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

  /// [json] é uma linha da tabela "utilizador" do Supabase ou mapa da cache local.
  factory ProfileUserModel.fromJson(Map<String, dynamic> json) {
    return ProfileUserModel(
      id: (json['id_utilizador'] ?? json['id'] ?? '').toString(),
      fullName: (json['nome'] ?? json['full_name'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: (json['telefone'] ?? json['phone'] ?? '').toString(),
      neighborhood: (json['bairro'] ?? json['neighborhood'] ?? '').toString(),
      token: json['token']?.toString(),
      isVerified: json['estado'] == 'activo' || json['is_verified'] == true,
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

  /// Converte o utilizador de volta a JSON para persistência em cache local.
  Map<String, dynamic> toJson() {
    return {
      'id_utilizador': id,
      'nome': fullName,
      'email': email,
      'telefone': phoneNumber,
      'bairro': neighborhood,
      'token': token,
      'estado': isVerified ? 'activo' : 'inactivo',
    };
  }
}
