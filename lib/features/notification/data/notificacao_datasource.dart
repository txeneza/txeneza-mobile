import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notificacao_model.dart';

/// Lê as notificações do morador e marca-as como lidas.
///
/// A app móvel NUNCA cria notificações — quem cria é sempre o backend web,
/// na mesma transação em que altera o estado de uma ocorrência ou regista
/// uma verificação de resolução (ver txeneza-web:
/// src/app/api/occurrences/[id]/route.ts e
/// src/app/api/occurrences/[id]/verifications/route.ts). Este datasource
/// existe só para ler e marcar como lida.
class NotificacaoDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  /// Lê as notificações do utilizador autenticado, da mais recente para a
  /// mais antiga. Nunca lança exceção: se a leitura falhar (sem rede, RLS
  /// mal configurado, etc.) devolve lista vazia, para o ecrã mostrar um
  /// estado vazio/discreto em vez de quebrar (mesmo cuidado já usado em
  /// PontoRecolhaDataSource/_loadPontosRecolha).
  Future<List<NotificacaoModel>> fetchNotificacoes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('notificacao')
          .select('*')
          .eq('id_utilizador', userId)
          .order('data_hora', ascending: false);

      return (rows as List)
          .map((r) => NotificacaoModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erro ao buscar notificações: $e');
      return [];
    }
  }

  /// Marca uma notificação individual como lida.
  Future<void> marcarComoLida(String idNotificacao) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client
          .from('notificacao')
          .update({'lida': true})
          .eq('id_notificacao', idNotificacao)
          .eq('id_utilizador', userId);
    } catch (e) {
      debugPrint('Erro ao marcar notificação como lida: $e');
    }
  }

  /// Marca todas as notificações não lidas do utilizador como lidas de
  /// uma vez (botão "marcar tudo como lido").
  Future<void> marcarTodasComoLidas() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client
          .from('notificacao')
          .update({'lida': true})
          .eq('id_utilizador', userId)
          .eq('lida', false);
    } catch (e) {
      debugPrint('Erro ao marcar todas as notificações como lidas: $e');
    }
  }

  /// Subscreve alterações em tempo real na tabela "notificacao" para o
  /// utilizador atual (INSERT de notificações novas e UPDATE de estado
  /// lida/não lida). Chama [onChange] sempre que algo muda — o chamador
  /// decide o que fazer (tipicamente: reler a contagem de não lidas).
  ///
  /// Devolve o canal para o chamador poder subscrever (é preciso chamar
  /// `.subscribe()` antes de usar) e, principalmente, para poder ser
  /// removido em dispose() com `_client.removeChannel(channel)` — sem
  /// isso, o canal fica ligado mesmo depois do widget ser destruído.
  RealtimeChannel subscribeToChanges({
    required String userId,
    required VoidCallback onChange,
  }) {
    final channel = _client
        .channel('notificacao_utilizador_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notificacao',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id_utilizador',
            value: userId,
          ),
          callback: (payload) => onChange(),
        );

    return channel;
  }
}
