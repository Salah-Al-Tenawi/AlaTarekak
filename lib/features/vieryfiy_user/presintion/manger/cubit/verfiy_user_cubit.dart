import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/features/vieryfiy_user/data/model/verifiy_user_modle.dart';
import 'package:alatarekak/features/vieryfiy_user/data/repo/verfiy_user_repo.dart';
import 'package:equatable/equatable.dart';

part 'verfiy_user_state.dart';

class VerifyUserCubit extends Cubit<VerfiyUserState> {
  final ImagePicker _picker = ImagePicker();
  final VerfiYUserRepo verfiYUserRepo;

  XFile? frontIdImage;
  XFile? backIdImage;
  XFile? driverLicenseImage;
  XFile? mechanicImage;

  VerifyUserCubit({required this.verfiYUserRepo})
      : super(VerfiyUserInitial());

  Future<void> pickFrontId() async =>
      await _pickImage((file) => frontIdImage = file);

  Future<void> pickBackId() async =>
      await _pickImage((file) => backIdImage = file);

  Future<void> pickDriverLicense() async =>
      await _pickImage((file) => driverLicenseImage = file);

  Future<void> pickMechanic() async =>
      await _pickImage((file) => mechanicImage = file);

  Future<void> _pickImage(Function(XFile) assign) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      assign(picked);
      emit(VerfiyUserImagesUpdated(
        frontIdImage: frontIdImage,
        backIdImage: backIdImage,
        driverLicenseImage: driverLicenseImage,
        mechanicImage: mechanicImage,
      ));
    }
  }

  bool allImagesSelected(bool isDriver) {
    if (isDriver) {
      return frontIdImage != null &&
          backIdImage != null &&
          driverLicenseImage != null &&
          mechanicImage != null;
    }
    return frontIdImage != null && backIdImage != null;
  }

  Future<void> submitDriverImages() async {
    emit(VerfiyLoading());

    final response = await verfiYUserRepo.verfiyDriver(
      frontIdImage,
      backIdImage,
      driverLicenseImage,
      mechanicImage,
    );
    response.fold((erorr) {
      emit(VerfiyError(erorr.message));
    }, (succses) {
      emit(VerfiySuccess(data: succses));
    });
  }

  Future<void> submitPassengerImages() async {
    emit(VerfiyLoading());

    final response = await verfiYUserRepo.verfiyPassanger(
      frontIdImage,
      backIdImage,
    );
    response.fold((erorr) {
      emit(VerfiyError(erorr.message));
    }, (success) {
      emit(VerfiySuccess(data: success));
    });
  }
}
