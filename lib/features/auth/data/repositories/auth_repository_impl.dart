import '../../../../core/errors/supabase_error_translator.dart';
import '../../domain/entities/auth_sign_up_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _remoteDataSource.login(email: email, password: password);
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
  }

  @override
  Future<AuthSignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String neighborhood,
  }) async {
    try {
      final result = await _remoteDataSource.signUp(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        neighborhood: neighborhood,
      );
      return AuthSignUpResult(
        user: result.user,
        needsEmailConfirmation: result.needsEmailConfirmation,
      );
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _remoteDataSource.signInWithGoogle();
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
  }

  @override
  Future<List<String>> getNeighborhoods() async {
    try {
      return await _remoteDataSource.getNeighborhoods();
    } catch (e) {
      throw Exception('Não foi possível carregar a lista de bairros.');
    }
  }

  @override
  Stream<UserEntity> get onExternalSignIn => _remoteDataSource.onSignedIn;
}
