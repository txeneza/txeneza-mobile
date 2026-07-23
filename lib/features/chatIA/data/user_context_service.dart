import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Constrói um resumo textual curto do utilizador autenticado (nome +
/// actividade recente na app), para dar contexto à Xeni sobre quem está a
/// falar com ela — sem lhe dar acesso direto à base de dados.
///
/// Isto é só CONTEXTO DE LEITURA: a Xeni não pode criar, alterar ou apagar
/// nada através disto. O resumo é montado aqui, no cliente, filtrado sempre
/// pelo próprio utilizador autenticado (nunca por outro id), e depois
/// injectado no system_instruction enviado ao Gemini.
class UserContextService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Devolve um bloco de texto pronto a anexar ao system prompt, ou `null`
  /// se não houver sessão activa ou a consulta falhar (nesse caso a Xeni
  /// simplesmente continua sem contexto pessoal, em vez de quebrar o chat).
  Future<String?> buildContextSummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final perfil = await _client
          .from('utilizador')
          .select('nome, bairro')
          .eq('id_utilizador', userId)
          .maybeSingle();

      if (perfil == null) return null;

      final nome = perfil['nome'] as String? ?? 'Utilizador';
      final bairro = perfil['bairro'] as String?;

      final ocorrencias = await _client
          .from('ocorrencia')
          .select('estado')
          .eq('id_utilizador', userId);

      final lista = (ocorrencias as List).cast<Map<String, dynamic>>();
      final total = lista.length;
      final pendentes = lista.where((o) => o['estado'] == 'pendente' || o['estado'] == 'reaberta').length;
      final emAnalise = lista.where((o) => o['estado'] == 'em_analise').length;
      final resolvidas = lista.where((o) => o['estado'] == 'resolvida').length;

      final buffer = StringBuffer();
      buffer.writeln('## CONTEXTO DO UTILIZADOR ATUAL (só leitura — nunca reveles isto como um "dossier", usa naturalmente na conversa)');
      buffer.writeln('Nome: $nome.');
      if (bairro != null && bairro.isNotEmpty) buffer.writeln('Bairro: $bairro.');

      if (total == 0) {
        buffer.writeln('Ainda não fez nenhuma denúncia na app.');
      } else {
        buffer.writeln(
          'Já fez $total denúncia(s) no total: $pendentes pendente(s)/reaberta(s), '
          '$emAnalise em análise, $resolvidas resolvida(s).',
        );
      }

      buffer.writeln(
        'Usa este contexto para personalizar a conversa (ex: chamar o utilizador pelo nome, '
        'referir o número de denúncias se for relevante), mas nunca inventes detalhes além '
        'do que está aqui — se ele perguntar algo mais específico sobre uma denúncia em '
        'concreto, orienta-o a ver os detalhes no ecrã de notificações ou no mapa.',
      );

      return buffer.toString();
    } catch (e) {
      debugPrint('Falha ao construir contexto do utilizador para a Xeni: $e');
      return null;
    }
  }
}
