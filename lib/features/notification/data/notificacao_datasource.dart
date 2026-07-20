import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notificacao_model.dart';
import '../services/local_notification_service.dart';

/// Datasource de gestão e sincronização de notificações ao morador.
class NotificacaoDataSource {
  static const String _localPrefsKey = 'txeneza_notifications_local';
  static const String _lastKnownStatusesKey = 'txeneza_occurrences_statuses';

  SupabaseClient get _client => Supabase.instance.client;

  /// Lê as notificações do morador (Supabase com fallback para armazenamento local).
  Future<List<NotificacaoModel>> fetchNotificacoes() async {
    final userId = _client.auth.currentUser?.id;
    final List<NotificacaoModel> list = [];

    if (userId != null) {
      try {
        final rows = await _client
            .from('notificacao')
            .select('*')
            .eq('id_utilizador', userId)
            .order('data_hora', ascending: false);

        for (final r in (rows as List)) {
          list.add(NotificacaoModel.fromJson(r as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('Tabela notificacao inacessível no Supabase: $e');
      }
    }

    // Combina com notificações guardadas localmente
    final localList = await _fetchLocalNotifications();
    for (final item in localList) {
      if (!list.any((n) => n.id == item.id)) {
        list.add(item);
      }
    }

    list.sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return list;
  }

  /// Verifica se alguma ocorrência do morador mudou de estado e dispara a notificação.
  Future<void> checkStatusChangesAndNotify() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final rows = await _client
          .from('ocorrencia')
          .select('id_ocorrencia, estado, categoria_residuo(nome)')
          .eq('id_utilizador', userId);

      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString(_lastKnownStatusesKey);
      final Map<String, String> lastKnown = cachedJson != null
          ? Map<String, String>.from(jsonDecode(cachedJson) as Map)
          : {};

      final Map<String, String> updatedKnown = {};

      for (final r in (rows as List)) {
        final id = r['id_ocorrencia'] as String;
        final estadoAtual = r['estado'] as String? ?? 'pendente';
        final categoria = r['categoria_residuo'] as Map<String, dynamic>?;
        final nomeCategoria = categoria?['nome'] as String? ?? 'Resíduo';

        updatedKnown[id] = estadoAtual;

        // Se já conhecíamos esta ocorrência e o estado mudou:
        if (lastKnown.containsKey(id) && lastKnown[id] != estadoAtual) {
          final estadoAntigo = lastKnown[id];
          final titulo = 'Estado da Denúncia Atualizado';
          final mensagem =
              'A sua ocorrência "$nomeCategoria" mudou de "${_formatEstado(estadoAntigo)}" para "${_formatEstado(estadoAtual)}".';

          // 1. Notificação local imediata no dispositivo (Push/Local)
          await LocalNotificationService.showNotification(
            id: id.hashCode,
            title: titulo,
            body: mensagem,
          );

          // 2. Registar notificação no Supabase e localmente
          final notif = NotificacaoModel(
            id: 'notif_${id}_${DateTime.now().millisecondsSinceEpoch}',
            idUtilizador: userId,
            idOcorrencia: id,
            titulo: titulo,
            mensagem: mensagem,
            lida: false,
            tipo: 'mudanca_estado',
            dataHora: DateTime.now(),
          );

          await _persistNotificacao(notif);
        }
      }

      await prefs.setString(_lastKnownStatusesKey, jsonEncode(updatedKnown));
    } catch (e) {
      debugPrint('Erro ao verificar mudança de estado para notificações: $e');
    }
  }

  /// Marca a notificação como lida.
  Future<void> marcarComoLida(String idNotificacao) async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _client
            .from('notificacao')
            .update({'lida': true})
            .eq('id_notificacao', idNotificacao);
      } catch (_) {}
    }

    final localList = await _fetchLocalNotifications();
    final updated = localList.map((n) {
      if (n.id == idNotificacao) return n.copyWith(lida: true);
      return n;
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    final jsonList = updated.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_localPrefsKey, jsonList);
  }

  Future<void> _persistNotificacao(NotificacaoModel notif) async {
    try {
      await _client.from('notificacao').upsert(notif.toJson());
    } catch (_) {}

    final localList = await _fetchLocalNotifications();
    localList.insert(0, notif);
    final prefs = await SharedPreferences.getInstance();
    final jsonList = localList.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_localPrefsKey, jsonList);
  }

  Future<List<NotificacaoModel>> _fetchLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_localPrefsKey) ?? [];
    return list
        .map((s) => NotificacaoModel.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  String _formatEstado(String? estado) {
    switch (estado) {
      case 'pendente':
        return 'Pendente';
      case 'em_analise':
        return 'Em Análise';
      case 'em_progresso':
      case 'atribuida':
        return 'Em Progresso';
      case 'resolvida':
        return 'Resolvida';
      case 'reaberta':
        return 'Reaberta';
      default:
        return estado ?? 'Atualizado';
    }
  }
}
