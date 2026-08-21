import 'package:flutter/material.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/trip_create/presantion/trip_created_nav.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/functions/my_dilaog.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/presantion/manger/cubit/push_ride_cubit.dart';

const _arabicDays = [
  'الأحد', 'الاثنين', 'الثلاثاء',
  'الأربعاء', 'الخميس', 'الجمعة', 'السبت',
];
const _arabicMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

class TripReviewAndConfirm extends StatelessWidget {
  const TripReviewAndConfirm({
    super.key,
    required this.tripFrom,
    this.onBack,
  });

  final TripFrom tripFrom;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PushRideCubit, PushRideState>(
      listener: _onState,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Column(
                children: [
                  _RouteCard(tripFrom: tripFrom),
                  SizedBox(height: 16.h),
                  _DetailsCard(tripFrom: tripFrom),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          _BottomBar(tripFrom: tripFrom, onBack: onBack),
        ],
      ),
    );
  }

  void _onState(BuildContext context, PushRideState state) {
    if (state is PushRideSuccsess) {
      goToReturnTripPrompt(tripFrom);
    } else if (state is PushRideErorr) {
      final message = HandelErorrMessage.withStatus(
          HandelErorrMessage.createWithRoute(state.message), state.statusCode);
      final needsVerification =
          state.message.contains("You must be verified as a driver") ||
              state.message.contains("Missing required verification");
      if (needsVerification) {
        myConfirmDilaogWithPolicy(
          context,
          message,
          title: "فشل إنشاء الرحلة",
          onConfirm: () =>
              Get.toNamed(RouteName.verfiyUser, arguments: "driver"),
          onCancel: () => Get.offAllNamed(RouteName.home),
        );
      } else if (HandelErorrMessage.isCashRideWalletMissing(state.message)) {
        // رحلة بالدفع النقدي تحتاج محفظة (تُخصم منها رسوم الإنشاء)
        myConfirmDilaogWithPolicy(
          context,
          message,
          title: "المحفظة مطلوبة",
          confirmText: "إنشاء محفظة",
          cancelText: "لاحقاً",
          onConfirm: () => Get.toNamed(RouteName.wallet),
        );
      } else {
        showMySnackBar(context, message);
      }
    }
  }
}

// ─── Route summary card ───────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final TripFrom tripFrom;
  _RouteCard({required this.tripFrom});

  @override
  Widget build(BuildContext context) {
    final startCity = tripFrom.startName ?? 'نقطة الانطلاق';
    final endCity = tripFrom.endName ?? 'الوجهة';
    final distanceKm = (tripFrom.distance as num?)?.toDouble() ?? 0;
    final durationMin = (tripFrom.duration as num?)?.toDouble() ?? 0;
    final parsedDate = _parseDate(tripFrom.date);
    final parsedTime = _parseTime(tripFrom.date);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.route_outlined, title: "ملخص المسار"),
          SizedBox(height: 16.h),
          // ── connector line ──
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12.r,
                      height: 12.r,
                      decoration: BoxDecoration(
                          color: MyColors.primary, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Container(
                          width: 2,
                          color: MyColors.border,
                          margin: EdgeInsets.symmetric(vertical: 4.h)),
                    ),
                    Container(
                      width: 12.r,
                      height: 12.r,
                      decoration: BoxDecoration(
                          color: MyColors.accent, shape: BoxShape.circle),
                    ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(startCity,
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: 16.h),
                      Text(endCity,
                          style: AppTextStyles.labelLarge
                              .copyWith(color: MyColors.accent),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Divider(color: MyColors.border, height: 1, thickness: 1),
          SizedBox(height: 12.h),
          // ── chips row ──
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _InfoChip(
                icon: Icons.straighten_rounded,
                label: '${distanceKm.toStringAsFixed(0)} كم',
              ),
              _InfoChip(
                icon: Icons.timer_outlined,
                label: '${durationMin.toStringAsFixed(0)} دقيقة',
              ),
              if (parsedDate.isNotEmpty)
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: parsedDate,
                ),
              if (parsedTime.isNotEmpty)
                _InfoChip(
                  icon: Icons.access_time_outlined,
                  label: parsedTime,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _parseDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr);
      return '${_arabicDays[dt.weekday % 7]}، ${dt.day} ${_arabicMonths[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  String _parseTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final period =
          dt.hour < 12 ? 'صباحاً' : (dt.hour < 17 ? 'ظهراً' : 'مساءً');
      return '$h:$m $period';
    } catch (_) {
      return '';
    }
  }
}

// ─── Details card ─────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final TripFrom tripFrom;
  _DetailsCard({required this.tripFrom});

  @override
  Widget build(BuildContext context) {
    final cashLabel = tripFrom.cashType == 'cash' ? 'كاش' : 'إلكتروني';
    final bookingLabel =
        tripFrom.bookingType == 'Direct' ? 'أي شخص' : 'بعد الموافقة';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
              icon: Icons.list_alt_rounded, title: "تفاصيل الرحلة"),
          SizedBox(height: 8.h),
          _DetailRow(
            icon: Icons.airline_seat_recline_normal_outlined,
            label: "المقاعد المتاحة",
            value: "${tripFrom.numberSeats} راكب",
          ),
          const _RowDivider(),
          _DetailRow(
            icon: Icons.monetization_on_outlined,
            label: "السعر للمقعد",
            value: "${_formatPrice(tripFrom.price)} ل.س",
          ),
          const _RowDivider(),
          _DetailRow(
            icon: Icons.payment_outlined,
            label: "طريقة الدفع",
            value: cashLabel,
          ),
          const _RowDivider(),
          _DetailRow(
            icon: Icons.bookmark_border_rounded,
            label: "نوع الحجز",
            value: bookingLabel,
          ),
          const _RowDivider(),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: "رقم التواصل",
            value: tripFrom.numberPhone ?? '---',
          ),
          if (tripFrom.notes.isNotEmpty) ...[
            const _RowDivider(),
            _DetailRow(
              icon: Icons.notes_rounded,
              label: "ملاحظات",
              value: tripFrom.notes,
            ),
          ],
        ],
      ),
    );
  }

  String _formatPrice(int p) =>
      NumberFormat('#,###').format(p);
}

// ─── Bottom publish bar ───────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final TripFrom tripFrom;
  final VoidCallback? onBack;
  const _BottomBar({required this.tripFrom, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyColors.surface,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MyColors.primary,
                  side: BorderSide(color: MyColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                  minimumSize: Size(double.infinity, 52.h),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 18.sp),
              ),
            ),
            SizedBox(width: 10.w),
          ],
          Expanded(
            flex: 3,
            child: BlocBuilder<PushRideCubit, PushRideState>(
              // لا بد من إدراج حالتَي الفشل والنجاح: بدونهما لا يُعاد بناء
              // الزر بعد فشل النشر فيبقى عالقاً في وضع التحميل للأبد.
              buildWhen: (_, curr) =>
                  curr is PushRideLoading ||
                  curr is PushRideInitial ||
                  curr is PushRideErorr ||
                  curr is PushRideSuccsess,
              builder: (context, state) {
                final isLoading = state is PushRideLoading;
                return ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () =>
                          context.read<PushRideCubit>().pushRide(tripFrom),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                    minimumSize: Size(double.infinity, 52.h),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const AppLoader.onButton()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch_outlined, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text("نشر الرحلة",
                                style: AppTextStyles.buttonLarge),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
            color: MyColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: MyColors.primary, size: 17.sp),
        ),
        SizedBox(width: 8.w),
        Text(title, style: AppTextStyles.labelLarge),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: MyColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: MyColors.textSecondary),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.labelSmall
                .copyWith(color: MyColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: MyColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: MyColors.primary, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Text(
            label,
            style:
                AppTextStyles.bodySmall.copyWith(color: MyColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.labelLarge
                .copyWith(color: MyColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      Divider(color: MyColors.border, height: 1, thickness: 1);
}
