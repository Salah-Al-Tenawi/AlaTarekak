// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

class TripSelectBookingType extends StatefulWidget {
  final TripFrom tripFrom;

  const TripSelectBookingType({
    super.key,
    required this.tripFrom,
  });

  @override
  State<TripSelectBookingType> createState() => _TripSelectBookingTypeState();
}

class _TripSelectBookingTypeState extends State<TripSelectBookingType> {
  String _bookeingType = "direct";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 30.h, bottom: 40),
      child: ToggleButtons(
        isSelected: [_bookeingType == "direct", _bookeingType == "request"],
        onPressed: (index) {
          setState(() {
            if (index == 0) {
              _bookeingType = "direct";
              widget.tripFrom.bookingType = _bookeingType;
            } else {
              _bookeingType = "request";

              widget.tripFrom.bookingType = _bookeingType;
            }
          });
        },
        borderColor: Colors.transparent,
        selectedBorderColor: Colors.transparent,
        fillColor: Colors.transparent,
        color: Colors.grey,
        selectedColor: MyColors.primary,
        borderRadius: BorderRadius.circular(10),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              children: [
                const FaIcon(FontAwesomeIcons.userGroup, size: 30),
                SizedBox(height: 5.h),
                Text("أي شخص", style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              children: [
                const FaIcon(FontAwesomeIcons.userCheck, size: 30),
                SizedBox(height: 5.h),
                Text("بعد الموافقة", style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
