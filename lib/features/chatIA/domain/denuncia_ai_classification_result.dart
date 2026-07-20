import '../../denuncia/domain/gravidade.dart';

/// Resultado da pré-classificação por IA (Gemini) de uma fotografia de resíduo.
class DenunciaAIClassificationResult {
  /// Nome ou id da categoria identificada pela IA.
  final String categoriaSugerida;

  /// Nível de gravidade sugerido.
  final Gravidade gravidadeSugerida;

  /// Breve explicação ou justificação gerada pela IA.
  final String explicacao;

  const DenunciaAIClassificationResult({
    required this.categoriaSugerida,
    required this.gravidadeSugerida,
    required this.explicacao,
  });

  factory DenunciaAIClassificationResult.fromJson(Map<String, dynamic> json) {
    final gravStr = (json['gravidade'] as String? ?? 'media').toLowerCase();
    return DenunciaAIClassificationResult(
      categoriaSugerida: json['categoria'] as String? ?? 'Outros',
      gravidadeSugerida: Gravidade.fromDb(gravStr),
      explicacao: json['explicacao'] as String? ?? 'Análise fotográfica efetuada.',
    );
  }
}
