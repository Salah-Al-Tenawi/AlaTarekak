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
  final ProfileEntity? previousProfile;
  
  const ProfileLoadingState({this.previousProfile}) 
    : super(profileEntity: previousProfile);

  @override
  List<Object?> get props => [previousProfile];
}

final class ProfileErrorState extends ProfileState {
  final String message;
  final ProfileEntity? lastValidProfile;

  const ProfileErrorState({
    required this.message,
    this.lastValidProfile,
  }) : super(profileEntity: lastValidProfile);

  @override
  List<Object?> get props => [message, lastValidProfile];
}

final class ProfileLoadedState extends ProfileState {
  final ProfileMode mode;

  const ProfileLoadedState({
    required this.mode,
    required ProfileEntity profileEntity,
  }) : super(profileEntity: profileEntity);

  @override
  List<Object?> get props => [mode, profileEntity];
} 




