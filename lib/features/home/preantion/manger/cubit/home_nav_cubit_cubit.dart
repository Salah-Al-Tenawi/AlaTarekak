import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/chat_socket_service.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

class HomeNavCubit extends SafeCubit<int> {
  final AuthRepoIm _authRepoIm;
  HomeNavCubit(this._authRepoIm) : super(2);

  void changePage(int index) => emit(index);

  Future<void> logout(BuildContext context) async {
    final response = await _authRepoIm.logout();

    response.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(HandelErorrMessage.logout(error.message)),
            backgroundColor: MyColors.error,
          ),
        );
      },
      (success) async {
        await ChatSocketService.instance.disconnect();
        // كاش الميزات خاص بالمستخدم — يُمسح عند الخروج
        await HiveBoxes.cacheBox.clear();
        Get.offAllNamed(RouteName.login);
      },
    );
  }
}
