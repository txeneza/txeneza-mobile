import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/sqlite_service.dart';
import '../../denuncia/data/ocorrencia_datasource.dart';
import '../../denuncia/domain/denuncia_draft.dart';

/// Tipos de operações suportadas na fila unificada de sincronização offline
enum SyncOperationType {
  denuncia,
  contestacao,
  notificacaoLida,
  perfil,
}

/// Serviço de Fila de Sincronização Unificada baseado em SQLite (L2).
/// Garante que nenhuma ação do cidadão realizada offline seja perdida.
class SyncQueueService {
  static final SyncQueueService instance = SyncQueueService._internal();

  final SqliteService _sqlite = SqliteService.instance;
  final OcorrenciaDataSource _ocorrenciaDataSource = OcorrenciaDataSource();

  SyncQueueService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  // --- ENQUEUE METHODS ---

  /// Enfileira uma denúncia offline
  Future<void> enqueueDenuncia(DenunciaDraft draft, String imagePath) async {
    await _sqlite.enqueueSyncItem(
      idItem: draft.id,
      tipoOperacao: SyncOperationType.denuncia.name,
      payloadJson: jsonEncode(draft.toJson()),
      filePath: imagePath,
    );
  }

  /// Enfileira uma contestação/verificação de resolução offline
  Future<void> enqueueVerificacao({
    required String idOcorrencia,
    required bool aprovado,
    String? observacoes,
    String? fotoContestacaoPath,
  }) async {
    final payload = {
      'id_ocorrencia': idOcorrencia,
      'aprovado': aprovado,
      'observacoes': observacoes,
    };
    await _sqlite.enqueueSyncItem(
      idItem: 'verif_$idOcorrencia',
      tipoOperacao: SyncOperationType.contestacao.name,
      payloadJson: jsonEncode(payload),
      filePath: fotoContestacaoPath,
    );
  }

  /// Enfileira marcação de notificação lida offline
  Future<void> enqueueNotificacaoLida({
    required String idUtilizador,
    String? idNotificacao,
    bool marcarTodas = false,
  }) async {
    final payload = {
      'id_utilizador': idUtilizador,
      'id_notificacao': idNotificacao,
      'marcar_todas': marcarTodas,
    };
    await _sqlite.enqueueSyncItem(
      idItem: 'notif_${idNotificacao ?? idUtilizador}_${DateTime.now().millisecondsSinceEpoch}',
      tipoOperacao: SyncOperationType.notificacaoLida.name,
      payloadJson: jsonEncode(payload),
    );
  }

  /// Enfileira atualização de perfil offline
  Future<void> enqueuePerfilUpdate(String userId, Map<String, dynamic> updateData) async {
    final payload = {
      'id_utilizador': userId,
      'dados': updateData,
    };
    await _sqlite.enqueueSyncItem(
      idItem: 'perfil_$userId',
      tipoOperacao: SyncOperationType.perfil.name,
      payloadJson: jsonEncode(payload),
    );
  }

  // --- QUERY & METRICS ---

  Future<int> pendingCount() async => await _sqlite.getPendingSyncCount();

  Future<List<Map<String, dynamic>>> getPendingItems() async =>
      await _sqlite.getPendingSyncItems();

  // --- FLUSH & SYNC PROCESSING ---

  /// Processa todos os itens pendentes na fila
  Future<int> flush({bool forceResetTentativas = false}) async {
    final items = await _sqlite.getPendingSyncItems();
    if (items.isEmpty) return 0;

    int syncCount = 0;

    for (final item in items) {
      final idItem = item['id_item'] as String;
      final tipo = item['tipo_operacao'] as String;
      final payloadJson = item['payload_json'] as String;
      final filePath = item['file_path'] as String?;
      int tentativas = (item['tentativas'] as int?) ?? 0;

      if (!forceResetTentativas && tentativas >= 4) {
        continue; // Não tenta infinitamente se houver falha lógica
      }

      try {
        if (tipo == SyncOperationType.denuncia.name) {
          final draftMap = jsonDecode(payloadJson) as Map<String, dynamic>;
          final draft = DenunciaDraft.fromJson(draftMap);
          await _ocorrenciaDataSource.submit(draft);

          // Limpa foto local após envio bem-sucedido
          if (filePath != null) {
            final file = File(filePath);
            if (await file.exists()) await file.delete();
          }
        } else if (tipo == SyncOperationType.contestacao.name) {
          final map = jsonDecode(payloadJson) as Map<String, dynamic>;
          final idOcorrencia = map['id_ocorrencia'] as String;
          final aprovado = map['aprovado'] as bool;
          final observacoes = map['observacoes'] as String?;

          await _processContestacaoSync(
            idOcorrencia: idOcorrencia,
            aprovado: aprovado,
            observacoes: observacoes,
            fotoPath: filePath,
          );
        } else if (tipo == SyncOperationType.notificacaoLida.name) {
          final map = jsonDecode(payloadJson) as Map<String, dynamic>;
          final idNotificacao = map['id_notificacao'] as String?;
          final marcarTodas = map['marcar_todas'] as bool? ?? false;
          final userId = map['id_utilizador'] as String;

          if (marcarTodas) {
            await _client
                .from('notificacao')
                .update({'lida': true})
                .eq('id_utilizador', userId)
                .eq('lida', false);
          } else if (idNotificacao != null) {
            await _client
                .from('notificacao')
                .update({'lida': true})
                .eq('id_notificacao', idNotificacao)
                .eq('id_utilizador', userId);
          }
        } else if (tipo == SyncOperationType.perfil.name) {
          final map = jsonDecode(payloadJson) as Map<String, dynamic>;
          final userId = map['id_utilizador'] as String;
          final dados = Map<String, dynamic>.from(map['dados'] as Map);

          await _client
              .from('utilizador')
              .update(dados)
              .eq('id_utilizador', userId);
        }

        // Sucesso: remove o item da fila
        await _sqlite.removeSyncItem(idItem);
        syncCount++;
      } catch (e) {
        debugPrint('Erro ao sincronizar item $idItem ($tipo): $e');
        final errorStr = e.toString();

        final isNetworkError = errorStr.contains('SocketException') ||
            errorStr.contains('ClientException') ||
            errorStr.contains('TimeoutException') ||
            errorStr.contains('Connection failed') ||
            errorStr.contains('Failed host lookup');

        if (isNetworkError) {
          // Erro de rede: interrompe o loop para tentar novamente quando houver internet
          break;
        } else {
          // Erro estrutural: incrementa tentativas
          await _sqlite.updateSyncItemStatus(
            idItem: idItem,
            status: 'pendente',
            tentativas: tentativas + 1,
            ultimoErro: errorStr,
          );
        }
      }
    }

    return syncCount;
  }

  Future<void> _processContestacaoSync({
    required String idOcorrencia,
    required bool aprovado,
    String? observacoes,
    String? fotoPath,
  }) async {
    if (!aprovado && fotoPath != null) {
      final file = File(fotoPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final userId = _client.auth.currentUser?.id ?? 'anonymous';
        final storagePath = 'contestacoes/$userId/${idOcorrencia}_contestacao.jpg';

        await _client.storage.from('denuncias').uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        await _client.from('fotografia').upsert({
          'id_fotografia': '${idOcorrencia}_contestacao',
          'id_ocorrencia': idOcorrencia,
          'caminho_ficheiro': storagePath,
          'tipo': 'contestacao',
          'data_hora': DateTime.now().toUtc().toIso8601String(),
        });

        await file.delete();
      }
    }

    if (!aprovado) {
      await _client
          .from('ocorrencia')
          .update({'estado': 'reaberta'})
          .eq('id_ocorrencia', idOcorrencia);
    }
  }
}
