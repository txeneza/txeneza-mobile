import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/supabase_error_translator.dart';
import '../../domain/my_report.dart';
import '../../domain/profile_stats.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/profile_user_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Nenhuma sessão ativa encontrada. Faça login novamente.');
    }
    return user.id;
  }

  @override
  Future<ProfileUserModel> getProfile() async {
    final uid = _uid;
    try {
      final row = await _client
          .from('utilizador')
          .select()
          .eq('id_utilizador', uid)
          .single();
      return ProfileUserModel.fromJson(row);
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
  }

  @override
  Future<void> updateProfile(ProfileUserModel profile) async {
    final uid = _uid;
    try {
      await _client
          .from('utilizador')
          .update(profile.toUpdateJson())
          .eq('id_utilizador', uid);
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
  }

  @override
  Future<ProfileStats> getStats() async {
    final uid = _uid;
    try {
      final rows = await _client
          .from('ocorrencia')
          .select('estado')
          .eq('id_utilizador', uid);

      final list = rows as List;
      final submitted = list.length;
      final resolved =
          list.where((r) => r['estado'] == 'resolvida').length;
      return ProfileStats(
        submitted: submitted,
        resolved: resolved,
        pending: submitted - resolved,
      );
    } catch (_) {
      // Estatística não é crítica: em falha devolve zeros.
      return ProfileStats.empty;
    }
  }

  @override
  Future<List<MyReport>> getMyReports() async {
    final uid = _uid;
    try {
      final rows = await _client
          .from('ocorrencia')
          .select(
            'id_ocorrencia, descricao, latitude, longitude, estado, gravidade, '
            'data_hora_registo, categoria_residuo(nome), '
            'fotografia(caminho_ficheiro, tipo)',
          )
          .eq('id_utilizador', uid)
          .order('data_hora_registo', ascending: false);

      return (rows as List)
          .map((r) => _mapToReport(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _client.rpc('delete_own_account');
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
    // A conta já não existe: limpa a sessão local.
    await _client.auth.signOut();
  }

  MyReport _mapToReport(Map<String, dynamic> row) {
    final categoria = row['categoria_residuo'] as Map<String, dynamic>?;
    final nomeCategoria = categoria?['nome'] as String? ?? 'Resíduo';
    final descricao = (row['descricao'] as String?)?.trim();

    // Foto da denúncia (a primeira do tipo 'denuncia') → URL pública do bucket.
    String? photoUrl;
    final fotos = row['fotografia'] as List?;
    if (fotos != null && fotos.isNotEmpty) {
      final foto = fotos.cast<Map<String, dynamic>>().firstWhere(
            (f) => f['tipo'] == 'denuncia',
            orElse: () => fotos.first as Map<String, dynamic>,
          );
      final path = foto['caminho_ficheiro'] as String?;
      if (path != null && path.isNotEmpty) {
        photoUrl = _client.storage.from('denuncias').getPublicUrl(path);
      }
    }

    return MyReport(
      id: row['id_ocorrencia'] as String,
      photoUrl: photoUrl,
      categoria: nomeCategoria,
      descricao: (descricao != null && descricao.isNotEmpty)
          ? descricao
          : 'Ocorrência de resíduo reportada.',
      latitude: double.tryParse(row['latitude'].toString()) ?? 0,
      longitude: double.tryParse(row['longitude'].toString()) ?? 0,
      estado: row['estado'] as String? ?? 'pendente',
      gravidade: row['gravidade'] as String? ?? 'media',
      dataHora: (DateTime.tryParse(row['data_hora_registo'].toString()) ??
              DateTime.now())
          .toLocal(),
    );
  }
}
