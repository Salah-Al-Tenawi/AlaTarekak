import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/hive_services.dart';

class SplashCubit extends Cubit<void> {

  SplashCubit() : super(null);

  Future<void> initApp() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = await HiveBoxes.authBox.get(HiveKeys.user);

    
    if (user != null) {
      Get.offAllNamed(RouteName.home);
    } else {
      Get.offAllNamed(RouteName.onboarding);
    }
  }
  
}
