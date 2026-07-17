import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/beira_neighborhoods.dart';

/// Valor gravado pelo trigger `handle_new_user` quando a conta é criada sem
/// metadado de bairro — o caso típico do login com Google, que não pede bairro.
const String kBairroPorDefinir = 'Não definido';

/// Decide se o utilizador tem de completar o perfil antes de entrar na app.
class ProfileCompletionService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Um bairro só é válido se constar da lista real de bairros da Beira.
  /// Assim cobrimos tanto o 'Não definido' do trigger como qualquer valor
  /// antigo/inválido que tenha ficado na base de dados.
  static bool isBairroValido(String? bairro) =>
      bairro != null && BeiraNeighborhoods.list.contains(bairro);

  /// True quando há sessão activa mas o perfil ainda não tem um bairro real.
  /// Em caso de erro de rede devolve false: mais vale deixar entrar do que
  /// prender o utilizador num ecrã de perfil por causa de uma falha temporária.
  Future<bool> needsCompletion() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final row = await _client
          .from('utilizador')
          .select('bairro')
          .eq('id_utilizador', user.id)
          .maybeSingle();

      // Sem linha ainda (trigger em atraso) conta como perfil incompleto.
      if (row == null) return true;

      return !isBairroValido(row['bairro'] as String?);
    } catch (_) {
      return false;
    }
  }

  Future<void> completeProfile({
    required String bairro,
    String? telefone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sessão expirada. Inicie sessão novamente.');
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final name = (metadata['nome'] ??
        metadata['full_name'] ??
        metadata['name'] ??
        user.email?.split('@').first ??
        'Utilizador') as String;

    await _client.from('utilizador').update({
      'nome': name,
      'email': user.email ?? '',
      'bairro': bairro,
      if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
    }).eq('id_utilizador', user.id);
  }
}
