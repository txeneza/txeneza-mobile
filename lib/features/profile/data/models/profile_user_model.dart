import '../../../auth/domain/entities/user_entity.dart';

class ProfileUserModel extends UserEntity {
  final int reportsSubmitted;
  final int reportsResolved;
  final int reportsPending;
  final bool isVerified;
  final int points;
  final int level;
  final List<String> badges;

  const ProfileUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phoneNumber,
    required super.neighborhood,
    super.token,
    required this.reportsSubmitted,
    required this.reportsResolved,
    required this.reportsPending,
    required this.isVerified,
    required this.points,
    required this.level,
    required this.badges,
  });

  ProfileUserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? neighborhood,
    String? token,
    int? reportsSubmitted,
    int? reportsResolved,
    int? reportsPending,
    bool? isVerified,
    int? points,
    int? level,
    List<String>? badges,
  }) {
    return ProfileUserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      neighborhood: neighborhood ?? this.neighborhood,
      token: token ?? this.token,
      reportsSubmitted: reportsSubmitted ?? this.reportsSubmitted,
      reportsResolved: reportsResolved ?? this.reportsResolved,
      reportsPending: reportsPending ?? this.reportsPending,
      isVerified: isVerified ?? this.isVerified,
      points: points ?? this.points,
      level: level ?? this.level,
      badges: badges ?? this.badges,
    );
  }

  factory ProfileUserModel.fromJson(Map<String, dynamic> json) {
    return ProfileUserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      neighborhood: json['neighborhood'] as String,
      token: json['token'] as String?,
      reportsSubmitted: json['reports_submitted'] as int? ?? 15,
      reportsResolved: json['reports_resolved'] as int? ?? 8,
      reportsPending: json['reports_pending'] as int? ?? 7,
      isVerified: json['is_verified'] as bool? ?? true,
      points: json['points'] as int? ?? 320,
      level: json['level'] as int? ?? 4,
      badges: (json['badges'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          ['Pioneiro da Beira', 'Guardião Verde', 'Denunciante Ativo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'neighborhood': neighborhood,
      'token': token,
      'reports_submitted': reportsSubmitted,
      'reports_resolved': reportsResolved,
      'reports_pending': reportsPending,
      'is_verified': isVerified,
      'points': points,
      'level': level,
      'badges': badges,
    };
  }
}
