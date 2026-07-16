import '../../data/models/profile_user_model.dart';
import '../my_report.dart';
import '../profile_stats.dart';

abstract class ProfileRepository {
  Future<ProfileUserModel> getProfile();
  Future<void> updateProfile(ProfileUserModel profile);

  /// Contagens reais das ocorrências do próprio utilizador.
  Future<ProfileStats> getStats();

  /// Ocorrências do próprio utilizador com foto e estado (Minhas Ocorrências).
  Future<List<MyReport>> getMyReports();

  /// Apaga permanentemente a conta do utilizador e termina a sessão.
  Future<void> deleteAccount();
}
