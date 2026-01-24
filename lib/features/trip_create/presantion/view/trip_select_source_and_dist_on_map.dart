import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

class TripSelectSourceAndDistOnMap extends StatefulWidget {
  const TripSelectSourceAndDistOnMap({super.key});

  @override
  State<TripSelectSourceAndDistOnMap> createState() =>
      _TripSelectSourceAndDestOnMapState();
}

class _TripSelectSourceAndDestOnMapState
    extends State<TripSelectSourceAndDistOnMap> {
  late TripFrom tripFrom;
  @override
  void initState() {
    super.initState();
    try {
      tripFrom = Get.arguments as TripFrom;
    } catch (e) {
      tripFrom = TripFrom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Padding(
        padding:
            EdgeInsetsGeometry.symmetric(horizontal: 30.h, vertical: 100.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "حدد موقع انطلاق و وجهة الرحلة و المسار على الخريطة",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: MyColors.primaryText),
            ),
            SizedBox(
              height: 30.h,
            ),
            MyButton(
              onPressed: () {
                Get.toNamed(RouteName.pushRideMap, arguments: tripFrom);
              },
              child: const FaIcon(FontAwesomeIcons.mapLocationDot,
                  size: 60, color: MyColors.accent),
            ),
          ],
        ),
      )),
    );
  }
}
