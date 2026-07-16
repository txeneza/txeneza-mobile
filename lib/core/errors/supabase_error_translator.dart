import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/auth_strings.dart';

/// Converte erros do Supabase (Auth/Postgrest/rede) em mensagens amigáveis em português.
class SupabaseErrorTranslator {
  SupabaseErrorTranslator._();

  static String translate(Object error) {
    if (error is AuthException) return _fromAuthException(error);
    if (error is PostgrestException) return _fromPostgrestException(error);

    final message = error.toString().toLowerCase();
    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network')) {
      return 'Sem ligação à internet. Verifique a sua rede e tente novamente.';
    }

    return AuthStrings.genericAuthError;
  }

  static String _fromAuthException(AuthException error) {
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();

    if (code.contains('invalid_credentials') ||
        message.contains('invalid login credentials')) {
      return AuthStrings.loginError;
    }
    if (code.contains('user_already_exists') ||
        code.contains('user_already_registered') ||
        message.contains('already registered') ||
        message.contains('already been registered')) {
      return 'Este e-mail já está associado a uma conta.';
    }
    if (code.contains('email_not_confirmed') ||
        message.contains('email not confirmed')) {
      return 'Confirme o seu e-mail antes de iniciar sessão. Verifique a sua caixa de entrada.';
    }
    if (code.contains('weak_password') || message.contains('password')) {
      return AuthStrings.passwordStrength;
    }
    if (code.contains('over_email_send_rate_limit') ||
        message.contains('rate limit')) {
      return 'Demasiadas tentativas. Aguarde um pouco antes de tentar novamente.';
    }
    if (code.contains('user_not_found')) {
      return 'Utilizador não encontrado. Registe-se primeiro.';
    }

    return error.message.isNotEmpty ? error.message : AuthStrings.genericAuthError;
  }

  static String _fromPostgrestException(PostgrestException error) {
    if (error.code == '23505') {
      return 'Este valor já está registado noutra conta.';
    }
    return AuthStrings.genericAuthError;
  }
}
