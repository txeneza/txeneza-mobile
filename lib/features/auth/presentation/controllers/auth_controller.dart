import 'package:flutter/material.dart';
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

  AuthController({
    required AuthRepository repository,
  }) : _repository = repository;

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
      _state = AuthError(e.toString());
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
      final user = await _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        neighborhood: neighborhood,
      );
      _state = AuthSuccess(user);
    } catch (e) {
      _state = AuthError(e.toString());
    } finally {
      notifyListeners();
    }
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
}
