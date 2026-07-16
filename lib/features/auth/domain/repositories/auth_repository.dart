import '../entities/auth_sign_up_result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<AuthSignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String neighborhood,
  });

  Future<void> signInWithGoogle();

  Future<void> logout();

  Future<List<String>> getNeighborhoods();

  /// Emite um utilizador sempre que uma sessão é criada fora de login()/signUp()
  /// (por exemplo, após o regresso do fluxo de OAuth do Google via deep link).
  Stream<UserEntity> get onExternalSignIn;
}
