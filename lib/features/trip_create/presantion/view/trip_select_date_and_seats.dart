import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:intl/intl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/date_picker.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/presantion/view/widget/trip_date_show.dart';
import 'package:alatarekak/features/trip_create/presantion/view/widget/trip_select_seats.dart';

class TripSelectDateAndSeats extends StatefulWidget {
  const TripSelectDateAndSeats({super.key});

  @override
  State<TripSelectDateAndSeats> createState() => TripSelectAndSeatsState();
}

class TripSelectAndSeatsState extends State<TripSelectDateAndSeats> {
  late TripFrom tripFrom;
  String? formattedDate;
  String? formattedTime;

  @override
  void initState() {
    super.initState();
    tripFrom = Get.arguments as TripFrom;
  }

  Future<void> _selectDatetime(BuildContext context) async {
    DateTime? sel =
        await DatePickerService.showCustomDateTimePicker(context: context);
    if (sel != null) {
      final String fullDate = DateFormat('yyyy-MM-dd hh:mm a').format(sel);

      List<String> dateParts = fullDate.split(' ');
      formattedDate = dateParts[0];
      formattedTime = '${dateParts[1]} ${dateParts[2]}';
      tripFrom.date = fullDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 30.h, vertical: 100.w),
        child: Column(
          children: [
            const Text(
              "حدد موعد الرحلة",
              style: font15BoldRamadi,
            ),
            SizedBox(
              height: 20.h,
            ),
            MyButton(
              onPressed: () async {
                await _selectDatetime(context);
                setState(() {});
              },
              width: 100.w,
              height: 30.h,
              child: const FaIcon(FontAwesomeIcons.calendarDays,
                  size: 60, color: MyColors.primary),
            ),
            TripDateShow(day: formattedDate, hour: formattedTime),
            const Divider(
              color: MyColors.primaryText,
              endIndent: 50,
              indent: 50,
              thickness: 0.3,
            ),
            const Text(
              "حدد عدد الكراسي المتاحة",
              style: font15BoldRamadi,
            ),
            TripSelectSeats(
              tripFrom: tripFrom,
            ),
            Padding(
              padding: EdgeInsetsGeometry.only(left: 160.w),
              child: MyButton(
                onPressed: () {
                  Get.toNamed(RouteName.tripSelectPriceAndBookingType,
                      arguments: tripFrom);
                },
                color: MyColors.primary,
                width: 130.w,
                height: 50.h,
                borderRadius: true,
                splashcolor: MyColors.primary,
                child: const Text(
                  "التالي",
                  style: font13boldwhite,
                ),
              ),
            )
          ],
        ),
      )),
    );
  }
}
