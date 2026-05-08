import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';

class HomeNavCubit extends Cubit<int> {
  final AuthRepoIm _authRepoIm;
  HomeNavCubit(this._authRepoIm) : super(0);

  void changePage(int index) => emit(index);

  Future<void> logout(BuildContext context) async {
    final response = await _authRepoIm.logout();

    response.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
      },
      (success) {
        Get.offAllNamed(RouteName.login); 
      },
    );
  }
}
