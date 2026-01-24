import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/functions/my_dilaog.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_item.dart';

class BookingMeList extends StatefulWidget {
  const BookingMeList({super.key});

  @override
  State<BookingMeList> createState() => _BookingMeListState();
}

class _BookingMeListState extends State<BookingMeList> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<BookingMeCubit, BookingMeState>(
        listener: (context, state) {
          if (state is BookingMeCanceled) {
            final refund = state.cancelModel.data.refundPolicy.refundPercentage;
            myConfirmDilaogWithPolicy(
              context,
              "تم استرداد $refund ل.س من قيمة الحجز",
              title: "تم إلغاء الحجز",
            );
          } else if (state is BookingMeErorr) {
            final message = HandelErorrMessage.bookingMe(state.message);
            
            showMySnackBar(context, message);
          }
        },
        builder: (context, state) {
          if (state is BookingMeListloading) {
            return const Center(child: LoadingWidgetSize150());
          } else if (state is BookingMeListLoaded) {
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: state.bookings.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 80.h,
                            ),
                            Image.asset(
                              'assets/images/Empty.png',
                              width: 300.w,
                              height: 300.h,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: 16.h),
                            const Text(
                              'لا توجد حجوزات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.bookings.length,
                      itemBuilder: (context, index) {
                        final booking = state.bookings[index];
                        return BookingItem(
                          booking: booking,
                          onTapDetails: () {
                            Get.toNamed(RouteName.tripDetails,
                                arguments: state.bookings[index].rideId);
                          },
                        );
                      },
                    ),
            );
          } else if (state is BookingMeErorr) {
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("خطأ حاول مجددا"),
                        SizedBox(height: 16.h),
                        IconButton(
                          onPressed: () {
                            context.read<BookingMeCubit>().getMyBooking();
                          },
                          icon: const Icon(
                            Icons.refresh,
                            color: MyColors.accent,
                            size: 50,
                          ),
                        ),
                        SizedBox(
                          height: 70.h,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final cubit = context.read<BookingMeCubit>();
    if (cubit.state is! BookingMeFinish &&
        cubit.state is! BookingMeCanceled &&
        cubit.state is! BookingMeRated) {
      cubit.getMyBooking();
    }
  });
  
  return const SizedBox.shrink();
}

        },
      ),
    );
  } 
    Future<void> _refreshData() async {
    await context.read<BookingMeCubit>().getMyBooking();
  }

}
