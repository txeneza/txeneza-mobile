import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/profile_user_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  static const String _usersKey = 'mock_registered_users';
  static const String _sessionKey = 'mock_user_session';

  @override
  Future<ProfileUserModel> getProfile() async {
    // Simular latência de rede/banco de dados (600ms)
    await Future.delayed(const Duration(milliseconds: 600));

    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);

    if (sessionJson == null) {
      throw Exception('Nenhuma sessão ativa encontrada. Faça login novamente.');
    }

    try {
      final Map<String, dynamic> userMap = json.decode(sessionJson) as Map<String, dynamic>;
      return ProfileUserModel.fromJson(userMap);
    } catch (e) {
      throw Exception('Erro ao processar os dados do perfil.');
    }
  }

  @override
  Future<void> updateProfile(ProfileUserModel profile) async {
    // Simular latência de rede (800ms)
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();

    // 1. Atualizar sessão atual do usuário
    final updatedSessionJson = json.encode(profile.toJson());
    await prefs.setString(_sessionKey, updatedSessionJson);

    // 2. Atualizar nos usuários registrados para consistência entre logins
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    bool userUpdated = false;

    for (int i = 0; i < usersJson.length; i++) {
      final Map<String, dynamic> userMap = json.decode(usersJson[i]) as Map<String, dynamic>;
      if (userMap['email'] == profile.email) {
        // Preserva a senha para não quebrar o login futuro
        final savedPassword = userMap['password'];
        
        final Map<String, dynamic> updatedUserMap = profile.toJson();
        if (savedPassword != null) {
          updatedUserMap['password'] = savedPassword;
        }
        
        usersJson[i] = json.encode(updatedUserMap);
        userUpdated = true;
        break;
      }
    }

    if (userUpdated) {
      await prefs.setStringList(_usersKey, usersJson);
    }
  }
}
