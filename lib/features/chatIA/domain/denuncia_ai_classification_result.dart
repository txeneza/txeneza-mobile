import '../../denuncia/domain/gravidade.dart';

/// Resultado da pré-classificação por IA (Gemini) de uma fotografia de resíduo.
class DenunciaAIClassificationResult {
  /// Nome ou id da categoria identificada pela IA.
  final String categoriaSugerida;

  /// Nível de gravidade sugerido.
  final Gravidade gravidadeSugerida;

  /// Breve explicação ou justificação gerada pela IA.
  final String explicacao;

  /// Grau de confiança da classificação (de 0.0 a 1.0, ex: 0.85 para 85%).
  final double confianca;

  const DenunciaAIClassificationResult({
    required this.categoriaSugerida,
    required this.gravidadeSugerida,
    required this.explicacao,
    required this.confianca,
  });

  factory DenunciaAIClassificationResult.fromJson(Map<String, dynamic> json) {
    final gravStr = (json['gravidade'] as String? ?? 'media').toLowerCase();

    // Extrair a confiança (pode vir como número 0-100 ou 0.0-1.0)
    double rawConfianca = 0.85;
    final confVal = json['confianca'];
    if (confVal is num) {
      rawConfianca = confVal.toDouble();
      if (rawConfianca > 1.0) {
        rawConfianca = rawConfianca / 100.0;
      }
    }

    return DenunciaAIClassificationResult(
      categoriaSugerida: json['categoria'] as String? ?? 'Outros',
      gravidadeSugerida: Gravidade.fromDb(gravStr),
      explicacao: json['explicacao'] as String? ?? 'Análise fotográfica efetuada com sucesso.',
      confianca: rawConfianca.clamp(0.0, 1.0),
    );
  }
}
