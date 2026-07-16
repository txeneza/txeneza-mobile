import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;

  AuthState _state = const AuthInitial();
  AuthState get state => _state;

  List<String> _neighborhoods = [];
  List<String> get neighborhoods => _neighborhoods;

  bool _isLoadingNeighborhoods = false;
  bool get isLoadingNeighborhoods => _isLoadingNeighborhoods;

  String? _neighborhoodsError;
  String? get neighborhoodsError => _neighborhoodsError;

  StreamSubscription<UserEntity>? _externalSignInSubscription;

  AuthController({
    required AuthRepository repository,
  }) : _repository = repository {
    _externalSignInSubscription =
        _repository.onExternalSignIn.listen(_onExternalSignIn);
  }

  void _onExternalSignIn(UserEntity user) {
    // login()/signUp() já tratam o próprio resultado; isto cobre apenas o
    // regresso assíncrono do fluxo OAuth do Google via deep link.
    if (_state is AuthSuccess) return;
    _state = AuthSuccess(user);
    notifyListeners();
  }

  void resetState() {
    _state = const AuthInitial();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      final user = await _repository.login(
        email: email,
        password: password,
      );
      _state = AuthSuccess(user);
    } catch (e) {
      _state = AuthError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String neighborhood,
  }) async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      final result = await _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        neighborhood: neighborhood,
      );
      _state = result.needsEmailConfirmation
          ? AuthSignUpPendingConfirmation(result.user)
          : AuthSuccess(result.user);
    } catch (e) {
      _state = AuthError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      // Abre o browser para o fluxo OAuth; o resultado chega de forma
      // assíncrona através de onExternalSignIn (deep link de regresso).
      await _repository.signInWithGoogle();
    } catch (e) {
      _state = AuthError(e.toString().replaceAll('Exception: ', ''));
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _state = const AuthInitial();
    notifyListeners();
  }

  Future<void> fetchNeighborhoods() async {
    if (_neighborhoods.isNotEmpty) return; // Evita recargas desnecessárias

    _isLoadingNeighborhoods = true;
    _neighborhoodsError = null;
    notifyListeners();

    try {
      _neighborhoods = await _repository.getNeighborhoods();
    } catch (e) {
      _neighborhoodsError = e.toString();
    } finally {
      _isLoadingNeighborhoods = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _externalSignInSubscription?.cancel();
    super.dispose();
  }
}
