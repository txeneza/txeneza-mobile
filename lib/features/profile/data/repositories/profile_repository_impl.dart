import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/sqlite_service.dart';
import '../../../../core/errors/supabase_error_translator.dart';
import '../../../../core/network/cache_manager.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../denuncia/data/denuncia_queue.dart';
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
  Future<ProfileUserModel?> getCachedProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final uid = user.id;
      final hiveKey = 'profile_fast_$uid';

      // 1. Hive L1 Fast Access (0ms na memória/disco)
      try {
        final fastMap = CacheManager.instance.getFast<Map>(hiveKey);
        if (fastMap != null) {
          final map = Map<String, dynamic>.from(fastMap);
          if (!map.containsKey('id_utilizador') || map['id_utilizador'] == null) {
            map['id_utilizador'] = uid;
          }
          final model = ProfileUserModel.fromJson(map);
          if (model.id.isNotEmpty && model.fullName.isNotEmpty) {
            return model;
          }
        }
      } catch (e) {
        // Fallback silencioso para SQLite
      }

      // 2. SQLite L2 Relacional
      try {
        final sqliteRow = await SqliteService.instance.getPerfil(uid);
        if (sqliteRow != null) {
          final map = Map<String, dynamic>.from(sqliteRow);
          if (!map.containsKey('id_utilizador') || map['id_utilizador'] == null) {
            map['id_utilizador'] = uid;
          }
          final model = ProfileUserModel.fromJson(map);
          await CacheManager.instance.putFast(hiveKey, model.toJson());
          return model;
        }
      } catch (e) {
        // Fallback silencioso para metadados
      }

      // 3. Fallback instantâneo: Metadados da sessão Auth ativa
      try {
        final metadata = user.userMetadata ?? const <String, dynamic>{};
        final fullName = (metadata['nome'] ??
                metadata['full_name'] ??
                metadata['name'] ??
                user.email?.split('@').first ??
                'Utilizador')
            .toString();

        final fallbackModel = ProfileUserModel(
          id: uid,
          fullName: fullName,
          email: user.email ?? '',
          phoneNumber: (metadata['telefone'] ?? '').toString(),
          neighborhood: (metadata['bairro'] ?? '').toString(),
          token: _client.auth.currentSession?.accessToken,
          isVerified: true,
        );
        await CacheManager.instance.putFast(hiveKey, fallbackModel.toJson());
        return fallbackModel;
      } catch (_) {}
    } catch (_) {}

    return null;
  }

  @override
  Future<ProfileStats?> getCachedStats() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final uid = user.id;
      final hiveKey = 'stats_fast_$uid';

      final pendingOffline = await _getPendingSyncReports();
      final offlineCount = pendingOffline.length;

      // 1. Hive L1 Fast Access
      try {
        final fastStats = CacheManager.instance.getFast<Map>(hiveKey);
        if (fastStats != null) {
          final base = ProfileStats.fromJson(Map<String, dynamic>.from(fastStats));
          return ProfileStats(
            submitted: base.submitted + offlineCount,
            resolved: base.resolved,
            pending: base.pending + offlineCount,
          );
        }
      } catch (_) {}

      // 2. SQLite L2 rápido a partir das ocorrências salvas localmente
      try {
        final localRows = await SqliteService.instance.getOcorrencias(uid);
        if (localRows.isNotEmpty || offlineCount > 0) {
          final submitted = localRows.length + offlineCount;
          final resolved = localRows.where((r) => r['estado'] == 'resolvida').length;
          final stats = ProfileStats(
            submitted: submitted,
            resolved: resolved,
            pending: submitted - resolved,
          );
          await CacheManager.instance.putFast(hiveKey, stats.toJson());
          return stats;
        }
      } catch (_) {}
    } catch (_) {}

    return null;
  }

  @override
  Future<ProfileUserModel> fetchRemoteProfile() async {
    final uid = _uid;
    final hiveKey = 'profile_fast_$uid';

    try {
      final row = await _client
          .from('utilizador')
          .select()
          .eq('id_utilizador', uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (row != null) {
        final profile = ProfileUserModel.fromJson(row);
        final map = profile.toJson();
        await SqliteService.instance.savePerfil(map);
        await CacheManager.instance.putFast(hiveKey, map);
        return profile;
      }
    } catch (e) {
      // Falha de rede ou timeout: tenta recuperar o perfil em cache
    }

    final cached = await getCachedProfile();
    if (cached != null) return cached;

    final user = _client.auth.currentUser;
    return ProfileUserModel(
      id: uid,
      fullName: (user?.userMetadata?['nome'] ??
              user?.userMetadata?['full_name'] ??
              user?.email?.split('@').first ??
              'Utilizador')
          .toString(),
      email: user?.email ?? '',
      phoneNumber: '',
      neighborhood: '',
      isVerified: true,
    );
  }

  @override
  Future<ProfileStats> fetchRemoteStats() async {
    final uid = _uid;
    final hiveKey = 'stats_fast_$uid';
    final pendingOffline = await _getPendingSyncReports();
    final offlineCount = pendingOffline.length;

    try {
      final rows = await _client
          .from('ocorrencia')
          .select('estado')
          .eq('id_utilizador', uid)
          .timeout(const Duration(seconds: 5));

      final list = rows as List;
      final submitted = list.length + offlineCount;
      final resolved = list.where((r) => r['estado'] == 'resolvida').length;
      final stats = ProfileStats(
        submitted: submitted,
        resolved: resolved,
        pending: submitted - resolved,
      );

      await CacheManager.instance.putFast(hiveKey, stats.toJson());
      return stats;
    } catch (_) {
      final cached = await getCachedStats();
      if (cached != null) return cached;
      return ProfileStats(
        submitted: offlineCount,
        resolved: 0,
        pending: offlineCount,
      );
    }
  }

  @override
  Future<ProfileUserModel> getProfile() async {
    final cached = await getCachedProfile();
    if (cached != null) {
      // Revalida em segundo plano sem travar a interface
      fetchRemoteProfile().catchError((_) => cached);
      return cached;
    }
    return await fetchRemoteProfile();
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
      await SyncQueueService.instance.enqueuePerfilUpdate(uid, updateData);
    }
  }

  @override
  Future<ProfileStats> getStats() async {
    final cached = await getCachedStats();
    if (cached != null) {
      fetchRemoteStats().catchError((_) => cached);
      return cached;
    }
    return await fetchRemoteStats();
  }

  @override
  Future<List<MyReport>> getMyReports() async {
    final uid = _uid;
    final hiveKey = 'my_reports_fast_$uid';
    final pendingOffline = await _getPendingSyncReports();

    final cachedList = await CacheManager.instance.executeSWR<MyReport>(
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
        await CacheManager.instance.putFast('ocorrencias_fast_$uid', rawMaps);
      },
    );

    final Set<String> existingIds = cachedList.map((r) => r.id).toSet();
    final uniquePending =
        pendingOffline.where((p) => !existingIds.contains(p.id)).toList();

    return [...uniquePending, ...cachedList];
  }

  Future<List<MyReport>> _getPendingSyncReports() async {
    try {
      final List<MyReport> pendingReports = [];
      final Set<String> seenIds = {};

      // 1. Lê rascunhos da DenunciaQueue (SharedPreferences)
      try {
        final drafts = await DenunciaQueue().pending();
        for (final draft in drafts) {
          if (draft.tentativas < 3) {
            seenIds.add(draft.id);
            pendingReports.add(
              MyReport(
                id: draft.id,
                photoUrl: draft.fotoPathLocal,
                categoria: 'Denúncia (Offline)',
                descricao: (draft.descricao != null && draft.descricao!.trim().isNotEmpty)
                    ? draft.descricao!.trim()
                    : 'Denúncia offline pendente de envio.',
                latitude: draft.latitude,
                longitude: draft.longitude,
                estado: 'pendente_sync',
                gravidade: draft.gravidade.dbValue,
                dataHora: draft.dataHoraRegisto,
              ),
            );
          }
        }
      } catch (_) {}

      // 2. Lê pendências da SyncQueueService (SQLite)
      final pendingItems = await SyncQueueService.instance.getPendingItems();
      for (final item in pendingItems) {
        if (item['tipo_operacao'] == SyncOperationType.denuncia.name) {
          final payloadStr = item['payload_json'] as String;
          final map = jsonDecode(payloadStr) as Map<String, dynamic>;
          final id = (map['id'] ?? item['id_item']) as String;
          if (seenIds.contains(id)) continue;
          seenIds.add(id);

          final desc = (map['descricao'] as String?) ?? 'Denúncia offline pendente de envio.';
          final lat = double.tryParse(map['latitude']?.toString() ?? '0') ?? 0;
          final lng = double.tryParse(map['longitude']?.toString() ?? '0') ?? 0;
          final photoPath = item['file_path'] as String? ?? map['fotoPathLocal'] as String?;
          final dataHoraStr = map['dataHoraRegisto'] as String? ?? item['data_criacao'] as String?;

          pendingReports.add(
            MyReport(
              id: id,
              photoUrl: photoPath,
              categoria: 'Denúncia (Offline)',
              descricao: desc,
              latitude: lat,
              longitude: lng,
              estado: 'pendente_sync',
              gravidade: map['gravidade']?.toString() ?? 'media',
              dataHora: DateTime.tryParse(dataHoraStr ?? '') ?? DateTime.now(),
            ),
          );
        }
      }
      return pendingReports;
    } catch (e) {
      return [];
    }
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
