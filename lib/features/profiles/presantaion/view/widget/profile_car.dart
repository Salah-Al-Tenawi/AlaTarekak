import 'package:flutter/material.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/car_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/Profile_car_info_edit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_car_info_view.dart';

class ProfileCar extends StatelessWidget {
  final CarEntity? car;
  final CarEntity? carWitheidt;
  final ProfileMode mode;
  final ValueChanged<CarEntity>? onCarChanged; // new

  const ProfileCar({
    super.key,
    required this.car,
    required this.carWitheidt,
    required this.mode,
    this.onCarChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case ProfileMode.otherView:
      case ProfileMode.myView:
        return ProfileCarInfoView(car: car);
      case ProfileMode.myEdit:
        return ProfileCarInfoEdit(
          carWithEdit: carWitheidt,
          onCarChanged: onCarChanged,
        );
    }
  }
}
