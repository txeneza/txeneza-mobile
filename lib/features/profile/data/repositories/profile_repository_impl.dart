import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/supabase_error_translator.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/profile_user_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<ProfileUserModel> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Nenhuma sessão ativa encontrada. Faça login novamente.');
    }

    try {
      final row = await _client
          .from('utilizador')
          .select()
          .eq('id_utilizador', user.id)
          .single();
      return ProfileUserModel.fromJson(row);
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
  }

  @override
  Future<void> updateProfile(ProfileUserModel profile) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Nenhuma sessão ativa encontrada. Faça login novamente.');
    }

    try {
      await _client
          .from('utilizador')
          .update(profile.toUpdateJson())
          .eq('id_utilizador', user.id);
    } catch (e) {
      throw Exception(SupabaseErrorTranslator.translate(e));
    }
  }
}
