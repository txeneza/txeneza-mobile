import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/sqlite_service.dart';
import '../../../../core/errors/supabase_error_translator.dart';
import '../../../../core/network/cache_manager.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../sync/data/sync_queue_service.dart';
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
    final hiveKey = 'profile_fast_$uid';

    final result = await CacheManager.instance.executeSingleSWR<ProfileUserModel>(
      loadFromLocal: () async {
        // 1. Hive L1 Fast Access
        final fastMap = CacheManager.instance.getFast<Map>(hiveKey);
        if (fastMap != null) {
          return ProfileUserModel.fromJson(Map<String, dynamic>.from(fastMap));
        }

        // 2. SQLite L2 Relacional
        final sqliteRow = await SqliteService.instance.getPerfil(uid);
        if (sqliteRow != null) {
          return ProfileUserModel.fromJson(sqliteRow);
        }

        return null;
      },
      fetchFromRemote: () async {
        final row = await _client
            .from('utilizador')
            .select()
            .eq('id_utilizador', uid)
            .single();
        return ProfileUserModel.fromJson(row);
      },
      saveToLocal: (profile) async {
        final map = profile.toJson();
        await SqliteService.instance.savePerfil(map);
        await CacheManager.instance.putFast(hiveKey, map);
      },
    );

    if (result != null) return result;
    throw Exception('Não foi possível carregar o perfil.');
  }

  @override
  Future<void> updateProfile(ProfileUserModel profile) async {
    final uid = _uid;
    final hiveKey = 'profile_fast_$uid';
    final updateData = profile.toUpdateJson();

    // 1. Atualização Otimista Local (L1 & L2)
    final profileJson = profile.toJson();
    await SqliteService.instance.savePerfil(profileJson);
    await CacheManager.instance.putFast(hiveKey, profileJson);

    // 2. Atualização Remota com Fallback para SyncQueue
    try {
      await _client
          .from('utilizador')
          .update(updateData)
          .eq('id_utilizador', uid);
    } catch (e) {
      // Se estiver offline ou falhar na rede, enfileira para sincronização
      await SyncQueueService.instance.enqueuePerfilUpdate(uid, updateData);
    }
  }

  @override
  Future<ProfileStats> getStats() async {
    final uid = _uid;
    final hiveKey = 'stats_fast_$uid';

    // 1. Tenta obter do Hive L1
    final fastStats = CacheManager.instance.getFast<Map>(hiveKey);
    if (fastStats != null) {
      return ProfileStats.fromJson(Map<String, dynamic>.from(fastStats));
    }

    try {
      final rows = await _client
          .from('ocorrencia')
          .select('estado')
          .eq('id_utilizador', uid);

      final list = rows as List;
      final submitted = list.length;
      final resolved =
          list.where((r) => r['estado'] == 'resolvida').length;
      final stats = ProfileStats(
        submitted: submitted,
        resolved: resolved,
        pending: submitted - resolved,
      );

      await CacheManager.instance.putFast(hiveKey, stats.toJson());
      return stats;
    } catch (_) {
      // Fallback: calcula a partir das ocorrências salvas no SQLite L2
      final localRows = await SqliteService.instance.getOcorrencias(uid);
      if (localRows.isNotEmpty) {
        final submitted = localRows.length;
        final resolved =
            localRows.where((r) => r['estado'] == 'resolvida').length;
        final stats = ProfileStats(
          submitted: submitted,
          resolved: resolved,
          pending: submitted - resolved,
        );
        await CacheManager.instance.putFast(hiveKey, stats.toJson());
        return stats;
      }
      return ProfileStats.empty;
    }
  }

  @override
  Future<List<MyReport>> getMyReports() async {
    final uid = _uid;
    final hiveKey = 'my_reports_fast_$uid';

    return await CacheManager.instance.executeSWR<MyReport>(
      loadFromLocal: () async {
        // 1. Tenta do Hive L1
        final fastList = CacheManager.instance.getFast<List>(hiveKey);
        if (fastList != null && fastList.isNotEmpty) {
          return fastList
              .map((r) => _mapRawToReport(Map<String, dynamic>.from(r)))
              .toList();
        }

        // 2. Tenta do SQLite L2
        final sqliteRows = await SqliteService.instance.getOcorrencias(uid);
        if (sqliteRows.isNotEmpty) {
          return sqliteRows.map((r) => _mapRawToReport(r)).toList();
        }

        return [];
      },
      fetchFromRemote: () async {
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
      },
      saveToLocal: (freshList) async {
        final rawMaps = freshList.map((rep) {
          return {
            'id_ocorrencia': rep.id,
            'id_utilizador': uid,
            'latitude': rep.latitude,
            'longitude': rep.longitude,
            'descricao': rep.descricao,
            'estado': rep.estado,
            'gravidade': rep.gravidade,
            'nome_categoria': rep.categoria,
            'photo_url': rep.photoUrl,
            'data_hora_registo': rep.dataHora.toIso8601String(),
          };
        }).toList();

        await SqliteService.instance.saveOcorrencias(uid, rawMaps);
        await CacheManager.instance.putFast(hiveKey, rawMaps);
      },
    );
  }

  @override
  Future<void> deleteAccount() async {
    final uid = _uid;
    try {
      await _client.rpc('delete_own_account');
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
    // Limpa cache local e encerra sessão
    await CacheManager.instance.clearUserCache(uid);
    await _client.auth.signOut();
  }

  MyReport _mapRawToReport(Map<String, dynamic> row) {
    return MyReport(
      id: row['id_ocorrencia'] as String,
      photoUrl: row['photo_url'] as String?,
      categoria: row['nome_categoria'] as String? ?? 'Resíduo',
      descricao: (row['descricao'] as String?)?.trim() ?? 'Ocorrência de resíduo reportada.',
      latitude: double.tryParse(row['latitude'].toString()) ?? 0,
      longitude: double.tryParse(row['longitude'].toString()) ?? 0,
      estado: row['estado'] as String? ?? 'pendente',
      gravidade: row['gravidade'] as String? ?? 'media',
      dataHora: parseUtcDateTime(row['data_hora_registo']),
    );
  }

  MyReport _mapToReport(Map<String, dynamic> row) {
    final categoria = row['categoria_residuo'] as Map<String, dynamic>?;
    final nomeCategoria = categoria?['nome'] as String? ?? 'Resíduo';
    final descricao = (row['descricao'] as String?)?.trim();

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
      dataHora: parseUtcDateTime(row['data_hora_registo']),
    );
  }
}
