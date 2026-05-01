import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/date_picker.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/trip_search/presantion/manger/cubit/search_cubit.dart';
import 'package:alatarekak/features/trip_search/presantion/view/widget/show_dialog_empty_search.dart';

class TripSearch extends StatefulWidget {
  const TripSearch({super.key});

  @override
  State<TripSearch> createState() => _TripSearchState();
}

class _TripSearchState extends State<TripSearch> {
  final TextEditingController seatsController = TextEditingController();
  String? sourceLat;
  String? sourceLng;
  String? destinationLat;
  String? destinationLng;
  String? sourceAddress;
  String? destinationAddress;
  String? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SearchCubit, SearchState>(
        listener: (context, state) {
          if (state is SearchErorr) {
            if (state.error.contains(
                "You must be verified as a passenger to book rides.")) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("يحب عليك توثيق هويتك اولا ")),
              );

              Get.toNamed(RouteName.verfiyUser, arguments: "passanger");
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("حدثت مشكلة ما ")),
              );
            }
          } else if (state is SearchSucces) {
            if (state.trips.isEmpty) {
              showNoTripsDialog(context);
            } else {
              Get.toNamed(RouteName.tripSearchList, arguments: state.trips);
            }
          }
        },
        child: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 10.w),
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16.r),
    side: BorderSide(color: Colors.grey.shade200, width: 1),
  ),
  elevation: 6,
  color: Colors.white,
  
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            _modernLocationPicker(),
            SizedBox(height: 30.h),
            _modernDateTimeCard(),
            SizedBox(height: 40.h),
            _searchButtonWithState(),
            SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
        )
      ),
    );
  }

  Widget _modernLocationPicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Source
          ListTile(
            leading: Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: MyColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.my_location,
                size: 20.sp,
                color: MyColors.primary,
              ),
            ),
            title: Text(
              sourceAddress ?? "اختر مكان الانطلاق",
              style: TextStyle(
                fontSize: 16.sp,
                color: sourceAddress != null
                    ? MyColors.textPrimary
                    : MyColors.textSecondary,
                fontWeight:
                    sourceAddress != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 18.sp,
              color: MyColors.textSecondary,
            ),
            onTap: () async {
              final result =
                  await Get.toNamed(RouteName.pickLocation, arguments: {
                "type": "source",
              });
              if (result != null) {
                setState(() {
                  sourceAddress = result["placeName"];
                  sourceLat = result["lat"];
                  sourceLng = result["lng"];
                });
              }
            },
          ),
          Divider(
            height: 1.h,
            indent: 70.w,
            endIndent: 16.w,
            color: MyColors.background,
          ),
          // Destination
          ListTile(
            leading: Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: MyColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                size: 20.sp,
                color: MyColors.accent,
              ),
            ),
            title: Text(
              destinationAddress ?? "اختر الوجهة",
              style: TextStyle(
                fontSize: 16.sp,
                color: destinationAddress != null
                    ? MyColors.textPrimary
                    : MyColors.textSecondary,
                fontWeight: destinationAddress != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 18.sp,
              color: MyColors.textSecondary,
            ),
            onTap: () async {
              final result =
                  await Get.toNamed(RouteName.pickLocation, arguments: {
                "type": "destination",
              });
              if (result != null) {
                setState(() {
                  destinationAddress = result["placeName"];
                  destinationLat = result["lat"];
                  destinationLng = result["lng"];
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _modernDateTimeCard() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final pickedDate =
                  await DatePickerService.showCustomDateTimePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedDate != null) {
                setState(() {
                  selectedDate = DateFormat('dd MMM yyyy').format(pickedDate);
                });
              }
            },
            child: Container(
              height: 80.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20.sp,
                    color: MyColors.primary,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      selectedDate ?? "اختر التاريخ",
                      style: TextStyle(
                        color: selectedDate != null
                            ? MyColors.textPrimary
                            : MyColors.textSecondary,
                        fontSize: 14.sp,
                        fontWeight: selectedDate != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Container(
            height: 80.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_seat,
                  size: 20.sp,
                  color: MyColors.primary,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: seatsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "عدد المقاعد",
                      hintStyle: TextStyle(
                        color: MyColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                    style: TextStyle(
                      color: MyColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchButtonWithState() {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading) {
          return const Center(
            child: LoadingWidgetSize150(),
          );
        }
        return _modernSearchButton();
      },
    );
  }

  Widget _modernSearchButton() {
    return Center(
      child: SizedBox(
        height: 75.h,
        width: 300.w, 
        child: ElevatedButton.icon(
          onPressed: _validateAndSearch,
          icon: const Icon(
            Icons.search,
            color: Colors.white,
            size: 25,
          ),
          label: Text(
            "ابحث عن رحلة",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: MyColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40.r),
            ),
            elevation: 0, // تصميم هادئ
            padding: EdgeInsets.symmetric(horizontal: 12.w),
          ),
        ),
      ),
    );
  }

  void _validateAndSearch() {
    if (sourceLat == null || sourceLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء اختيار مكان الانطلاق")),
      );
      return;
    }

    if (destinationLat == null || destinationLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء اختيار الوجهة")),
      );
      return;
    }

    if (selectedDate == null || selectedDate!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء اختيار تاريخ الرحلة")),
      );
      return;
    }

    final seats = int.tryParse(seatsController.text) ?? 0;
    if (seats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("الرجاء إدخال عدد مقاعد صحيح")),
      );
      return;
    }

    context.read<SearchCubit>().search(
          sourceLat!.toString(),
          sourceLng!.toString(),
          destinationLat!.toString(),
          destinationLng!.toString(),
          selectedDate!,
          seats,
        );
  }
}
