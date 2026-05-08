import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/widget/status_trip.dart';

class BookingItem extends StatefulWidget {
  final BookingMe booking;
  final VoidCallback onTapDetails;

  const BookingItem({
    super.key,
    required this.booking,
    required this.onTapDetails,
  });

  @override
  State<BookingItem> createState() => _BookingItemState();
}

class _BookingItemState extends State<BookingItem> {
  late final StatusInfo statusInfoRide;
  late final StatusInfo statusInfobooking;

  @override
  void initState() {
    statusInfoRide = getStatusInfo(widget.booking.rideStatus);
    statusInfobooking = getStatusInfo(widget.booking.status);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTapDetails,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 16.h),
              _buildTripDetails(),
              SizedBox(height: 16.h),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              SizedBox(height: 16.h),
              _buildPricingInfo(),
              SizedBox(height: 16.h),
              _buildAdditionalInfo(),
              SizedBox(height: 16.h),
              BlocBuilder<BookingMeCubit, BookingMeState>(
                builder: (context, state) {
                  if (state is BookingMeButtonloading) {
                    return const CircularProgressIndicator();
                  } else if (state is BookingMeCanceled) {
                    return MyButton(
                      onPressed: () {},
                      child: const Text("تم الغاء الحجز"),
                    );
                  } else if (state is BookingMeRated) {
                    return RatingBarIndicator(
                      rating: state.rate,
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 20.0,
                      direction: Axis.horizontal,
                    );
                  } else if (state is BookingMeFinish) {
                    return _buildFeedBackButton(
                        context, widget.booking.userDriver);
                  }

                  return _buildActionButtons(context, widget.booking.status,
                      widget.booking.userDriver);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            // Get.toNamed(RouteName.profile ,arguments:  widget.booking.driverId)
          },
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Driver avatar
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: MyColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: (widget.booking.driverAvatar.isEmpty)
                      ? Image.asset(
                          ImagesUrl.profileImage,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          widget.booking.driverAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              ImagesUrl.profileImage,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                ),
              ),

              // Online status indicator
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: statusInfobooking.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              widget.booking.driverName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: MyColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusInfobooking.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusInfobooking.color,
              width: 1,
            ),
          ),
          child: Text(
            statusInfobooking.text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusInfobooking.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.my_location, size: 18, color: MyColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "من: ${widget.booking.pickupAddress}",
                style: const TextStyle(
                  fontSize: 14,
                  color: MyColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(vertical: 10.h),
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.route,
              size: 25.w,
              color: MyColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, size: 18, color: MyColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "إلى: ${widget.booking.destinationAddress}",
                style: const TextStyle(
                  fontSize: 14,
                  color: MyColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today,
                size: 16, color: MyColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              _formatDate(widget.booking.bookingDate),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.access_time, size: 16, color: MyColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              _formatTime(widget.booking.departureTime),
              style: const TextStyle(
                  fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              width: 30.w,
            ),
          ],
        ),
        Center(
          child: Card(
            margin: const EdgeInsets.all(10),
            color: MyColors.textHint,
            child: Padding(
              padding: const EdgeInsetsGeometry.all(8),
              child: Text(
                timeUntil(widget.booking.departureTime),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: MyColors.textHint),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoItem(
            "عدد المقاعد", "${widget.booking.seats}", Icons.event_seat),
        _buildInfoItem("سعر المقعد", "${widget.booking.pricePerSeat} ل.س",
            Icons.attach_money),
        _buildInfoItem(
            "السعر الكلي", "${widget.booking.totalPrice} ل.س", Icons.payment),
      ],
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: MyColors.accent),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: MyColors.textHint,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MyColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAdditionalInfoItem(
            "المركبة", widget.booking.vehicleType, Icons.directions_car),
        _buildAdditionalInfoItem(
            "طريقة الدفع", widget.booking.paymentMethod, Icons.credit_card),
        _buildAdditionalInfoItem(
            "حالة الرحلة", statusInfobooking.text, Icons.trip_origin),
      ],
    );
  }

  Widget _buildAdditionalInfoItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: MyColors.textLight),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: MyColors.textLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: MyColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, String bookingState, int userId) {
    final departure = widget.booking.departureTime;
    final now = DateTime.now();
    final difference = departure.difference(now);

    return Row(
      children: [
        switch (bookingState) {
          "completed" => Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showRatingDialog(context, userId),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blue.shade100, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                ),
                icon: const Icon(Icons.star_rate, size: 22), 
                label: const Text(
                  "الرحلة انتهت - قيم الآن",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          "cancelled" => Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (states) => states.contains(WidgetState.pressed)
                        ? Colors.red
                        : Colors.red,
                  ),
                ),
                icon: const Icon(Icons.cancel, size: 20),
                label: const Text(
                  "تم الالغاء",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          "pending" => Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final seatsToCancel = await _showCancelSeatsDialog();
                  if (seatsToCancel != null) {
                    final confirm = await _showConfirmationDialog(
                      "هل أنت متأكد انك تريد الغاء حجز مقعد  $seatsToCancel .",
                    );
                    if (confirm ?? false) {
                      context.read<BookingMeCubit>().cancelBooking(
                            widget.booking.bookingId,
                            seatsToCancel,
                          );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (states) => states.contains(WidgetState.pressed)
                        ? MyColors.accent.withOpacity(0.8)
                        : MyColors.accent,
                  ),
                ),
                icon: const Icon(Icons.cancel, size: 20),
                label: const Text(
                  "إلغاء الحجز",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          "finished" => Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text(
                  "انتهت الرحلة",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          "canceled" => Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم إلغاء الحجز مسبقاً")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.block, size: 20),
                label: const Text(
                  "الحجز ملغي",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          _ => difference.inSeconds <= 0
              ? Expanded(
                  child: Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await _showConfirmationDialog(
                            "هل أنت متأكد من إنهاء الرحلة؟ تأكيد الخيار هذا يدل على وصلك الى الموقع المحدد و نجاح الرحلة ",
                          );
                          if (confirm ?? false) {
                            context
                                .read<BookingMeCubit>()
                                .finishTrip(widget.booking.bookingId);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ).copyWith(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                            (states) => states.contains(WidgetState.pressed)
                                ? MyColors.primary.withOpacity(0.8)
                                : MyColors.primary,
                          ),
                        ),
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text(
                          "إنهاء الرحلة",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ]),
                )
              : Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final seatsToCancel = await _showCancelSeatsDialog();
                      if (seatsToCancel != null) {
                        final confirm = await _showConfirmationDialog(
                          "هل أنت متأكد من إلغاء $seatsToCancel مقعد(مقاعد)؟ قد يتم خصم جزء من المبلغ أو كامل المبلغ.",
                        );
                        if (confirm ?? false) {
                          context.read<BookingMeCubit>().cancelBooking(
                                widget.booking.bookingId,
                                seatsToCancel,
                              );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => states.contains(WidgetState.pressed)
                            ? MyColors.accent.withOpacity(0.8)
                            : MyColors.accent,
                      ),
                    ),
                    icon: const Icon(Icons.cancel, size: 20),
                    label: const Text(
                      "إلغاء الحجز",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
        }
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'م' : 'ص'; // ص = AM ، م = PM
    hour = hour % 12;
    if (hour == 0) hour = 12; // للتعامل مع منتصف الليل والظهيرة
    String minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  String timeUntil(DateTime tripTime) {
    final now = DateTime.now();
    if (tripTime.isBefore(now)) {
      return "انطلقت الرحلة";
    }

    final difference = tripTime.difference(now);

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    String formatUnit(int value, String singular, String dual, String plural) {
      if (value == 1) {
        return '$value $singular';
      } else if (value == 2) {
        return '$value $dual';
      } else if (value >= 3 && value <= 10) {
        return '$value $plural';
      } else {
        return '$value $singular';
      }
    }

    List<String> parts = [];
    if (days > 0) {
      parts.add(formatUnit(days, "يوم", "يومين", "أيام"));
    }
    if (hours > 0) {
      parts.add(formatUnit(hours, "ساعة", "ساعتين", "ساعات"));
    }
    if (minutes > 0) {
      parts.add(formatUnit(minutes, "دقيقة", "دقيقتين", "دقائق"));
    }

    if (parts.isEmpty) {
      return "انطلقت الرحلة ";
    }

    return "باقٍ على الانطلاق: ${parts.join(" و ")}";
  }

  Future<int?> _showCancelSeatsDialog() async {
    int selectedSeats = 1;
    int maxSeats = widget.booking.seats;

    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "إلغاء المقاعد",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MyColors.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: MyColors.textLight),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "حدد عدد المقاعد التي تريد إلغاء حجزها",
                        style: TextStyle(
                          fontSize: 14,
                          color: MyColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // زر التقليل
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: selectedSeats <= 1
                                    ? Colors.grey
                                    : MyColors.accent,
                              ),
                              onPressed: selectedSeats <= 1
                                  ? null
                                  : () {
                                      setState(() {
                                        selectedSeats--;
                                      });
                                    },
                            ),

                            // عدد المقاعد المختارة
                            Text(
                              "$selectedSeats",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: MyColors.primary,
                              ),
                            ),

                            // زر الزيادة
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: selectedSeats >= maxSeats
                                    ? Colors.grey
                                    : MyColors.accent,
                              ),
                              onPressed: selectedSeats >= maxSeats
                                  ? null
                                  : () {
                                      setState(() {
                                        selectedSeats++;
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "الحد الأقصى للإلغاء: $maxSeats مقاعد",
                        style: const TextStyle(
                          fontSize: 12,
                          color: MyColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MyColors.primary,
                                side: const BorderSide(color: MyColors.primary),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("تراجع"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(selectedSeats),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MyColors.accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("تأكيد الإلغاء"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog(String message,
      {bool showPolicyLink = true}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "تأكيد",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (showPolicyLink) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Get.toNamed(RouteName.policy);
                },
                child: const Text(
                  "تعرف على سياسية التطبيق",
                  style: TextStyle(
                    color: MyColors.accent,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 100,
            height: 40,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "لا",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            height: 40,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "نعم",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedBackButton(BuildContext context, int userId) {
    const starCount = 5;
    final stars = List.generate(
      starCount,
      (index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          Icons.star_rate_rounded,
          size: 20,
          color: Colors.white,
        ),
      ),
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
    ).copyWith(
      overlayColor: WidgetStateProperty.all(Colors.amber.withOpacity(0.3)),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 60.w),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _showRatingDialog(context, userId),
          style: buttonStyle, // استخدام النمط الذي أنشأناه
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: stars,
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, int userId) {
    double userRating = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'قيم السائق',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'كيف تقيم تجربتك مع السائق',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 28.0, // تم تصغير حجم النجوم
                    itemPadding: const EdgeInsets.symmetric(
                        horizontal: 2.0), // تم تقليل المسافة
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        userRating = rating;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  if (userRating > 0)
                    Text(
                      'تقييمك: ${userRating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // حجم نص أصغر
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (userRating > 0) {
                      _saveRating(userRating, userId);
                      Navigator.of(context).pop();
                      _showThankYouMessage(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('إرسال التقييم'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveRating(double rating, int userId) async {
    await context.read<BookingMeCubit>().reateUser(rating, userId);
  }

  void _showThankYouMessage(BuildContext context) {
    showMySnackBar(context, "شكرا لك على تقييمك ");
  }
}
