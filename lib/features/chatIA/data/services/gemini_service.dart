import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/env/app_env.dart';

class GeminiService {
  Future<String> sendMessage(String message) async {
    final apiKey = AppEnv.geminiApiKey;
    if (apiKey.isEmpty) {
      return 'Erro: Chave da API do Gemini não configurada no arquivo .env.';
    }

    final models = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
    ];

    const maxRetries = 2; // Retries per model

    for (final model in models) {
      int attempt = 0;
      while (attempt <= maxRetries) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        try {
          final body = {
            'contents': [
              {
                'parts': [
                  {'text': message}
                ]
              }
            ]
          };

          final response = await http.post(
            url,
            headers: {'content-type': 'application/json'},
            body: jsonEncode(body),
          );

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            
            final candidates = jsonResponse['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'] as Map?;
              if (content != null) {
                final parts = content['parts'] as List?;
                if (parts != null && parts.isNotEmpty) {
                  final text = parts[0]['text'] as String?;
                  if (text != null) {
                    return text.trim();
                  }
                }
              }
            }
            return 'Resposta vazia ou formato de resposta inesperado.';
          } else if (response.statusCode == 503) {
            attempt++;
            if (attempt <= maxRetries) {
              final waitSeconds = attempt * 2;
              debugPrint('Servidor ocupado (503) no modelo $model. Tentativa $attempt de $maxRetries. Aguardando ${waitSeconds}s...');
              await Future.delayed(Duration(seconds: waitSeconds));
              continue;
            }
            debugPrint('Falha ao usar o modelo $model após $maxRetries tentativas.');
          } else {
            return 'Erro da API Gemini (${response.statusCode}): ${response.body}';
          }
        } catch (e) {
          attempt++;
          if (attempt <= maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          debugPrint('Erro de conexão com o modelo $model: $e');
        }
      }
    }

    return 'Erro: O serviço do Gemini está indisponível no momento devido à alta demanda. Por favor, tente novamente em instantes.';
  }

  /// Método auxiliar para simular a classificação de imagem online via Gemini
  Future<String> analyzeSimulatedImage(String imageName, String imageDescription) async {
    final prompt = '''
Você é a Xeni, assistente de IA da Txeneza.
O usuário enviou uma foto de uma ocorrência de saneamento/lixo chamada "$imageName" descrita como: "$imageDescription".
Com base nas diretrizes de limpeza e reciclagem da cidade da Beira:
1. Classifique a gravidade da situação (Baixa, Média, Alta ou Crítica).
2. Explique brevemente o tipo de resíduo identificado e o perigo potencial.
3. Descreva a ação recomendada para a Txeneza (ex: direcionar para coleta orgânica, acionar voluntários, encaminhar à edilidade).
4. Informe que um boletim de ocorrência foi pré-estruturado.

Responda em formato executivo, profissional, porém amigável, adequado para uma aplicação de gestão urbana Premium Enterprise.
''';
    return sendMessage(prompt);
  }
}
