/// Resumo real da atividade do utilizador, calculado a partir das suas
/// ocorrências na tabela `ocorrencia`.
class ProfileStats {
  final int submitted;
  final int resolved;
  final int pending;

  const ProfileStats({
    required this.submitted,
    required this.resolved,
    required this.pending,
  });

  static const ProfileStats empty =
      ProfileStats(submitted: 0, resolved: 0, pending: 0);
}
