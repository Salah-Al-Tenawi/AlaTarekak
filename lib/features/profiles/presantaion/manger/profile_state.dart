part of 'profile_cubit.dart';

sealed class ProfileState extends Equatable {
  final ProfileEntity? profileEntity;
  const ProfileState({this.profileEntity});
  @override
  List<Object?> get props => [profileEntity];
}

final class ProfileInitialState extends ProfileState {
  const ProfileInitialState() : super(profileEntity: null);
}

final class ProfileLoadingState extends ProfileState {
  const ProfileLoadingState({super.profileEntity});
  @override
  List<Object?> get props => [profileEntity];
}

final class ProfileErrorState extends ProfileState {
  final String message;
  const ProfileErrorState({required this.message, super.profileEntity});
  @override
  List<Object?> get props => [message, profileEntity];
}

final class ProfileLoadedState extends ProfileState {
  final ProfileMode mode;

  // ━━ edit data — بدل setState ━━
  final ProfileEntity? editProfile;
  final String? editDescription;

  const ProfileLoadedState({
    required this.mode,
    required ProfileEntity profileEntity,
    this.editProfile,
    this.editDescription,
  }) : super(profileEntity: profileEntity);

  ProfileLoadedState copyWith({
    ProfileMode? mode,
    ProfileEntity? profileEntity,
    ProfileEntity? editProfile,
    String? editDescription,
  }) {
    return ProfileLoadedState(
      mode: mode ?? this.mode,
      profileEntity: profileEntity ?? this.profileEntity!,
      editProfile: editProfile ?? this.editProfile,
      editDescription: editDescription ?? this.editDescription,
    );
  }

  @override
  List<Object?> get props => [mode, profileEntity, editProfile, editDescription];
}