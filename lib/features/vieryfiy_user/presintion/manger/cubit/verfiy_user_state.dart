part of 'verfiy_user_cubit.dart';

sealed class VerfiyUserState extends Equatable {
  const VerfiyUserState();

  @override
  List<Object?> get props => [];
}

final class VerfiyUserInitial extends VerfiyUserState {}

final class VerfiyLoading extends VerfiyUserState {}

final class VerfiyError extends VerfiyUserState {
  final String message;
  const VerfiyError(this.message);

  @override
  List<Object?> get props => [message];
}

final class VerfiySuccess extends VerfiyUserState {
  final VerifiyUserModle data;
  const VerfiySuccess({required this.data});

  @override
  List<Object?> get props => [data];
}

final class VerfiyUserImagesUpdated extends VerfiyUserState {
  final XFile? frontIdImage;
  final XFile? backIdImage;
  final XFile? driverLicenseImage;
  final XFile? mechanicImage;

  const VerfiyUserImagesUpdated({
    this.frontIdImage,
    this.backIdImage,
    this.driverLicenseImage,
    this.mechanicImage,
  });

  @override
  List<Object?> get props =>
      [frontIdImage, backIdImage, driverLicenseImage, mechanicImage];
}
