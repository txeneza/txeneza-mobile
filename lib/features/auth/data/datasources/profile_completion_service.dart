import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/beira_neighborhoods.dart';
import '../../../../core/database/sqlite_service.dart';
import '../../../../core/network/cache_manager.dart';
import '../../../sync/data/sync_queue_service.dart';

/// Valor gravado pelo trigger `handle_new_user` quando a conta é criada sem
/// metadado de bairro — o caso típico do login com Google, que não pede bairro.
const String kBairroPorDefinir = 'Não definido';

/// Decide se o utilizador tem de completar o perfil antes de entrar na app.
class ProfileCompletionService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Um bairro só é válido se constar da lista real de bairros da Beira.
  static bool isBairroValido(String? bairro) =>
      bairro != null && BeiraNeighborhoods.list.contains(bairro);

  /// True quando há sessão activa mas o perfil ainda não tem um bairro real.
  /// Avalia primeiro a cache L1/L2 local instantaneamente.
  Future<bool> needsCompletion() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    // 1. Verificação L1 Rápida (Hive)
    final hiveKey = 'profile_fast_${user.id}';
    final fastMap = CacheManager.instance.getFast<Map>(hiveKey);
    if (fastMap != null) {
      final bairro = fastMap['bairro'] as String?;
      if (isBairroValido(bairro)) return false;
    }

    // 2. Verificação L2 (SQLite)
    try {
      final localRow = await SqliteService.instance.getPerfil(user.id);
      if (localRow != null) {
        final bairro = localRow['bairro'] as String?;
        if (isBairroValido(bairro)) return false;
      }
    } catch (_) {}

    // 3. Fallback Remoto L3 (Supabase)
    try {
      final row = await _client
          .from('utilizador')
          .select('bairro')
          .eq('id_utilizador', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 2));

      // Sem linha ainda (trigger em atraso) conta como perfil incompleto.
      if (row == null) return true;

      return !isBairroValido(row['bairro'] as String?);
    } catch (_) {
      return false;
    }
  }

  Future<void> completeProfile({
    required String bairro,
    String? telefone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sessão expirada. Inicie sessão novamente.');
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final name = (metadata['nome'] ??
        metadata['full_name'] ??
        metadata['name'] ??
        user.email?.split('@').first ??
        'Utilizador') as String;

    final updateData = {
      'nome': name,
      'email': user.email ?? '',
      'bairro': bairro,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
    };

    // 1. Atualização L1 (Hive)
    final hiveKey = 'profile_fast_${user.id}';
    final currentFast = CacheManager.instance.getFast<Map>(hiveKey) ?? {};
    final updatedMap = Map<String, dynamic>.from(currentFast)..addAll(updateData);
    await CacheManager.instance.putFast(hiveKey, updatedMap);

    // 2. Atualização L2 (SQLite)
    try {
      await SqliteService.instance.savePerfil({
        'id_utilizador': user.id,
        ...updateData,
      });
    } catch (e) {
      debugPrint('Erro ao guardar perfil localmente no SQLite: $e');
    }

    // 3. Atualização L3 (Supabase) com enfileiramento offline
    try {
      await _client
          .from('utilizador')
          .update(updateData)
          .eq('id_utilizador', user.id);
    } catch (e) {
      debugPrint('Rede indisponível ao atualizar perfil. Enfileirando offline: $e');
      await SyncQueueService.instance.enqueuePerfil(
        userId: user.id,
        dados: updateData,
      );
    }
  }
}
