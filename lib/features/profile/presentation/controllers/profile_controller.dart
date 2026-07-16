import 'package:flutter/material.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileState _state = const ProfileInitial();
  ProfileState get state => _state;

  ProfileController({
    required ProfileRepository repository,
  }) : _repository = repository;

  Future<void> loadProfile() async {
    _state = const ProfileLoading();
    notifyListeners();

    try {
      final profile = await _repository.getProfile();
      final stats = await _repository.getStats();
      _state = ProfileLoaded(profile, stats);
    } catch (e) {
      _state = ProfileError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      notifyListeners();
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
