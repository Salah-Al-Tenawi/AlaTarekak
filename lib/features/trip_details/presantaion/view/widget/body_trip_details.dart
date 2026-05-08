import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/core/utils/widgets/custom_text_form.dart';
import 'package:alatarekak/features/trip_create/data/model/booking_model.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_details/data/model/trip_details_mode.dart';
import 'package:alatarekak/features/trip_details/presantaion/manger/cubit/tripdetails_cubit.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/widget/status_trip.dart';

class BodyTripDetails extends StatefulWidget {
  final TripModel trip;
  final TripDetailsMode mode;
  const BodyTripDetails({super.key, required this.trip, required this.mode});

  @override
  State<BodyTripDetails> createState() => _BodyTripDetailsState();
}

class _BodyTripDetailsState extends State<BodyTripDetails> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      width: double.infinity,
      child: Column(children: [
        _buildStatusChip(),

        SizedBox(
          height: 10.h,
        ),
        _buildDriverInfo(),
        // SizedBox(height: 5.h),
        _buildContactAndCreatedAtRow(),
        _buildTripRoute(),
        SizedBox(height: 17.h),
        _buildDistanceDurationRow(),

        _buildDepartureBadge(),
        
        _buildSeatsInfo(),

        SizedBox(height: 17.h),
        _buildPaymentMethodWidget(),

        SizedBox(height: 5.h),
        _buildBookingTypeWidget(),
        SizedBox(height: 20.h),
        widget.mode == TripDetailsMode.otherView
            ? _buildConditionalBookingButton(context)
            : showBookingButton(),
        widget.mode == TripDetailsMode.myView
            ? _buildFinishRideButton()
            : const SizedBox()
      ]),
    );
  }

  Widget _buildFinishRideButton() {
    final departure = widget.trip.departure;
    final now = DateTime.now();
    final difference = departure.difference(now);

    // نتحقق إذا كانت الحالة active أو full
    if (widget.trip.status == 'active' || widget.trip.status == 'full') {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 10.h),
        child: ElevatedButton(
          onPressed: () {
            if (widget.trip.booking.isEmpty) {
              context.read<TripDetailsCubit>().finishRide(widget.trip.id);
            } else if (difference.inSeconds <= 0) {
              context
                  .read<TripDetailsCubit>()
                  .finishAndConfirmRide(widget.trip.id);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MyColors.accent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 4,
            shadowColor: MyColors.accent.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag_rounded,
                size: 24.w,
                color: Colors.white,
              ),
              SizedBox(width: 12.w),
              difference.inSeconds <= 0
                  ? Text(
                      "إنهاء الرحلة",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      "لم يحن وقت الرحلة",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    )
            ],
          ),
        ),
      );
    }

    return const SizedBox();
  }

  ElevatedButton showBookingButton() {
    return ElevatedButton(
      onPressed: () {
        Get.toNamed(RouteName.bookingUserInTrip,
            arguments: widget.trip.booking);
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 6,
        backgroundColor: MyColors.primary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            color: Colors.white,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Text(
            "عرض الحجوزات - ${widget.trip.seatsBooked} محجوزة",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final statusInfo = getStatusInfo(widget.trip.status);

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: statusInfo.color,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: statusInfo.color.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          statusInfo.text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfo() {
    return Row(
      children: [
        InkWell(
          onTap: () {
            context
                .read<TripDetailsCubit>()
                .fetchProfile(widget.trip.driver.id);
          },
          child: CircleAvatar(
            radius: 30.w,
            backgroundImage: (widget.trip.driver.avatar == null ||
                    widget.trip.driver.avatar!.isEmpty)
                ? const AssetImage(ImagesUrl.profileImage)
                : NetworkImage(widget.trip.driver.avatar!) as ImageProvider,
          ),
        ),
        SizedBox(width: 8.w),
        Text(widget.trip.driver.name),
        SizedBox(width: 15.w),
        RatingBarIndicator(
          rating: widget.trip.driver.rating.toDouble(),
          itemBuilder: (context, index) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          itemCount: 5,
          itemSize: 20.0,
          direction: Axis.horizontal,
        ),
      ],
    );
  }

  Widget _buildPickupCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.my_location, color: MyColors.textSecondary, size: 24.w),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "موقع الانطلاق",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: MyColors.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    widget.trip.pickup.address,
                    style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on, color: MyColors.textSecondary, size: 24.w),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "الوجهة",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: MyColors.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    widget.trip.destination.address,
                    style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripRoute() {
    return InkWell(
      onTap: () {
        Get.toNamed(
          RouteName.routeMapView,
          arguments: {
            'startLat': widget.trip.pickup.coordinates.lat,
            'startLng': widget.trip.pickup.coordinates.lng,
            'endLat': widget.trip.destination.coordinates.lat,
            'endLng': widget.trip.destination.coordinates.lng,
            'routeIndex': widget.trip.chosenRouteIndex,
          },
        );
      },
      child: Column(
        children: [
          _buildPickupCard(),
          SizedBox(height: 8.h),
          FaIcon(
            FontAwesomeIcons.route,
            size: 25.w,
            color: MyColors.accent,
          ),
          SizedBox(height: 8.h),
          _buildDestinationCard(),
        ],
      ),
    );
  }

  Widget _buildDepartureBadge() {
    final departure = widget.trip.departure;
    final now = DateTime.now();
    final difference = departure.difference(now);

    String timeLeft;
    if (difference.inSeconds <= 0) {
      timeLeft = "بدأت الرحلة";
    } else if (difference.inMinutes < 60) {
      timeLeft = "${difference.inMinutes} دقيقة متبقية";
    } else if (difference.inHours < 24) {
      timeLeft =
          "${difference.inHours} ساعة و ${difference.inMinutes % 60} دقيقة متبقية";
    } else {
      timeLeft =
          "${difference.inDays} يوم و ${difference.inHours % 24} ساعة متبقية";
    }

    final hour12 = departure.hour % 12 == 0 ? 12 : departure.hour % 12;
    final amPm = departure.hour >= 12 ? "م" : "ص";
    final timeFormatted =
        "${hour12.toString().padLeft(2, '0')}:${departure.minute.toString().padLeft(2, '0')} $amPm";

    final dateFormatted =
        "${departure.day.toString().padLeft(2, '0')}/${departure.month.toString().padLeft(2, '0')}/${departure.year}";

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        // color: MyColors.primary,
        borderRadius: BorderRadius.circular(16.r),
        // boxShadow: [
        //   BoxShadow(
        //     color: MyColors.primary.withOpacity(0.2),
        //     blurRadius: 8,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.timelapse_outlined,
            color: MyColors.accent,
            size: 28.sp,
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$dateFormatted  |  $timeFormatted",
                style: TextStyle(
                  color: MyColors.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                timeLeft,
                style: TextStyle(
                  color: MyColors.textHint,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'قبل ثوانٍ';
    } else if (difference.inMinutes < 60) {
      return 'قبل ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'قبل ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'قبل ${difference.inDays} يوم';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return 'قبل $weeks أسبوع';
    }
  }

  Widget _buildCreatedAtBadge() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: EdgeInsets.only(top: 10.h, right: 30.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              size: 16.sp,
              color: MyColors.textPrimary,
            ),
            SizedBox(width: 6.w),
            Text(
              timeAgo(widget.trip.createdAt),
              style: TextStyle(
                  color: MyColors.background,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatsInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // بطاقة المقاعد المتاحة
        _buildSeatCard(
          label: "المقاعد المتاحة",
          count: widget.trip.seatsAvailable,
          icon: Icons.event_seat,
          color: MyColors.primary,
        ),
        // بطاقة المقاعد المحجوزة
        _buildSeatCard(
          label: "المقاعد المحجوزة",
          count: widget.trip.seatsBooked,
          icon: Icons.event_busy,
          color: MyColors.accent,
        ),
      ],
    );
  }

  Widget _buildSeatCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: MyColors.textPrimary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodWidget() {
    final method =
        widget.trip.paymentMethod.toLowerCase() == "cash" ? "كاش" : "الكتروني";
    final icon = widget.trip.paymentMethod.toLowerCase() == "cash"
        ? Icons.money // أيقونة للكاش
        : Icons.credit_card; // أيقونة للدفع الالكتروني

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: MyColors.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MyColors.primary, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            "نوع الدفع: ",
            style: TextStyle(
              color: MyColors.textPrimary,
              fontSize: 14.sp,
            ),
          ),
          Text(
            method,
            style: TextStyle(
              color: MyColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTypeWidget() {
    final type = widget.trip.bookingType.toLowerCase() == "direct"
        ? "مباشر"
        : "بعد الموافقة";
    final icon = widget.trip.bookingType.toLowerCase() == "direct"
        ? Icons.flash_on // أيقونة مباشر
        : Icons.pending_actions; // أيقونة طلب

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: MyColors.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MyColors.primary, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            "نوع الحجز: ",
            style: TextStyle(
              color: MyColors.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          Text(
            type,
            style: TextStyle(
              color: MyColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceWidget() {
    final distance = widget.trip.distance;
    final distanceText = distance.kilometers >= 1
        ? "${distance.kilometers.toStringAsFixed(1)} كم"
        : "${distance.meters} م";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 15.h),
      decoration: BoxDecoration(
        // color: MyColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place, color: MyColors.textSecondary, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            "المسافة: ",
            style: TextStyle(
              color: MyColors.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          Text(
            distanceText,
            style: TextStyle(
              color: MyColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationWidget() {
    final duration = widget.trip.duration;
    final durationText = duration.minutes > 0
        ? "${duration.minutes} دقيقة"
        : "${duration.seconds} ثانية";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_filled,
              color: MyColors.textSecondary, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            " المدة المتوقعة: ",
            style: TextStyle(
              color: MyColors.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          Text(
            durationText,
            style: TextStyle(
              color: MyColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceDurationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildDistanceWidget(),
        SizedBox(width: 20.w),
        _buildDurationWidget(),
      ],
    );
  }

  Widget _buildCommunicationNumber() {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: EdgeInsets.only(bottom: 20.h, left: 10.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone, color: MyColors.primary, size: 20.sp),
            SizedBox(width: 10.w),
            Text(
              "تواصل: ",
              style: TextStyle(
                color: MyColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
            Text(
              widget.trip.communicationNumber,
              style: TextStyle(
                color: MyColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAndCreatedAtRow() {
    return Column(
      children: [
        _buildCreatedAtBadge(),
        SizedBox(
          width: 10.w,
        ),
        _buildCommunicationNumber()
      ],
    );
  }

  Widget _buildBookingButton(BuildContext context) {
    return BlocBuilder<TripDetailsCubit, TripDetailsState>(
      builder: (context, state) {
        if (state is TripDetailsLoading) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: MyColors.primary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (state is TripDetailsRequestBooking) {
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: MyColors.accent,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 22.sp),
                  SizedBox(width: 10.w),
                  Text(
                    "تم الحجز",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            if (widget.trip.seatsAvailable == 0) {
              _showNoSeatsDialog(context);
            } else {
              _showBookingDialog(context);
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: MyColors.primary,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: MyColors.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_seat_sharp,
                  color: Colors.white,
                  size: 22.sp,
                ),
                SizedBox(width: 10.w),
                Text(
                  "احجز الآن - ${widget.trip.pricePerSeat} ل.س",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConditionalBookingButton(BuildContext context) {
    BookingModel? booking;
    for (var b in widget.trip.booking) {
      if (b.userId == myid()) {
        booking = b;
        break;
      }
    }

    if (booking != null) {
      switch (booking.status) {
        case "confirmed":
          return _buildBookingStatusButton(
            context,
            color: Colors.green,
            text: "تم قبول الحجز",
            icon: Icons.check_circle,
          );
        case "pending":
          return _buildBookingStatusButton(
            context,
            color: Colors.orange,
            text: "قيد الانتظار",
            icon: Icons.hourglass_top,
          );
        case "rejected":
          return _buildBookingStatusButton(
            context,
            color: Colors.red,
            text: "تم رفض الحجز",
            icon: Icons.cancel,
          );
        case "cancelled":
          return _buildBookingStatusButton(
            context,
            color: Colors.red,
            text: "الحجز ملغي",
            icon: Icons.cancel,
          );
        case "completed":
          return _buildBookingStatusButton(
            context,
            color: Colors.green,
            text: "مؤكد",
            icon: Icons.confirmation_num,
          );
        case "finished":
          return _buildBookingStatusButton(
            context,
            color: Colors.grey,
            text: "انتهت الرحلة",
            icon: Icons.cancel,
          );

        default:
          return _buildBookingButton(context);
      }
    } else {
      return _buildBookingButton(context);
    }
  }

  Widget _buildBookingStatusButton(
    BuildContext context, {
    required Color color,
    required String text,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22.sp),
            SizedBox(width: 10.w),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoSeatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("عذراً"),
        content: Text(
          "لا يوجد مقاعد فارغة في هذه الرحلة.",
          style: TextStyle(fontSize: 14.sp, color: MyColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("حسناً"),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    final seatsController = TextEditingController();
    final contactController = TextEditingController();
    final int maxSeats = widget.trip.seatsAvailable;
    final GlobalKey<FormState> formKey =
        GlobalKey<FormState>(); // مفتاح للتحقق من صحة النموذج

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          "حجز في الرحلة",
          style: TextStyle(
            color: MyColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        content: Form(
          key: formKey, // ربط النموذج بالمفتاح
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "العدد يجب أن يكون أكبر من 0 وأقل أو يساوي $maxSeats",
                style: TextStyle(
                  color: MyColors.background,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 10.h),
              CustomTextformfild(
                title: "أدخل عدد الكراسي ",
                controller: seatsController,
                fill: true,
                fillColor: Colors.white,
                icon: const Icon(
                  Icons.event_seat,
                  color: MyColors.accent,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال عدد الكراسي';
                  }
                  final int? seats = int.tryParse(value);
                  if (seats == null || seats < 1 || seats > maxSeats) {
                    return 'الرجاء إدخال عدد بين 1 و $maxSeats';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10.h),
              CustomTextformfild(
                title: "أدخل رقم التواصل ",
                controller: contactController,
                fill: true,
                fillColor: Colors.white,
                icon: const Icon(
                  Icons.phone,
                  color: MyColors.accent,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال رقم الهاتف';
                  }
                  // التحقق من أن الرقم يحتوي على 10 أرقام فقط
                  final RegExp phoneRegex = RegExp(r'^[0-9]{10}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'يجب أن يتكون رقم الهاتف من 10 أرقام';
                  }
                  return null;
                },
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إلغاء",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () {
              // التحقق من صحة النموذج قبل المتابعة
              if (formKey.currentState!.validate()) {
                final int? seats = int.tryParse(seatsController.text);
                final String contactNumber = contactController.text.trim();

                // هذه الشروط أصبحت زائدة عن الحاجة بسبب الـ validator
                // ولكن نتركها للاحتياط
                if (seats == null || seats < 1 || seats > maxSeats) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("الرجاء إدخال عدد صحيح بين 1 و $maxSeats"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (contactNumber.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("الرجاء إدخال رقم التواصل"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                _bookSeats(seats, widget.trip.id, contactNumber);
                Navigator.pop(context);
              }
            },
            child: const Text(
              "موافق",
              style: AppTextStyles.buttonLarge,
            ),
          ),
        ],
      ),
    );
  }

  void _bookSeats(int seats, int tripId, String contactNumber) async {
    await context
        .read<TripDetailsCubit>()
        .booking(seats, tripId, contactNumber);
  }
}
