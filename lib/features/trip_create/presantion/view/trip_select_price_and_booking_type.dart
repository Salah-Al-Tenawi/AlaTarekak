import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/presantion/view/widget/trip_select_booking_type.dart';
import 'package:alatarekak/features/trip_create/presantion/view/widget/trip_select_cash_type.dart';
import 'package:alatarekak/features/trip_create/presantion/view/widget/trip_select_price.dart';
import 'package:alatarekak/features/trip_create/presantion/view/widget/trip_text_note.dart';

class TripSelectPriceAndBookingType extends StatefulWidget {
  const TripSelectPriceAndBookingType({super.key});

  @override
  State<TripSelectPriceAndBookingType> createState() =>
      _TripSelectPriceAndBookingTypeState();
}

class _TripSelectPriceAndBookingTypeState
    extends State<TripSelectPriceAndBookingType> {
  late TripFrom tripFrom;
  late String recomandedprice;

  @override
  void initState() {
    super.initState();
    tripFrom = Get.arguments as TripFrom;
    final price = calculateSuggestedPrice(tripFrom.distance);
    tripFrom.price = price;
    recomandedprice = "السعر المناسب ";
  }

  int calculateSuggestedPrice(double distanceInKm) {
    double rawPrice;
    if (distanceInKm <= 65) {
      rawPrice = distanceInKm * 500;
    } else {
      rawPrice = distanceInKm * 700;
    }

    // تقريب إلى أقرب 1000 للأسفل
    return (rawPrice ~/ 1000) * 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 80.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 20.h,
              ),
              const Text(
                " السعر للراكب الواحد بالليرة السورية",
                style: AppTextStyles.buttonLarge,
              ),
              SizedBox(
                height: 20.h,
              ),
              // Text(recomandedprice, style: font25boldgreen),
              TripSelectPrice(tripFrom: tripFrom),

              const Text(
                "اختر نوع الدفع ",
                style: AppTextStyles.accent,
              ),
              TripSelectCashType(
                tripFrom: tripFrom,
              ),
              const Divider(
                color: MyColors.textPrimary,
                endIndent: 100,
                indent: 100,
                thickness: 0.3,
              ),
              SizedBox(
                height: 10.h,
              ),
              const Text(
                "اختر نوع الحجز ",
                style: AppTextStyles.bodyMedium,
              ),
              TripSelectBookingType(tripFrom: tripFrom),
              const TripTextNote(),
              Padding(
                padding: EdgeInsetsGeometry.only(left: 160.w),
                child: MyButton(
                  onPressed: () {
                    Get.toNamed(RouteName.tripAddNumberPhone,
                        arguments: tripFrom);
                  },
                  color: MyColors.textLight,
                  width: 130.w,
                  height: 50.h,
                  borderRadius: true,
                  splashcolor: MyColors.primary,
                  child: const Text(
                    "التالي",
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
