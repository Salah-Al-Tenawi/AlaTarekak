// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

class TripDidYouBackTextAndButtons extends StatefulWidget {
  final TripFrom tripFrom;
  const TripDidYouBackTextAndButtons({
    super.key,
    required this.tripFrom,
  });

  @override
  State<TripDidYouBackTextAndButtons> createState() =>
      _TripDidYouBackTextAndButtonsState();
}

class _TripDidYouBackTextAndButtonsState
    extends State<TripDidYouBackTextAndButtons> {
  void _swapSourceAndDestination() {
    final statrLat = widget.tripFrom.startLat;
    final statrLng = widget.tripFrom.startLng;
    final endLat = widget.tripFrom.endLat;
    final endLng = widget.tripFrom.endLng;

    widget.tripFrom.startLat = endLat;
    widget.tripFrom.startLng = endLng;

    widget.tripFrom.endLat = statrLat;
    widget.tripFrom.endLng = statrLng;

    widget.tripFrom.reverseTripRoute = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text(
        " هل ترغب بإنشاء رحلة للعودة  ",
        style: font14boldblueblack,
      ),
      SizedBox(
        height: 60.h,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          MyButton(
            onPressed: () {
              _swapSourceAndDestination();
              Get.toNamed(RouteName.tripSelectDateAndSeats,
                  arguments: widget.tripFrom);
            },
            color: MyColors.primary,
            width: 120.w,
            height: 50,
            borderRadius: true,
            child: const Text(
              "نعم ",
              style: font12boldgray,
            ),
          ),
          MyButton(
            onPressed: () {
              Get.offAllNamed(RouteName.home);
            },
            color: MyColors.accent,
            width: 120.w,
            height: 50,
            borderRadius: true,
            child: const Text(
              "لا شكراً ",
              style: font12boldsky,
            ),
          ),
        ],
      )
    ]);
  }
}
