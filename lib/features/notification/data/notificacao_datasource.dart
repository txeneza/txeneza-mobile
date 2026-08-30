import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/database/sqlite_service.dart';
import '../../../core/network/cache_manager.dart';
import '../../sync/data/sync_queue_service.dart';
import '../domain/notificacao_model.dart';
import '../services/local_notification_service.dart';

/// Lê as notificações do morador e marca-as como lidas.
/// Implementa a Arquitetura Híbrida: Hive (L1 contador) + SQLite (L2 lista/filtros) + Supabase (L3 nuvem).
class NotificacaoDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  /// Lê as notificações do utilizador autenticado usando a estratégia SWR:
  /// 1. Exibe instantaneamente as notificações salvas no SQLite L2.
  /// 2. Sincroniza em segundo plano com o Supabase.
  Future<List<NotificacaoModel>> fetchNotificacoes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final unreadHiveKey = 'unread_notif_count_$userId';

    return await CacheManager.instance.executeSWR<NotificacaoModel>(
      loadFromLocal: () async {
        final rows = await SqliteService.instance.getNotificacoes(userId);
        if (rows.isNotEmpty) {
          return rows.map((r) => _mapSqliteToModel(r)).toList();
        }
        return [];
      },
      fetchFromRemote: () async {
        final rows = await _client
            .from('notificacao')
            .select('*')
            .eq('id_utilizador', userId)
            .order('data_hora', ascending: false);

        return (rows as List)
            .map((r) => NotificacaoModel.fromJson(r as Map<String, dynamic>))
            .toList();
      },
      saveToLocal: (freshList) async {
        final rawMaps = freshList.map((n) {
          return {
            'id_notificacao': n.id,
            'id_utilizador': userId,
            'id_ocorrencia': n.idOcorrencia,
            'tipo': n.tipo,
            'mensagem': n.mensagem,
            'lida': n.lida ? 1 : 0,
            'data_hora': n.dataHora.toUtc().toIso8601String(),
          };
        }).toList();

        await SqliteService.instance.saveNotificacoes(userId, rawMaps);
        final unreadCount = freshList.where((n) => !n.lida).length;
        await CacheManager.instance.putFast(unreadHiveKey, unreadCount);
      },
    );
  }

  /// Marca uma notificação individual como lida com atualização otimista local.
  Future<void> marcarComoLida(String idNotificacao) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Atualização Otimista no SQLite L2
    await SqliteService.instance.updateNotificacaoLida(idNotificacao, true);

    // 2. Atualiza badge Hive L1
    final unreadHiveKey = 'unread_notif_count_$userId';
    final currentCount = CacheManager.instance.getFast<int>(unreadHiveKey) ?? 1;
    final newCount = (currentCount > 0) ? currentCount - 1 : 0;
    await CacheManager.instance.putFast(unreadHiveKey, newCount);

    if (newCount == 0) {
      await LocalNotificationService.cancelAllNotifications();
    }

    // 3. Atualização Remota ou Fila de Sincronização
    try {
      await _client
          .from('notificacao')
          .update({'lida': true})
          .eq('id_notificacao', idNotificacao)
          .eq('id_utilizador', userId);
    } catch (e) {
      debugPrint('Offline/Erro ao marcar notificação como lida: $e. Enfileirando...');
      await SyncQueueService.instance.enqueueNotificacaoLida(
        idUtilizador: userId,
        idNotificacao: idNotificacao,
      );
    }
  }

  /// Marca todas as notificações não lidas do utilizador como lidas de uma vez.
  Future<void> marcarTodasComoLidas() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Atualização Otimista no SQLite L2
    await SqliteService.instance.marcarTodasNotificacoesLidas(userId);

    // 2. Zera o badge no Hive L1
    final unreadHiveKey = 'unread_notif_count_$userId';
    await CacheManager.instance.putFast(unreadHiveKey, 0);
    await LocalNotificationService.cancelAllNotifications();

    // 3. Atualização Remota ou Fila de Sincronização
    try {
      await _client
          .from('notificacao')
          .update({'lida': true})
          .eq('id_utilizador', userId)
          .eq('lida', false);
    } catch (e) {
      debugPrint('Offline/Erro ao marcar todas notificações: $e. Enfileirando...');
      await SyncQueueService.instance.enqueueNotificacaoLida(
        idUtilizador: userId,
        marcarTodas: true,
      );
    }
  }

  NotificacaoModel _mapSqliteToModel(Map<String, dynamic> row) {
    return NotificacaoModel(
      id: row['id_notificacao'] as String,
      idUtilizador: row['id_utilizador'] as String,
      idOcorrencia: row['id_ocorrencia'] as String?,
      tipo: row['tipo'] as String,
      mensagem: row['mensagem'] as String,
      lida: (row['lida'] == 1 || row['lida'] == true),
      dataHora: DateTime.tryParse(row['data_hora'].toString()) ?? DateTime.now(),
    );
  }

  /// Subscreve alterações em tempo real na tabela "notificacao" para o utilizador atual.
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
