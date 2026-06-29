import '../../data/models/profile_user_model.dart';

abstract class ProfileRepository {
  Future<ProfileUserModel> getProfile();
  Future<void> updateProfile(ProfileUserModel profile);
}
