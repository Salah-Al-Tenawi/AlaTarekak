import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/utils/functions/boot_to_int.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/features/profiles/data/model/enum/image_mode.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/data/repo/profile_repo_im.dart';
import 'package:alatarekak/features/profiles/domain/entity/car_entity.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepoIm profileRepoIm;
  XFile? userPhoto;
  XFile? carPhoto;

  ProfileCubit(this.profileRepoIm) : super(const ProfileInitialState());

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Load
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  Future<ProfileEntity> showOtherProfile(int userid) async {
    emit(const ProfileLoadingState());
    final response = await profileRepoIm.showProfile(userid);
    return response.fold(
      (error) {
        emit(ProfileErrorState(message: error.message));
        throw Exception(error.message);
      },
      (profileEntity) {
        emit(ProfileLoadedState(
          mode: ProfileMode.otherView,
          profileEntity: profileEntity,
        ));
        return profileEntity;
      },
    );
  }

  Future<ProfileEntity> showMyProfile() async {
    final myId = myid();
    emit(const ProfileLoadingState());
    final response = await profileRepoIm.showProfile(myId!);
    return response.fold(
      (error) {
        emit(ProfileErrorState(message: error.message));
        throw Exception(error.message);
      },
      (myProfile) {
        emit(ProfileLoadedState(
          mode: ProfileMode.myView,
          profileEntity: myProfile,
        ));
        return myProfile;
      },
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Edit Mode
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  void enterEditMode() {
    final current = state;
    if (current is! ProfileLoadedState) return;
    emit(current.copyWith(
      mode: ProfileMode.myEdit,
      editProfile: current.profileEntity!.copyWith(),
      editDescription: current.profileEntity!.description,
    ));
  }

  void exitEditMode() {
    final current = state;
    if (current is! ProfileLoadedState) return;
    emit(current.copyWith(
      mode: ProfileMode.myView,
      editProfile: null,
      editDescription: null,
    ));
  }

  // ━━ تعديل الوصف ━━
  void updateDescription(String value) {
    final current = state;
    if (current is! ProfileLoadedState) return;
    emit(current.copyWith(
      editDescription: value,
      editProfile: current.editProfile?.copyWith(description: value),
    ));
  }

  // ━━ تعديل السيارة ━━
  void updateCar(CarEntity newCar) {
    final current = state;
    if (current is! ProfileLoadedState) return;
    emit(current.copyWith(
      editProfile: current.editProfile?.copyWith(car: newCar),
    ));
  }

  // ━━ تهيئة بوضع التعديل (شاشة تعديل المعلومات الشخصية) ━━
  void initWithProfile(ProfileEntity profile) {
    emit(ProfileLoadedState(
      mode: ProfileMode.myEdit,
      profileEntity: profile,
      editProfile: profile.copyWith(),
      editDescription: profile.description,
    ));
  }

  // ━━ تهيئة بوضع العرض (شاشة مركباتي) ━━
  void loadProfile(ProfileEntity profile) {
    emit(ProfileLoadedState(
      mode: ProfileMode.myView,
      profileEntity: profile,
    ));
  }

  // ━━ حفظ السيارة فقط مع الإبقاء على باقي البيانات ━━
  Future<void> saveCar(CarEntity car, XFile? carPic) async {
    final current = state;
    if (current is! ProfileLoadedState) return;

    final profile = current.profileEntity!;
    if (carPic != null) carPhoto = carPic;

    emit(ProfileLoadingState(profileEntity: profile));

    final response = await profileRepoIm.updateProfile(
      null,
      profile.description,
      car.color,
      car.seats,
      carPhoto,
      boolToInt(car.hasRadio),
      boolToInt(car.allowsSmoking),
      null, null, null, null,
      car.type,
      profile.gender,
      profile.address,
    );

    response.fold(
      (error) => emit(ProfileErrorState(
        message: error.message,
        profileEntity: profile,
      )),
      (updated) {
        carPhoto = null;
        emit(ProfileLoadedState(
          mode: ProfileMode.myView,
          profileEntity: updated,
        ));
      },
    );
  }

  // ━━ تطبيق التعديلات دفعة واحدة قبل الحفظ ━━
  void applyEdit({
    String? description,
    String? address,
    String? gender,
    CarEntity? car,
  }) {
    final current = state;
    if (current is! ProfileLoadedState) return;
    emit(current.copyWith(
      editDescription: description,
      editProfile: current.editProfile?.copyWith(
        description: description,
        address: address,
        gender: gender,
        car: car ?? current.editProfile?.car,
      ),
    ));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Save
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> saveMyProfile() async {
    final current = state;
    if (current is! ProfileLoadedState) return;

    final profile = current.editProfile;
    final car = profile?.car;

    emit(ProfileLoadingState(profileEntity: current.profileEntity));

    final response = await profileRepoIm.updateProfile(
      userPhoto,
      profile?.description,
      car?.color,
      car?.seats,
      carPhoto,
      boolToInt(car?.hasRadio),
      boolToInt(car?.allowsSmoking),
      null, null, null, null,
      car?.type,
      profile?.gender,
      profile?.address,
    );

    response.fold(
      (error) => emit(ProfileErrorState(
        message: error.message,
        profileEntity: current.profileEntity,
      )),
      (updated) => emit(ProfileLoadedState(
        mode: ProfileMode.myView,
        profileEntity: updated,
      )),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Image
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  void pickImage(XFile image, ProfileImagePicMode type) {
    final current = state;
    if (current is! ProfileLoadedState) return;

    if (type == ProfileImagePicMode.user) {
      userPhoto = image;
    } else {
      carPhoto = image;
    }

    // ━━ re-emit لتحديث الصورة ━━
    emit(current.copyWith());
  }
}