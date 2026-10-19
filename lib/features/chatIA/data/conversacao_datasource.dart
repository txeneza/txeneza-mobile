import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/sqlite_service.dart';
import '../../../core/network/cache_manager.dart';
import '../../../core/utils/date_utils.dart';

/// Uma troca guardada: mensagem do utilizador + resposta da Xeni.
class ConversaTurno {
  final String? idMensagem;
  final String mensagemUtilizador;
  final String respostaXeni;
  final DateTime dataHora;

  const ConversaTurno({
    this.idMensagem,
    required this.mensagemUtilizador,
    required this.respostaXeni,
    required this.dataHora,
  });
}

/// Persiste e lê o histórico de conversa com a Xeni na tabela `conversacao_xeni`.
/// Suporta SQLite local L2 para acesso instantâneo e offline.
class ConversacaoDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  /// Guarda uma troca localmente no SQLite e no Supabase.
  Future<void> save({
    required String mensagem,
    required String resposta,
  }) async {
    final uid = _client.auth.currentUser?.id ?? 'local_user';
    final idMensagem = const Uuid().v4();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    // 1. Grava no SQLite L2
    await SqliteService.instance.saveMensagemChat(
      idMensagem: idMensagem,
      idUtilizador: uid,
      mensagemUtilizador: mensagem,
      respostaXeni: resposta,
      modo: 'gemini',
      dataHora: nowIso,
    );

    // 2. Grava no Supabase L3 se autenticado
    final remoteUid = _client.auth.currentUser?.id;
    if (remoteUid != null) {
      try {
        await _client.from('conversacao_xeni').insert({
          'id_mensagem': idMensagem,
          'id_utilizador': remoteUid,
          'mensagem_utilizador': mensagem,
          'resposta_xeni': resposta,
          'modo': 'gemini',
          'data_hora': nowIso,
        });
      } catch (e) {
        debugPrint('Aviso: Histórico remoto não guardado ($e)');
      }
    }
  }

  /// Carrega o histórico do utilizador por ordem cronológica com padrão SWR.
  Future<List<ConversaTurno>> fetchHistory() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      final localRows = await SqliteService.instance.getMensagensChat('local_user');
      return localRows.map((r) {
        return ConversaTurno(
          idMensagem: r['id_mensagem'] as String?,
          mensagemUtilizador: r['mensagem_utilizador'] as String? ?? '',
          respostaXeni: r['resposta_xeni'] as String? ?? '',
          dataHora: DateTime.tryParse(r['data_hora'].toString()) ?? DateTime.now(),
        );
      }).toList();
    }

    return await CacheManager.instance.executeSWR<ConversaTurno>(
      loadFromLocal: () async {
        final localRows = await SqliteService.instance.getMensagensChat(uid);
        if (localRows.isNotEmpty) {
          return localRows.map((r) {
            return ConversaTurno(
              idMensagem: r['id_mensagem'] as String?,
              mensagemUtilizador: r['mensagem_utilizador'] as String? ?? '',
              respostaXeni: r['resposta_xeni'] as String? ?? '',
              dataHora: DateTime.tryParse(r['data_hora'].toString()) ?? DateTime.now(),
            );
          }).toList();
        }
        return [];
      },
      fetchFromRemote: () async {
        final rows = await _client
            .from('conversacao_xeni')
            .select('id_mensagem, mensagem_utilizador, resposta_xeni, modo, data_hora')
            .eq('id_utilizador', uid)
            .order('data_hora', ascending: true);

        return (rows as List).map((r) {
          final map = r as Map<String, dynamic>;
          return ConversaTurno(
            idMensagem: map['id_mensagem'] as String?,
            mensagemUtilizador: map['mensagem_utilizador'] as String? ?? '',
            respostaXeni: map['resposta_xeni'] as String? ?? '',
            dataHora: parseUtcDateTime(map['data_hora']),
          );
        }).toList();
      },
      saveToLocal: (freshList) async {
        await SqliteService.instance.clearMensagensChat(uid);
        for (final item in freshList) {
          await SqliteService.instance.saveMensagemChat(
            idMensagem: item.idMensagem ?? const Uuid().v4(),
            idUtilizador: uid,
            mensagemUtilizador: item.mensagemUtilizador,
            respostaXeni: item.respostaXeni,
            dataHora: item.dataHora.toUtc().toIso8601String(),
          );
        }
      },
    );
  }

  /// Apaga de forma definitiva todo o histórico de conversas do utilizador no SQLite e no Supabase.
  Future<void> clearHistory() async {
    final uid = _client.auth.currentUser?.id;

    // 1. Limpa todas as tabelas locais no SQLite
    if (uid != null) {
      await SqliteService.instance.clearMensagensChat(uid);
    }
    await SqliteService.instance.clearMensagensChat('local_user');
    await SqliteService.instance.clearAllMensagensChat();

    // 2. Limpa definitivamente no Supabase remoto
    if (uid != null) {
      try {
        await _client.from('conversacao_xeni').delete().eq('id_utilizador', uid);
      } catch (e) {
        debugPrint('Erro ao apagar histórico remoto no Supabase: $e');
        rethrow;
      }
    }
  }
}
