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

  Map<String, dynamic> toJson() {
    return {
      'submitted': submitted,
      'resolved': resolved,
      'pending': pending,
    };
  }

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      submitted: json['submitted'] as int? ?? 0,
      resolved: json['resolved'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
    );
  }
}
