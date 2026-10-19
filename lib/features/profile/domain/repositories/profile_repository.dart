import '../../data/models/profile_user_model.dart';
import '../my_report.dart';
import '../profile_stats.dart';

abstract class ProfileRepository {
  /// Obtém o perfil através de estratégia SWR / First Offline.
  Future<ProfileUserModel> getProfile();

  /// Atualiza os dados do perfil com escrita otimista e sincronização remota.
  Future<void> updateProfile(ProfileUserModel profile);

  /// Leitura instantânea (0ms) do perfil a partir de Hive L1, SQLite L2 ou Auth Metadata.
  Future<ProfileUserModel?> getCachedProfile();

  /// Leitura instantânea (0ms) das estatísticas a partir de Hive L1 ou SQLite L2.
  Future<ProfileStats?> getCachedStats();

  /// Revalidação em segundo plano do perfil no Supabase.
  Future<ProfileUserModel> fetchRemoteProfile();

  /// Revalidação em segundo plano das estatísticas no Supabase.
  Future<ProfileStats> fetchRemoteStats();

  /// Contagens reais das ocorrências do próprio utilizador.
  Future<ProfileStats> getStats();

  /// Ocorrências do próprio utilizador com foto e estado (Minhas Ocorrências).
  Future<List<MyReport>> getMyReports();

  /// Apaga permanentemente a conta do utilizador e termina a sessão.
  Future<void> deleteAccount();
}
