import '../../../auth/domain/entities/user_entity.dart';

/// Perfil do utilizador, mapeado da tabela "utilizador". Apenas dados reais —
/// sem campos de gamificação/placeholder.
class ProfileUserModel extends UserEntity {
  final bool isVerified;

  const ProfileUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phoneNumber,
    required super.neighborhood,
    super.token,
    required this.isVerified,
  });

  ProfileUserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? neighborhood,
  }) {
    return ProfileUserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      neighborhood: neighborhood ?? this.neighborhood,
      token: token,
      isVerified: isVerified,
    );
  }

  /// [json] é uma linha da tabela "utilizador" do Supabase.
  factory ProfileUserModel.fromJson(Map<String, dynamic> json) {
    return ProfileUserModel(
      id: json['id_utilizador'] as String,
      fullName: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['telefone'] as String? ?? '',
      neighborhood: json['bairro'] as String? ?? '',
      token: json['token'] as String?,
      isVerified: json['estado'] == 'activo',
    );
  }

  /// Apenas os campos editáveis pelo próprio utilizador.
  Map<String, dynamic> toUpdateJson() {
    return {
      'nome': fullName,
      'telefone': phoneNumber,
      'bairro': neighborhood,
    };
  }
}
