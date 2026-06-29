import 'package:flutter/material.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileState _state = const ProfileInitial();
  ProfileState get state => _state;

  // Configurações locais (mock)
  bool _pushNotifications = true;
  bool get pushNotifications => _pushNotifications;

  bool _emailNotifications = false;
  bool get emailNotifications => _emailNotifications;

  bool _offlineSync = true;
  bool get offlineSync => _offlineSync;

  String _language = 'Português (MZ)';
  String get language => _language;

  // Permissões mockup
  bool _locationPermission = true;
  bool get locationPermission => _locationPermission;

  bool _cameraPermission = false;
  bool get cameraPermission => _cameraPermission;

  ProfileController({
    required ProfileRepository repository,
  }) : _repository = repository;

  Future<void> loadProfile() async {
    _state = const ProfileLoading();
    notifyListeners();

    try {
      final profile = await _repository.getProfile();
      _state = ProfileLoaded(profile);
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
    final updatedProfile = currentProfile.copyWith(
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim().replaceAll(' ', ''),
      neighborhood: neighborhood.trim(),
    );

    _state = ProfileUpdating(currentProfile);
    notifyListeners();

    try {
      await _repository.updateProfile(updatedProfile);
      _state = ProfileLoaded(updatedProfile);
      notifyListeners();
      return true;
    } catch (e) {
      _state = ProfileLoaded(currentProfile); // Reverte para o perfil anterior
      notifyListeners();
      return false;
    }
  }

  // Setters para configurações mockup
  void setPushNotifications(bool value) {
    _pushNotifications = value;
    notifyListeners();
  }

  void setEmailNotifications(bool value) {
    _emailNotifications = value;
    notifyListeners();
  }

  void setOfflineSync(bool value) {
    _offlineSync = value;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void setLocationPermission(bool value) {
    _locationPermission = value;
    notifyListeners();
  }

  void setCameraPermission(bool value) {
    _cameraPermission = value;
    notifyListeners();
  }
}
