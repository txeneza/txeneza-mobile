import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/sqlite_service.dart';
import '../../../core/network/cache_manager.dart';
import '../../../core/utils/date_utils.dart';
import '../../sync/data/sync_queue_service.dart';
import '../domain/resolucao_verificacao.dart';

/// Datasource Supabase para o ciclo de verificação fotográfica pelo morador.
/// Suporta arquitetura híbrida com SQLite L2 e fila offline de sincronização.
class ResolucaoDataSource {
  static const String _bucket = 'denuncias';
  SupabaseClient get _client => Supabase.instance.client;

  /// Obtém a verificação e fotos associadas a uma ocorrência com padrão SWR.
  Future<ResolucaoVerificacao> fetchVerificacao(String idOcorrencia) async {
    final result = await CacheManager.instance.executeSingleSWR<ResolucaoVerificacao>(
      loadFromLocal: () async {
        final row = await SqliteService.instance.getVerificacaoResolucao(idOcorrencia);
        if (row != null) {
          return ResolucaoVerificacao(
            idOcorrencia: idOcorrencia,
            fotoInicialUrl: row['foto_inicial_url'] as String?,
            fotoResolucaoUrl: row['foto_resolucao_url'] as String?,
            dataResolucao: DateTime.tryParse(row['data_resolucao']?.toString() ?? '') ?? DateTime.now(),
            observacoesEquipa: row['observacoes_equipa'] as String?,
            statusVerificacao: StatusVerificacaoMorador.pendente,
            observacoesMorador: row['observacoes_morador'] as String?,
          );
        }
        return null;
      },
      fetchFromRemote: () async {
        String? fotoInicialPath;
        String? fotoResolucaoPath;
        String? observacoesEquipa;

        // 1. Procurar na tabela "verificacao_resolucao"
        try {
          final verRows = await _client
              .from('verificacao_resolucao')
              .select('id_foto_verificacao, observacoes')
              .eq('id_ocorrencia', idOcorrencia);
          if (verRows.isNotEmpty) {
            final lastVer = verRows.last;
            observacoesEquipa = lastVer['observacoes'] as String?;
            final idFotoVer = lastVer['id_foto_verificacao'] as String?;

            if (idFotoVer != null && idFotoVer.isNotEmpty) {
              final fotoRow = await _client
                  .from('fotografia')
                  .select('caminho_ficheiro')
                  .eq('id_fotografia', idFotoVer)
                  .maybeSingle();

              if (fotoRow != null && fotoRow['caminho_ficheiro'] != null) {
                fotoResolucaoPath = fotoRow['caminho_ficheiro'] as String;
              }
            }
          }
        } catch (e) {
          debugPrint('Aviso ao consultar verificacao_resolucao: $e');
        }

        // 2. Procurar na tabela "fotografia" por id_ocorrencia
        try {
          final photos = await _client
              .from('fotografia')
              .select('caminho_ficheiro, tipo, data_hora')
              .eq('id_ocorrencia', idOcorrencia)
              .order('data_hora', ascending: true);

          for (final row in (photos as List)) {
            final tipo = (row['tipo'] as String?)?.toLowerCase().trim();
            final path = row['caminho_ficheiro'] as String?;

            if (path != null && path.isNotEmpty) {
              if (tipo == 'denuncia') {
                fotoInicialPath = path;
              } else if (tipo == 'verificacao' ||
                  tipo == 'resolucao' ||
                  tipo == 'solucao' ||
                  tipo == 'resolvida') {
                fotoResolucaoPath = path;
              }
            }
          }

          if (fotoResolucaoPath == null && photos.length >= 2) {
            for (final row in (photos as List).reversed) {
              final path = row['caminho_ficheiro'] as String?;
              if (path != null && path.isNotEmpty && path != fotoInicialPath) {
                fotoResolucaoPath = path;
                break;
              }
            }
          }
        } catch (e) {
          debugPrint('Erro ao buscar fotos em fotografia: $e');
        }

        // 3. Obter detalhes da ocorrência
        Map<String, dynamic>? occ;
        try {
          occ = await _client
              .from('ocorrencia')
              .select('data_hora_sync, descricao')
              .eq('id_ocorrencia', idOcorrencia)
              .maybeSingle();

          if (observacoesEquipa == null || observacoesEquipa.isEmpty) {
            observacoesEquipa = occ?['descricao'] as String?;
          }
        } catch (e) {
          debugPrint('Aviso ao carregar ocorrencia: $e');
        }

        // 4. Formatar URLs públicas
        String? formatUrl(String? path) {
          if (path == null || path.trim().isEmpty) return null;
          final trimmed = path.trim();
          if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
            return trimmed;
          }
          return _client.storage.from(_bucket).getPublicUrl(trimmed);
        }

        final String? urlInicial = formatUrl(fotoInicialPath);
        final String? urlResolucao = formatUrl(fotoResolucaoPath);

        return ResolucaoVerificacao(
          idOcorrencia: idOcorrencia,
          fotoInicialUrl: urlInicial,
          fotoResolucaoUrl: urlResolucao,
          dataResolucao: occ != null && occ['data_hora_sync'] != null
              ? parseUtcDateTime(occ['data_hora_sync'])
              : DateTime.now(),
          observacoesEquipa: observacoesEquipa,
          statusVerificacao: StatusVerificacaoMorador.pendente,
          observacoesMorador: null,
        );
      },
      saveToLocal: (freshData) async {
        await SqliteService.instance.saveVerificacaoResolucao({
          'id_ocorrencia': freshData.idOcorrencia,
          'foto_inicial_url': freshData.fotoInicialUrl,
          'foto_resolucao_url': freshData.fotoResolucaoUrl,
          'observacoes_equipa': freshData.observacoesEquipa,
          'data_resolucao': (freshData.dataResolucao ?? DateTime.now()).toIso8601String(),
          'status_verificacao': freshData.statusVerificacao.name,
          'observacoes_morador': freshData.observacoesMorador,
        });
      },
    );

    return result ??
        ResolucaoVerificacao(
          idOcorrencia: idOcorrencia,
          dataResolucao: DateTime.now(),
          statusVerificacao: StatusVerificacaoMorador.pendente,
        );
  }

  /// Submete a decisão do morador (aprovar ou contestar com foto opcional).
  /// Se a conexão falhar, enfileira automaticamente no SyncQueueService.
  Future<void> submitVerificacao({
    required String idOcorrencia,
    required bool aprovado,
    String? observacoes,
    String? fotoContestacaoLocalPath,
  }) async {
    try {
      String? contestacaoStoragePath;

      if (!aprovado && fotoContestacaoLocalPath != null) {
        final file = File(fotoContestacaoLocalPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final userId = _client.auth.currentUser?.id ?? 'anonymous';
          contestacaoStoragePath =
              'contestacoes/$userId/${idOcorrencia}_contestacao.jpg';

          await _client.storage.from(_bucket).uploadBinary(
                contestacaoStoragePath,
                bytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );

          await _client.from('fotografia').upsert({
            'id_fotografia': '${idOcorrencia}_contestacao',
            'id_ocorrencia': idOcorrencia,
            'caminho_ficheiro': contestacaoStoragePath,
            'tipo': 'contestacao',
            'data_hora': DateTime.now().toUtc().toIso8601String(),
          });
        }
      }

      final payload = <String, dynamic>{};
      if (!aprovado) {
        payload['estado'] = 'reaberta';
      }

      if (payload.isNotEmpty) {
        await _client
            .from('ocorrencia')
            .update(payload)
            .eq('id_ocorrencia', idOcorrencia);
      }
    } catch (e) {
      debugPrint('Falha ao enviar verificação online: $e. Enfileirando na SyncQueue...');
      await SyncQueueService.instance.enqueueVerificacao(
        idOcorrencia: idOcorrencia,
        aprovado: aprovado,
        observacoes: observacoes,
        fotoContestacaoPath: fotoContestacaoLocalPath,
      );
    }
  }
}
