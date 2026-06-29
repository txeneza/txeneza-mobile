import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/beira_neighborhoods.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  static const String _usersKey = 'mock_registered_users';
  static const String _sessionKey = 'mock_user_session';

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Simula atraso de rede (latência de 1.5 segundos)
    await Future.delayed(const Duration(milliseconds: 1500));

    final cleanEmail = email.trim().toLowerCase();
    
    // Buscar usuários cadastrados localmente
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    
    UserModel? matchedUser;
    for (final jsonStr in usersJson) {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      if (map['email'] == cleanEmail) {
        matchedUser = UserModel.fromJson(map);
        break;
      }
    }

    // Para fins de demonstração, se não houver usuários cadastrados ainda, 
    // permitimos login com qualquer senha se o e-mail for "demo@txeneza.com" e senha "Txeneza123"
    if (matchedUser == null && cleanEmail == 'demo@txeneza.com' && password == 'Txeneza123') {
      matchedUser = const UserModel(
        id: 'demo-user-id',
        fullName: 'Usuário Demo',
        email: 'demo@txeneza.com',
        phoneNumber: '841234567',
        neighborhood: 'Ponta Gêa',
      );
    }

    if (matchedUser == null) {
      throw Exception('Usuário não encontrado. Registre-se primeiro.');
    }

    // Se o usuário existir, mas a senha for inválida (no mockup aceitamos qualquer senha para o demo,
    // ou se cadastrado, a senha inserida é simulada. Para ser robusto, guardamos a senha no mock se desejado.
    // Guardamos a senha no JSON do mock para validação real)
    final savedPassword = _getSavedPasswordForUser(usersJson, cleanEmail) ?? 'Txeneza123';
    if (password != savedPassword) {
      throw Exception('Credenciais inválidas. Palavra-passe incorreta.');
    }

    // Gerar token JWT mockado
    final userWithToken = UserModel(
      id: matchedUser.id,
      fullName: matchedUser.fullName,
      email: matchedUser.email,
      phoneNumber: matchedUser.phoneNumber,
      neighborhood: matchedUser.neighborhood,
      token: 'mock-jwt-token-header.${base64Encode(utf8.encode(matchedUser.email))}.signature',
    );

    // Salvar sessão ativa
    await prefs.setString(_sessionKey, json.encode(userWithToken.toJson()));

    return userWithToken;
  }

  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String neighborhood,
  }) async {
    // Simula atraso de rede (latência de 1.5 segundos)
    await Future.delayed(const Duration(milliseconds: 1500));

    final cleanEmail = email.trim().toLowerCase();

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];

    // Verificar duplicados
    for (final jsonStr in usersJson) {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      if (map['email'] == cleanEmail) {
        throw Exception('Este endereço de e-mail já está associado a uma conta.');
      }
    }

    // Criar novo usuário
    final newId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final cleanName = _sanitizeFullName(fullName);

    final newUser = UserModel(
      id: newId,
      fullName: cleanName,
      email: cleanEmail,
      phoneNumber: phoneNumber.replaceAll(' ', ''),
      neighborhood: neighborhood,
    );

    // Salvar usuário com a senha
    final userMap = newUser.toJson();
    userMap['password'] = password; // Apenas para validação no mockup local

    usersJson.add(json.encode(userMap));
    await prefs.setStringList(_usersKey, usersJson);

    return newUser;
  }

  Future<List<String>> getNeighborhoods() async {
    // Simula tempo de resposta do banco de dados/Supabase
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Retorna a lista de bairros do arquivo de constantes
    return BeiraNeighborhoods.list;
  }

  // Helpers
  String _sanitizeFullName(String name) {
    // Remove espaços duplicados e limpa extremidades
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _getSavedPasswordForUser(List<String> usersList, String email) {
    for (final jsonStr in usersList) {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      if (map['email'] == email) {
        return map['password'] as String?;
      }
    }
    return null;
  }
}
