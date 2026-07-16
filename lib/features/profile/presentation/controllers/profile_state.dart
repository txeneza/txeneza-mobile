import '../../data/models/profile_user_model.dart';
import '../../domain/profile_stats.dart';

abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ProfileUserModel profile;
  final ProfileStats stats;
  const ProfileLoaded(this.profile, this.stats);
}

class ProfileUpdating extends ProfileState {
  final ProfileUserModel currentProfile;
  final ProfileStats stats;
  const ProfileUpdating(this.currentProfile, this.stats);
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
}
