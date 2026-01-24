import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

import 'package:alatarekak/features/trip_create/presantion/view/widget/trip_did_you_back_text_and_buttons.dart';

class TripDidYouBack extends StatefulWidget {
  const TripDidYouBack({super.key});

  @override
  State<TripDidYouBack> createState() => _TripDidYouBackState();
}

class _TripDidYouBackState extends State<TripDidYouBack> {
  late final TripFrom tripFrom;
  @override
  void initState() {
    super.initState();
    tripFrom = Get.arguments as TripFrom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.only(top: 130.h),
            child: Column(
              children: [
                const Text(
                  "تم إنشاء الرحلة بنجاح ",
                  style: font18boldramdi,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 30.h, bottom: 100.h),
                  child: const FaIcon(
                    FontAwesomeIcons.circleCheck,
                    size: 150,
                    color: MyColors.accent,
                  ),
                ),
                tripFrom.reverseTripRoute == false
                    ? TripDidYouBackTextAndButtons(tripFrom: tripFrom)
                    : MyButton(
                        onPressed: () {
                          Get.offAllNamed(RouteName.home);
                        },
                        color: MyColors.primary,
                        splashcolor: MyColors.primaryText,
                        width: 260.w,
                        height: 60,
                        borderRadius: true,
                        child: const FaIcon(
                          FontAwesomeIcons.carSide,
                          color: Colors.orange,
                          size: 35,
                        ).animate().fadeIn(duration: 500.ms).move(
                            begin: const Offset(-50, 0), end: Offset.zero))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
