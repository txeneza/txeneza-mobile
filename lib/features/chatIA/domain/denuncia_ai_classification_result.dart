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

  /// Se a IA considera que a fotografia mostra mesmo resíduos/lixo. Quando
  /// `false`, a categoria/gravidade sugeridas não devem ser aplicadas
  /// automaticamente — o utilizador deve confirmar/escolher manualmente.
  final bool residuoDetectado;

  const DenunciaAIClassificationResult({
    required this.categoriaSugerida,
    required this.gravidadeSugerida,
    required this.explicacao,
    required this.confianca,
    this.residuoDetectado = true,
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

    // Categoria: chamador (classifyReportImage) já garante que este campo
    // existe antes de chegar aqui — não fabricamos "Outros" por omissão.
    final categoria = json['categoria'] as String;

    return DenunciaAIClassificationResult(
      categoriaSugerida: categoria,
      gravidadeSugerida: Gravidade.fromDb(gravStr),
      explicacao: json['explicacao'] as String? ?? 'Análise fotográfica efetuada com sucesso.',
      confianca: rawConfianca.clamp(0.0, 1.0),
      residuoDetectado: json['residuo_detectado'] as bool? ?? true,
    );
  }
}
