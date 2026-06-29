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
      final userModel = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      return userModel;
    } catch (e) {
      // Repassa a mensagem do erro ou lança uma genérica
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<UserEntity> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String neighborhood,
  }) async {
    try {
      final userModel = await _remoteDataSource.signUp(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        neighborhood: neighborhood,
      );
      return userModel;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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
}
