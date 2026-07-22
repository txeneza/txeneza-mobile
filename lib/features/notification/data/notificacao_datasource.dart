import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notificacao_model.dart';

/// Lê as notificações do morador e marca-as como lidas.
/// Suporta cache local (SharedPreferences) para funcionamento offline.
class NotificacaoDataSource {
  static const String _prefsKeyPrefix = 'notificacoes_cache_';

  SupabaseClient get _client => Supabase.instance.client;

  /// Lê as notificações do utilizador autenticado, da mais recente para a
  /// mais antiga. Se a leitura de rede falhar (ex: offline), carrega da cache local.
  Future<List<NotificacaoModel>> fetchNotificacoes() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('notificacao')
          .select('*')
          .eq('id_utilizador', userId)
          .order('data_hora', ascending: false);

      final list = (rows as List)
          .map((r) => NotificacaoModel.fromJson(r as Map<String, dynamic>))
          .toList();

      await _saveToCache(userId, list);
      return list;
    } catch (e) {
      debugPrint('Rede indisponível para notificações ($e). A carregar cache local...');
      return await _loadFromCache(userId);
    }
  }

  /// Marca uma notificação individual como lida.
  Future<void> marcarComoLida(String idNotificacao) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final cached = await _loadFromCache(userId);
    final updatedList = cached.map((n) {
      if (n.id == idNotificacao) {
        return n.copyWith(lida: true);
      }
      return n;
    }).toList();
    await _saveToCache(userId, updatedList);

    try {
      await _client
          .from('notificacao')
          .update({'lida': true})
          .eq('id_notificacao', idNotificacao)
          .eq('id_utilizador', userId);
    } catch (e) {
      debugPrint('Erro ao marcar notificação como lida no Supabase: $e');
    }
  }

  /// Marca todas as notificações não lidas do utilizador como lidas de uma vez.
  Future<void> marcarTodasComoLidas() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final cached = await _loadFromCache(userId);
    final updatedList = cached.map((n) => n.copyWith(lida: true)).toList();
    await _saveToCache(userId, updatedList);

    try {
      await _client
          .from('notificacao')
          .update({'lida': true})
          .eq('id_utilizador', userId)
          .eq('lida', false);
    } catch (e) {
      debugPrint('Erro ao marcar todas as notificações como lidas no Supabase: $e');
    }
  }

  Future<void> _saveToCache(String userId, List<NotificacaoModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((n) => n.toJson()).toList());
      await prefs.setString('$_prefsKeyPrefix$userId', encoded);
    } catch (e) {
      debugPrint('Erro ao gravar cache de notificações: $e');
    }
  }

  Future<List<NotificacaoModel>> _loadFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsKeyPrefix$userId');
      if (raw == null) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((r) => NotificacaoModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar cache de notificações: $e');
      return [];
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
