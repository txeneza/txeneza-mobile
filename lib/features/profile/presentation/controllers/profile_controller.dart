import 'package:flutter/material.dart';
import '../../data/models/profile_user_model.dart';
import '../../domain/profile_stats.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileState _state = const ProfileInitial();
  ProfileState get state => _state;

  ProfileController({
    required ProfileRepository repository,
  }) : _repository = repository;

  Future<void> loadProfile({bool isRefresh = false}) async {
    ProfileUserModel? cachedProfile;
    ProfileStats? cachedStats;

    try {
      cachedProfile = await _repository.getCachedProfile();
      cachedStats = await _repository.getCachedStats();
    } catch (e) {
      debugPrint('Erro ao obter perfil da cache: $e');
    }

    // 1. Se temos perfil em cache ou sessão, exibe imediatamente (0ms)
    if (cachedProfile != null) {
      _state = ProfileLoaded(cachedProfile, cachedStats ?? ProfileStats.empty);
      notifyListeners();
    } else if (!isRefresh) {
      _state = const ProfileLoading();
      notifyListeners();
    }

    // 2. Revalidação em segundo plano no Supabase
    try {
      final freshProfile = await _repository.fetchRemoteProfile();
      final freshStats = await _repository.fetchRemoteStats();
      _state = ProfileLoaded(freshProfile, freshStats);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao buscar perfil remoto: $e');
      if (_state is! ProfileLoaded) {
        // Tenta mais um fallback seguro para nunca deixar o utilizador preso em loading
        final fallback = await _repository.getCachedProfile();
        if (fallback != null) {
          _state = ProfileLoaded(fallback, cachedStats ?? ProfileStats.empty);
        } else {
          _state = ProfileError(e.toString().replaceAll('Exception: ', ''));
        }
        notifyListeners();
      }
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String neighborhood,
  }) async {
    final currentState = _state;
    if (currentState is! ProfileLoaded) return false;

    final currentProfile = currentState.profile;
    final stats = currentState.stats;
    final updatedProfile = currentProfile.copyWith(
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim().replaceAll(' ', ''),
      neighborhood: neighborhood.trim(),
    );

    _state = ProfileUpdating(currentProfile, stats);
    notifyListeners();

    try {
      await _repository.updateProfile(updatedProfile);
      _state = ProfileLoaded(updatedProfile, stats);
      notifyListeners();
      return true;
    } catch (e) {
      _state = ProfileLoaded(currentProfile, stats); // Reverte
      notifyListeners();
      return false;
    }
  }

  /// Apaga a conta permanentemente. Lança em caso de erro para a UI tratar.
  Future<void> deleteAccount() => _repository.deleteAccount();
}
