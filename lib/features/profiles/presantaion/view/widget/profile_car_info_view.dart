import 'package:flutter/material.dart';
import 'package:alatarekak/features/profiles/domain/entity/car_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/car_color_tile.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/car_image_view_tile.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/car_radio_info_tile.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/car_seats_tile.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/car_smoking_info_tile.dart';

class ProfileCarInfoView extends StatelessWidget {
  final CarEntity? car;

  const ProfileCarInfoView({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    if (car == null) {
      return const Text("لا توجد معلومات عن السيارة.");
    }

    return Column(
      children: [
        const Divider(endIndent: 100, indent: 100),
        CarImageViewerTile(car: car!),
        Row(
          children: [
            Expanded(child: CarColorTile(color: car!.color)),
            Expanded(child: CarSeatsTile(seats: car!.seats)),
          ],
        ),
        Row(
          children: [
            Expanded(child: CarRadioInfoTile(hasRadio: car!.hasRadio)),
            Expanded(
                child: CarSmokingInfoTile(allowsSmoking: car!.allowsSmoking)),
          ],
        ),
      ],
    );
  }
}
