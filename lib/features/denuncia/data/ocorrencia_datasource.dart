import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/sqlite_service.dart';
import '../../../core/network/cache_manager.dart';
import 'categoria_datasource.dart';
import '../domain/categoria.dart';
import '../../map/domain/occurrence_model.dart';
import '../domain/denuncia_draft.dart';

/// Escreve e lê ocorrências (denúncias) com suporte a SWR (Hive + SQLite + Supabase).
class OcorrenciaDataSource {
  static const String _bucket = 'denuncias';

  SupabaseClient get _client => Supabase.instance.client;

  /// Submete uma denúncia: sobe a foto para o Storage, insere a ocorrência e a
  /// fotografia. Idempotente — usa o id do draft como PK e faz upsert.
  Future<void> submit(DenunciaDraft draft) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Sessão expirada. Inicie sessão novamente.');
    }

    String realCategoryId = draft.idCategoria;
    if (realCategoryId.startsWith('temp_')) {
      try {
        final cats = await CategoriaDataSource().fetchAll(forceRefresh: true);
        final tempCat = Categoria.defaultOfflineCategorias.firstWhere(
          (c) => c.id == draft.idCategoria,
          orElse: () => Categoria.defaultOfflineCategorias.last,
        );
        final matched = cats.firstWhere(
          (c) => c.nome.toLowerCase() == tempCat.nome.toLowerCase(),
          orElse: () => cats.firstWhere(
            (c) => c.nome.toLowerCase().contains('outro'),
            orElse: () => cats.first,
          ),
        );
        realCategoryId = matched.id;
      } catch (_) {}
    }

    final Uint8List bytes = await File(draft.fotoPathLocal).readAsBytes();
    final String storagePath = '$userId/${draft.id}.jpg';

    // 1. Foto para o Storage
    await _client.storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final nowIso = DateTime.now().toUtc().toIso8601String();

    // 2. Ocorrência na base de dados remota Supabase
    await _client.from('ocorrencia').upsert({
      'id_ocorrencia': draft.id,
      'id_utilizador': userId,
      'id_categoria': realCategoryId,
      'descricao': draft.descricao,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'gravidade': draft.gravidade.dbValue,
      'estado': 'pendente',
      'modo_classificacao': 'manual',
      'sincronizado': true,
      'data_hora_registo': draft.dataHoraRegisto.toUtc().toIso8601String(),
      'data_hora_sync': nowIso,
    });

    // 3. Fotografia
    await _client.from('fotografia').upsert({
      'id_fotografia': draft.id,
      'id_ocorrencia': draft.id,
      'caminho_ficheiro': storagePath,
      'tipo': 'denuncia',
      'data_hora': nowIso,
    });

    // Limpa a cache Hive/SQLite para que a nova ocorrência apareça no fetch em seguida
    await CacheManager.instance.putFast('ocorrencias_fast_$userId', null);
  }

  /// Lê as ocorrências do utilizador autenticado usando a estratégia SWR:
  /// 1. Exibe instantaneamente a cache do Hive/SQLite em 0ms.
  /// 2. Busca dados atualizados no Supabase em segundo plano.
  Future<List<Occurrence>> fetchAll() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final hiveKey = 'ocorrencias_fast_$userId';

    return await CacheManager.instance.executeSWR<Occurrence>(
      loadFromLocal: () async {
        // Tenta primeiro Hive para exibição ultrarrápida
        final fastList = CacheManager.instance.getFast<List>(hiveKey);
        if (fastList != null && fastList.isNotEmpty) {
          return fastList
              .map((r) => _mapRawToOccurrence(Map<String, dynamic>.from(r)))
              .toList();
        }

        // De seguida tenta o SQLite local
        final sqliteRows = await SqliteService.instance.getOcorrencias(userId);
        if (sqliteRows.isNotEmpty) {
          return sqliteRows.map((r) => _mapRawToOccurrence(r)).toList();
        }

        return [];
      },
      fetchFromRemote: () async {
        final rows = await _client
            .from('ocorrencia')
            .select(
              'id_ocorrencia, latitude, longitude, descricao, estado, gravidade, '
              'categoria_residuo(nome), fotografia(caminho_ficheiro, tipo), data_hora_registo',
            )
            .eq('id_utilizador', userId)
            .order('data_hora_registo', ascending: false);

        return (rows as List)
            .map((r) => _mapSupabaseToOccurrence(r as Map<String, dynamic>))
            .toList();
      },
      saveToLocal: (freshList) async {
        final rawMaps = freshList.map((occ) {
          final estadoStr = occ.status == OccurrenceStatus.resolved
              ? 'resolvida'
              : (occ.status == OccurrenceStatus.critical ? 'critica' : 'pendente');

          return {
            'id_ocorrencia': occ.id,
            'id_utilizador': userId,
            'latitude': occ.position.latitude,
            'longitude': occ.position.longitude,
            'descricao': occ.description,
            'estado': estadoStr,
            'gravidade': occ.status == OccurrenceStatus.critical ? 'critica' : 'normal',
            'nome_categoria': occ.title.replaceFirst('Denúncia · ', ''),
            'photo_url': occ.photoUrl,
            'data_hora_registo': DateTime.now().toIso8601String(),
          };
        }).toList();

        await SqliteService.instance.saveOcorrencias(userId, rawMaps);
        await CacheManager.instance.putFast(hiveKey, rawMaps);
      },
    );
  }

  Occurrence _mapRawToOccurrence(Map<String, dynamic> row) {
    final estado = row['estado'] as String?;
    final gravidade = row['gravidade'] as String?;

    final OccurrenceStatus status;
    if (estado == 'resolvida') {
      status = OccurrenceStatus.resolved;
    } else if (gravidade == 'critica') {
      status = OccurrenceStatus.critical;
    } else {
      status = OccurrenceStatus.pending;
    }

    final nomeCategoria = row['nome_categoria'] as String? ?? 'Resíduo';
    final descricao = (row['descricao'] as String?)?.trim();

    return Occurrence(
      id: row['id_ocorrencia'] as String,
      position: LatLng(
        double.parse(row['latitude'].toString()),
        double.parse(row['longitude'].toString()),
      ),
      status: status,
      title: 'Denúncia · $nomeCategoria',
      description: (descricao != null && descricao.isNotEmpty)
          ? descricao
          : 'Ocorrência de resíduo reportada.',
      photoUrl: row['photo_url'] as String?,
    );
  }

  Occurrence _mapSupabaseToOccurrence(Map<String, dynamic> row) {
    final estado = row['estado'] as String?;
    final gravidade = row['gravidade'] as String?;

    final OccurrenceStatus status;
    if (estado == 'resolvida') {
      status = OccurrenceStatus.resolved;
    } else if (gravidade == 'critica') {
      status = OccurrenceStatus.critical;
    } else {
      status = OccurrenceStatus.pending;
    }

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
        photoUrl = _client.storage.from(_bucket).getPublicUrl(path);
      }
    }

    return Occurrence(
      id: row['id_ocorrencia'] as String,
      position: LatLng(
        double.parse(row['latitude'].toString()),
        double.parse(row['longitude'].toString()),
      ),
      status: status,
      title: 'Denúncia · $nomeCategoria',
      description: (descricao != null && descricao.isNotEmpty)
          ? descricao
          : 'Ocorrência de resíduo reportada.',
      photoUrl: photoUrl,
    );
  }
}
