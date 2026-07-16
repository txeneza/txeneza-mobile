import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Uma troca guardada: mensagem do utilizador + resposta da Xeni.
class ConversaTurno {
  final String mensagemUtilizador;
  final String respostaXeni;
  final DateTime dataHora;

  const ConversaTurno({
    required this.mensagemUtilizador,
    required this.respostaXeni,
    required this.dataHora,
  });
}

/// Persiste e lê o histórico de conversa com a Xeni na tabela `conversacao_xeni`.
class ConversacaoDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  /// Guarda uma troca. Silencioso em erro: não deve quebrar o chat.
  Future<void> save({
    required String mensagem,
    required String resposta,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await _client.from('conversacao_xeni').insert({
        'id_mensagem': const Uuid().v4(),
        'id_utilizador': uid,
        'mensagem_utilizador': mensagem,
        'resposta_xeni': resposta,
        'modo': 'gemini',
        'data_hora': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Histórico não é crítico para a conversa em curso.
    }
  }

  /// Carrega o histórico do utilizador por ordem cronológica.
  Future<List<ConversaTurno>> fetchHistory() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _client
        .from('conversacao_xeni')
        .select('mensagem_utilizador, resposta_xeni, data_hora')
        .eq('id_utilizador', uid)
        .order('data_hora', ascending: true);

    return (rows as List).map((r) {
      final map = r as Map<String, dynamic>;
      return ConversaTurno(
        mensagemUtilizador: map['mensagem_utilizador'] as String? ?? '',
        respostaXeni: map['resposta_xeni'] as String? ?? '',
        dataHora: DateTime.tryParse(map['data_hora'].toString()) ??
            DateTime.now(),
      );
    }).toList();
  }
}
