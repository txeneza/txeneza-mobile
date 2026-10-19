import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço utilitário que analisa o perfil e fornecedores de autenticação
/// da sessão ativa no Supabase Auth.
class AuthProviderResolver {
  const AuthProviderResolver._();

  /// Identifica se o utilizador autenticado realizou o registo ou início de sessão
  /// através do fornecedor Google.
  static bool isGoogleUser([User? user]) {
    final currentUser = user ?? Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return false;

    final appMetadata = currentUser.appMetadata;
    final String? provider = appMetadata['provider'] as String?;
    final List<dynamic>? providers = appMetadata['providers'] as List<dynamic>?;

    final bool inAppMetadata = provider == 'google' ||
        (providers != null && providers.map((e) => e.toString()).contains('google'));

    final identities = currentUser.identities ?? [];
    final bool inIdentities = identities.any((i) => i.provider == 'google');

    return inAppMetadata || inIdentities;
  }

  /// Identifica se o utilizador possui credenciais de palavra-passe ativas
  /// (fornecedor 'email' nas identidades ou metadados).
  static bool hasPasswordAuth([User? user]) {
    final currentUser = user ?? Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return false;

    final appMetadata = currentUser.appMetadata;
    final String? provider = appMetadata['provider'] as String?;
    final List<dynamic>? providers = appMetadata['providers'] as List<dynamic>?;

    final bool inAppMetadata = provider == 'email' ||
        (providers != null && providers.map((e) => e.toString()).contains('email'));

    final identities = currentUser.identities ?? [];
    final bool inIdentities = identities.any((i) => i.provider == 'email');

    return inAppMetadata || inIdentities;
  }

  /// Determina se a conta foi criada exclusivamente com Google e ainda
  /// não possui nenhuma palavra-passe local configurada.
  static bool isGoogleOnly([User? user]) {
    final currentUser = user ?? Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return false;
    return isGoogleUser(currentUser) && !hasPasswordAuth(currentUser);
  }
}
