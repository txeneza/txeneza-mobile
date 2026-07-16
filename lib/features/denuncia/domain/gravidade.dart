/// Gravidade da ocorrência, alinhada com o enum "Gravidade" da base de dados
/// ('baixa', 'media', 'alta', 'critica').
enum Gravidade {
  baixa,
  media,
  alta,
  critica;

  /// Valor tal como gravado na coluna `gravidade` (enum do Postgres).
  String get dbValue => name;

  /// Rótulo apresentado ao utilizador.
  String get label {
    switch (this) {
      case Gravidade.baixa:
        return 'Baixa';
      case Gravidade.media:
        return 'Média';
      case Gravidade.alta:
        return 'Alta';
      case Gravidade.critica:
        return 'Crítica';
    }
  }

  static Gravidade fromDb(String value) {
    return Gravidade.values.firstWhere(
      (g) => g.name == value,
      orElse: () => Gravidade.media,
    );
  }
}
