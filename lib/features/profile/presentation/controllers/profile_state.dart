import '../../data/models/profile_user_model.dart';

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
  const ProfileLoaded(this.profile);
}

class ProfileUpdating extends ProfileState {
  final ProfileUserModel currentProfile;
  const ProfileUpdating(this.currentProfile);
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
}
