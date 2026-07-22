import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/beira_neighborhoods.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  static const String _googleRedirectUrl = 'io.txeneza.app://login-callback';

  SupabaseClient get _client => Supabase.instance.client;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Não foi possível iniciar sessão.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);

    return mapUser(user);
  }

  Future<({UserModel user, bool needsEmailConfirmation})> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String neighborhood,
  }) async {
    final cleanName = _sanitizeFullName(fullName);
    final cleanPhone = phoneNumber.replaceAll(' ', '');

    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {
        'nome': cleanName,
        'telefone': cleanPhone,
        'bairro': neighborhood,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Não foi possível criar a conta.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);

    final userModel = UserModel(
      id: user.id,
      fullName: cleanName,
      email: user.email ?? email,
      phoneNumber: cleanPhone,
      neighborhood: neighborhood,
      token: response.session?.accessToken,
    );

    return (user: userModel, needsEmailConfirmation: response.session == null);
  }

  Future<void> signInWithGoogle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _googleRedirectUrl,
      authScreenLaunchMode: LaunchMode.inAppBrowserView,
      queryParams: {'prompt': 'select_account'},
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: _googleRedirectUrl,
    );
  }

  Future<List<String>> getNeighborhoods() async {
    // Lista fixa de bairros da Beira, não depende do backend.
    return BeiraNeighborhoods.list;
  }

  /// Emite o utilizador sempre que a sessão do Supabase muda para "signed in"
  /// fora dos métodos login()/signUp() acima — cobre o retorno do OAuth do Google.
  Stream<UserModel> get onSignedIn => _client.auth.onAuthStateChange
      .where((data) =>
          data.event == AuthChangeEvent.signedIn && data.session?.user != null)
      .map((data) => mapUser(data.session!.user));

  UserModel mapUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return UserModel(
      id: user.id,
      fullName: (metadata['nome'] ?? metadata['full_name'] ?? metadata['name'] ?? '') as String,
      email: user.email ?? '',
      phoneNumber: (metadata['telefone'] ?? '') as String,
      neighborhood: (metadata['bairro'] ?? '') as String,
      token: _client.auth.currentSession?.accessToken,
    );
  }

  String _sanitizeFullName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
