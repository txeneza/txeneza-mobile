import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/env/app_env.dart';
import '../../domain/denuncia_ai_classification_result.dart';
import '../xeni_prompt.dart';

/// Um turno da conversa, usado para dar contexto ao modelo.
class ChatTurn {
  final String text;
  final bool isUser;
  const ChatTurn({required this.text, required this.isUser});
}

class GeminiService {
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];
  static const int _maxRetries = 2;

  /// Mensagem de texto para a Xeni, com o system prompt e o histórico recente
  /// para manter o contexto da conversa.
  ///
  /// [userContext], quando fornecido (ver UserContextService), é anexado ao
  /// system prompt da Xeni para ela saber o nome do utilizador e um resumo
  /// da sua actividade — é só contexto de leitura, nunca dá à Xeni acesso a
  /// executar ações no sistema.
  Future<String> sendMessage(
    String message, {
    List<ChatTurn> history = const [],
    String? userContext,
  }) async {
    final contents = <Map<String, dynamic>>[
      for (final turn in history)
        {
          'role': turn.isUser ? 'user' : 'model',
          'parts': [
            {'text': turn.text}
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      },
    ];

    final systemInstruction = userContext == null || userContext.isEmpty
        ? kXeniSystemPrompt
        : '$kXeniSystemPrompt\n\n$userContext';

    return _generate(contents, systemInstruction: systemInstruction);
  }

  /// Classificação multimodal de uma imagem de resíduo (texto + imagem).
  /// [imageBytes] é o conteúdo do ficheiro; [mimeType] ex.: 'image/jpeg'.
  Future<String> classifyImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
    String? hint,
  }) async {
    final contents = [
      {
        'role': 'user',
        'parts': [
          {
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Encode(imageBytes),
            }
          },
          {
            'text': hint?.trim().isNotEmpty == true
                ? 'Classifica o resíduo nesta fotografia. Contexto: $hint'
                : 'Classifica o resíduo nesta fotografia.'
          },
        ],
      },
    ];

    return _generate(contents);
  }

  /// Classificação estruturada de uma foto de ocorrência (RF-010).
  /// Retorna um objeto `DenunciaAIClassificationResult` com a categoria, gravidade e explicação.
  /// Devolve `null` se a foto não puder ser classificada com confiança
  /// (resposta malformada, sem os campos obrigatórios, etc.) — o chamador
  /// deve nesse caso pedir ao utilizador para escolher a categoria
  /// manualmente, nunca assumir um resultado inventado.
  Future<DenunciaAIClassificationResult?> classifyReportImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    const promptText = '''
Analisa esta fotografia de resíduo urbano/ambiental e responde estritamente num formato JSON válido sem formatação markdown ou código adicional:
{
  "residuo_detectado": true ou false,
  "categoria": "Nome da categoria provável ex: Plástico, Vidro, Entulho, Matéria Orgânica, Lixo Eletrónico, Papel/Cartão, Metais ou Outro",
  "gravidade": "baixa ou media ou alta ou critica",
  "explicacao": "Descrição objectiva em 1-2 frases do que foi observado na imagem.",
  "confianca": 85
}
''';

    final contents = [
      {
        'role': 'user',
        'parts': [
          {
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Encode(imageBytes),
            }
          },
          {'text': promptText},
        ],
      },
    ];

    try {
      final rawResponse = await _generate(
        contents,
        systemInstruction: kImageClassificationSystemPrompt,
      );
      // Tentar extrair o JSON mesmo se a IA envolver em blocos ```json ... ```
      String cleanedJson = rawResponse.replaceAll(RegExp(r'^```json\s*|\s*```$'), '').trim();
      final startIndex = cleanedJson.indexOf('{');
      final endIndex = cleanedJson.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleanedJson = cleanedJson.substring(startIndex, endIndex + 1);
      }
      final parsedMap = jsonDecode(cleanedJson) as Map<String, dynamic>;

      // Se a resposta não tiver sequer o campo "categoria", não é uma
      // classificação válida — não fabricamos um resultado por omissão
      // (isso já causou classificações "falsas" no passado: qualquer
      // resposta malformada virava silenciosamente "Outros" a 85% de
      // confiança, como se fosse uma classificação real).
      if (parsedMap['categoria'] == null) {
        debugPrint('Resposta da IA sem campo "categoria" — a descartar.');
        return null;
      }

      return DenunciaAIClassificationResult.fromJson(parsedMap);
    } catch (e) {
      debugPrint('Falha ao processar resposta JSON da IA: $e');
      return null;
    }
  }

  /// Núcleo da chamada à API, com system prompt, fallback de modelos e retry.
  /// [systemInstruction] por omissão é o prompt conversacional da Xeni; a
  /// classificação estruturada (classifyReportImage) usa um prompt próprio,
  /// mais estrito e sem personalidade (ver kImageClassificationSystemPrompt).
  Future<String> _generate(
    List<Map<String, dynamic>> contents, {
    String systemInstruction = kXeniSystemPrompt,
  }) async {
    final apiKey = AppEnv.geminiApiKey;
    if (apiKey.isEmpty) {
      return 'A chave da API do Gemini não está configurada.';
    }

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'contents': contents,
      'generationConfig': {
        // Temperatura baixa: respostas mais focadas e menos genéricas.
        'temperature': 0.4,
        'maxOutputTokens': 1600,
      },
    });

    for (final model in _models) {
      int attempt = 0;
      while (attempt <= _maxRetries) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        try {
          final response = await http.post(
            url,
            headers: {'content-type': 'application/json'},
            body: body,
          );

          if (response.statusCode == 200) {
            return _extractText(response.body);
          } else if (response.statusCode == 503) {
            attempt++;
            if (attempt <= _maxRetries) {
              await Future.delayed(Duration(seconds: attempt * 2));
              continue;
            }
            debugPrint('Modelo $model ocupado após $_maxRetries tentativas.');
          } else if (response.statusCode == 400 || response.statusCode == 403) {
            // Chave inválida/sem permissão: tentar outro modelo não ajuda.
            debugPrint('Gemini rejeitou o pedido '
                '(${response.statusCode}): ${response.body}');
            return 'A chave da API do Gemini é inválida ou não tem acesso. '
                'Verifique a GEMINI_API_KEY no ficheiro .env.';
          } else {
            debugPrint('Erro Gemini (${response.statusCode}): ${response.body}');
            break; // tenta o próximo modelo
          }
        } catch (e) {
          attempt++;
          if (attempt <= _maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          debugPrint('Erro de ligação ao modelo $model: $e');
        }
      }
    }

    return 'O serviço da Xeni está indisponível de momento. Tente novamente daqui a instantes.';
  }

  String _extractText(String responseBody) {
    final json = jsonDecode(responseBody);
    final candidates = json['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates[0]['content'] as Map?;
      final parts = content?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        final text = parts[0]['text'] as String?;
        if (text != null) return text.trim();
      }
    }
    return 'Não consegui gerar uma resposta. Tente reformular a pergunta.';
  }
}
