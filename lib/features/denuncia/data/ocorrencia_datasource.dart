import 'dart:io';
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'categoria_datasource.dart';
import '../domain/categoria.dart';
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

    // Se a denúncia foi guardada offline com um ID temporário, resolve para o UUID real do Supabase.
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
      'id_categoria': realCategoryId,
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

  /// Lê as ocorrências do utilizador autenticado (para o mapa e para a
  /// secção "Ocorrências na Beira"), já mapeadas para [Occurrence] e com a
  /// URL pública da fotografia da denúncia.
  ///
  /// Só devolve as ocorrências do próprio utilizador — o mapa deixou de
  /// mostrar denúncias de outras pessoas. Sem sessão activa, devolve lista
  /// vazia (nunca lança excepção, mesmo cuidado dos restantes datasources).
  Future<List<Occurrence>> fetchAll() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('ocorrencia')
          .select(
            'id_ocorrencia, latitude, longitude, descricao, estado, gravidade, '
            'categoria_residuo(nome), fotografia(caminho_ficheiro, tipo)',
          )
          .eq('id_utilizador', userId)
          .order('data_hora_registo', ascending: false);

      return (rows as List)
          .map((r) => _mapToOccurrence(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
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

    // Foto da denúncia (a primeira do tipo 'denuncia') → URL pública do
    // bucket, mesmo padrão já usado em profile_repository_impl.dart.
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
