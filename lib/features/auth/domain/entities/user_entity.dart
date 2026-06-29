class UserEntity {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String neighborhood;
  final String? token;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.neighborhood,
    this.token,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          email == other.email &&
          phoneNumber == other.phoneNumber &&
          neighborhood == other.neighborhood &&
          token == other.token;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      email.hashCode ^
      phoneNumber.hashCode ^
      neighborhood.hashCode ^
      token.hashCode;
}
