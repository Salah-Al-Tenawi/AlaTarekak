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
  String? username;

  ProfileCubit(this.profileRepoIm) : super(const ProfileInitialState());

  Future<ProfileEntity> showOtherProfile(int userid) async {
    emit(const ProfileLoadingState());
    final response = await profileRepoIm.showProfile(userid);
    print("response-=========================");
    print(response);
    print("response-=========================");

    return response.fold(
      (error) {
        emit(ProfileErrorState(message: error.message));
        throw Exception(error.message);
      },
      (profileEntity) {
        emit(ProfileLoadedState(
            mode: ProfileMode.otherView, profileEntity: profileEntity));

        return profileEntity;
      },
    );
  }

  Future<ProfileEntity> showMyProfile() async {
    int? myId = myid();
    emit(const ProfileLoadingState());
    final response = await profileRepoIm.showProfile(myId!);

    return response.fold(
      (error) {
        emit(ProfileErrorState(message: error.message));
        throw Exception(error.message);
      },
      (myProfile) {
        emit(ProfileLoadedState(
            mode: ProfileMode.myView, profileEntity: myProfile));

        return myProfile;
      },
    );
  }

  emiteditMyProfile() {
    final current = state;
    if (current is ProfileLoadedState) {
      emit(ProfileLoadedState(
          mode: ProfileMode.myEdit, profileEntity: current.profileEntity!));
    }
  }

  void saveMyProfile(ProfileEntity? newProfile) async {
    final current = state;
    if (current is! ProfileLoadedState) return;
    emit(const ProfileLoadingState());
    ProfileEntity? profile = newProfile;
    CarEntity? car = profile?.car;
    final response = await profileRepoIm.updateProfile(
        userPhoto,
        profile?.description,
        car?.color,
        car?.seats,
        carPhoto,
        boolToInt(car?.hasRadio),
        boolToInt(car?.allowsSmoking),
        null,
        null,
        null,
        null,
        car?.type,
        null,
        profile?.address);
    response.fold((erorr) {
      emit(ProfileErrorState(message: erorr.message));
    }, (profileEntity) {
      emit(ProfileLoadedState(
          mode: ProfileMode.myView, profileEntity: profileEntity));
    });
  }

  void pickImage(XFile image, ProfileImagePicMode type) {
    switch (type) {
      case ProfileImagePicMode.user:
        userPhoto = image;
        break;
      case ProfileImagePicMode.car:
        carPhoto = image;
        break;
    }

    final current = state;
    if (current is ProfileLoadedState) {
      emit(const ProfileLoadingState());
      emit(ProfileLoadedState(
        mode: current.mode,
        profileEntity: current.profileEntity!,
      ));
    }
  }
}
