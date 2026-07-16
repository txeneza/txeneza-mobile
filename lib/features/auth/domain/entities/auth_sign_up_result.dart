import 'user_entity.dart';

class AuthSignUpResult {
  final UserEntity user;
  final bool needsEmailConfirmation;

  const AuthSignUpResult({
    required this.user,
    required this.needsEmailConfirmation,
  });
}
