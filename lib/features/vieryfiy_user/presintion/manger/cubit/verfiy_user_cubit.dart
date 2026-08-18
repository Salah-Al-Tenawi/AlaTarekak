import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/vieryfiy_user/data/model/verifiy_user_modle.dart';
import 'package:alatarekak/features/vieryfiy_user/data/repo/verfiy_user_repo.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'verfiy_user_state.dart';

class VerifyUserCubit extends SafeCubit<VerfiyUserState> {
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

  /// فتح المعرض واختيار صورة.
  ///
  /// `pickImage` يرمي `PlatformException` حين يرفض المستخدم إذن الصور
  /// (أندرويد 13 فأحدث) أو حين يفشل المعرض — وكان الاستثناء يخرج من هنا
  /// غير ملتقَط فتنهار الشاشة أثناء رفع المستندات.
  Future<void> _pickImage(Function(XFile) assign) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      if (isClosed) return;
      emit(const VerfiyError(
          'تعذّر فتح معرض الصور — تأكّد من السماح للتطبيق بالوصول إلى الصور'));
      return;
    }

    if (picked == null || isClosed) return; // ألغى الاختيار
    assign(picked);
    emit(VerfiyUserImagesUpdated(
      frontIdImage: frontIdImage,
      backIdImage: backIdImage,
      driverLicenseImage: driverLicenseImage,
      mechanicImage: mechanicImage,
    ));
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
      emit(VerfiyError(HandelErorrMessage.verfiyDriver(erorr.message)));
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
      emit(VerfiyError(HandelErorrMessage.verfiyPassanger(erorr.message)));
    }, (success) {
      emit(VerfiySuccess(data: success));
    });
  }
}
