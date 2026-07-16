import 'dart:io';
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../map/domain/occurrence_model.dart';
import '../domain/denuncia_draft.dart';

/// Escreve e lê ocorrências (denúncias) no Supabase.
class OcorrenciaDataSource {
  static const String _bucket = 'denuncias';

  SupabaseClient get _client => Supabase.instance.client;

  /// Submete uma denúncia: sobe a foto para o Storage, insere a ocorrência e a
  /// fotografia. Idempotente — usa o id do draft como PK e faz upsert, por isso
  /// re-tentar após uma falha parcial não cria duplicados.
  Future<void> submit(DenunciaDraft draft) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Sessão expirada. Inicie sessão novamente.');
    }

    final Uint8List bytes = await File(draft.fotoPathLocal).readAsBytes();
    final String storagePath = '$userId/${draft.id}.jpg';

    // 1. Foto para o Storage (upsert para tolerar re-tentativas).
    await _client.storage.from(_bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final nowIso = DateTime.now().toIso8601String();

    // 2. Ocorrência.
    await _client.from('ocorrencia').upsert({
      'id_ocorrencia': draft.id,
      'id_utilizador': userId,
      'id_categoria': draft.idCategoria,
      'descricao': draft.descricao,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'gravidade': draft.gravidade.dbValue,
      'estado': 'pendente',
      'modo_classificacao': 'manual',
      'sincronizado': true,
      'data_hora_registo': draft.dataHoraRegisto.toIso8601String(),
      'data_hora_sync': nowIso,
    });

    // 3. Fotografia (id_fotografia = id do draft → também idempotente).
    await _client.from('fotografia').upsert({
      'id_fotografia': draft.id,
      'id_ocorrencia': draft.id,
      'caminho_ficheiro': storagePath,
      'tipo': 'denuncia',
      'data_hora': nowIso,
    });
  }

  /// Lê todas as ocorrências para o mapa, já mapeadas para [Occurrence].
  Future<List<Occurrence>> fetchAll() async {
    final rows = await _client
        .from('ocorrencia')
        .select(
          'id_ocorrencia, latitude, longitude, descricao, estado, gravidade, '
          'categoria_residuo(nome)',
        )
        .order('data_hora_registo', ascending: false);

    return (rows as List)
        .map((r) => _mapToOccurrence(r as Map<String, dynamic>))
        .toList();
  }

  Occurrence _mapToOccurrence(Map<String, dynamic> row) {
    final estado = row['estado'] as String?;
    final gravidade = row['gravidade'] as String?;

    // O marcador tem 3 estados visuais; combinamos estado + gravidade da BD:
    // resolvida → verde; senão crítica → vermelho; senão → laranja.
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
    );
  }
}
