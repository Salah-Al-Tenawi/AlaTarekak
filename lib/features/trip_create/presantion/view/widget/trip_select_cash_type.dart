// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

class TripSelectCashType extends StatefulWidget {
  final TripFrom tripFrom;

  const TripSelectCashType({
    super.key,
    required this.tripFrom,
  });

  @override
  State<TripSelectCashType> createState() => TripSelectCashTypeTypeState();
}

class TripSelectCashTypeTypeState extends State<TripSelectCashType> {
  String _cashType = "cash";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 30.h, bottom: 5.h),
      child: ToggleButtons(
        isSelected: [_cashType == "cash", _cashType == "e-pay"],
        onPressed: (index) {
          setState(() {
            if (index == 0) {
              _cashType = "cash";
              widget.tripFrom.cashType = _cashType;
            } else {
              _cashType = "e-pay";

              widget.tripFrom.cashType = _cashType;
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
                const FaIcon(FontAwesomeIcons.moneyBillWave, size: 30),
                SizedBox(height: 5.h),
                Text("كاش", style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              children: [
                const FaIcon(FontAwesomeIcons.creditCard, size: 30),
                SizedBox(height: 5.h),
                Text("الكتروني", style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
