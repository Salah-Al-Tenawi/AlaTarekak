import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';

class SplashCubit extends Cubit<void> {
  final AuthRepoIm authRepoIm;

  SplashCubit(this.authRepoIm) : super(null);

  Future<void> initApp() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = HiveBoxes.authBox.get(HiveKeys.user);

      if (user == null) {
        Get.offAllNamed(RouteName.onboarding);
        return;
      }

      final result = await authRepoIm.refreshToken(user.refreshToken);

      result.fold(
        (_) {
          // token منتهي الصلاحية — امسح البيانات وانتقل للـ onboarding
          HiveBoxes.authBox.clear();
          Get.offAllNamed(RouteName.onboarding);
        },
        (_) => Get.offAllNamed(RouteName.home),
      );
    } catch (_) {
      Get.offAllNamed(RouteName.onboarding);
    }
  }
}
