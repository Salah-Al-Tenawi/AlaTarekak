import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

// ━━ بيانات فترة اليوم ━━
class _TimeSlotData {
  final String label;
  final String range;
  final IconData icon;
  final int hour;
  const _TimeSlotData({
    required this.label,
    required this.range,
    required this.icon,
    required this.hour,
  });
}

const _timeSlots = [
  _TimeSlotData(
    label: 'صباحاً',
    range: '6:00 - 12:00',
    icon: Icons.wb_sunny_outlined,
    hour: 9,
  ),
  _TimeSlotData(
    label: 'ظهراً',
    range: '12:00 - 17:00',
    icon: Icons.wb_sunny_rounded,
    hour: 14,
  ),
  _TimeSlotData(
    label: 'مساءً',
    range: '17:00 - 00:00',
    icon: Icons.nights_stay_outlined,
    hour: 20,
  ),
];

const _arabicDays = [
  'الأحد', 'الاثنين', 'الثلاثاء',
  'الأربعاء', 'الخميس', 'الجمعة', 'السبت',
];

const _arabicMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// الشاشة الرئيسية
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class TripSelectDateAndSeats extends StatefulWidget {
  const TripSelectDateAndSeats({super.key});

  @override
  State<TripSelectDateAndSeats> createState() => _TripSelectDateAndSeatsState();
}

class _TripSelectDateAndSeatsState extends State<TripSelectDateAndSeats> {
  late TripFrom _tripFrom;
  DateTime _selectedDate = DateTime.now();
  int _selectedTimeSlot = 1; // افتراضي: ظهراً
  int _seats = 1;

  @override
  void initState() {
    super.initState();
    _tripFrom = Get.arguments as TripFrom;
  }

  void _onNext() {
    if (_seats == 0) {
      AppSnackBar.warning("يرجى تحديد عدد المقاعد");
      return;
    }

    final slot = _timeSlots[_selectedTimeSlot];
    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      slot.hour,
    );
    _tripFrom.date = DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    _tripFrom.numberSeats = _seats;

    Get.toNamed(RouteName.tripSelectPriceAndBookingType, arguments: _tripFrom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded,
              color: MyColors.primary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text("إضافة رحلة جديدة", style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ━━ مؤشر الخطوة ━━
          _StepIndicator(currentStep: 2, totalSteps: 3),

          // ━━ المحتوى القابل للتمرير ━━
          Expanded(
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── التوقيت ──
                  _SectionHeader(
                    icon: Icons.calendar_today_outlined,
                    title: "التوقيت",
                  ),

                  SizedBox(height: 14.h),

                  Text(
                    "اختر تاريخ الرحلة",
                    style: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textSecondary),
                  ),

                  SizedBox(height: 10.h),

                  // ── منتقي التاريخ الأفقي ──
                  _DatePickerRow(
                    selectedDate: _selectedDate,
                    onSelect: (d) => setState(() => _selectedDate = d),
                  ),

                  SizedBox(height: 24.h),

                  // ── وقت الانطلاق ──
                  _SectionHeader(
                    icon: Icons.access_time_outlined,
                    title: "وقت الانطلاق",
                  ),

                  SizedBox(height: 14.h),

                  _TimeSlotRow(
                    selectedIndex: _selectedTimeSlot,
                    onSelect: (i) =>
                        setState(() => _selectedTimeSlot = i),
                  ),

                  SizedBox(height: 24.h),

                  // ── عدد المقاعد ──
                  _SectionHeader(
                    icon: Icons.airline_seat_recline_normal_outlined,
                    title: "عدد المقاعد المتاحة",
                  ),

                  SizedBox(height: 14.h),

                  _SeatsCounter(
                    seats: _seats,
                    onIncrement: () =>
                        setState(() { if (_seats < 8) _seats++; }),
                    onDecrement: () =>
                        setState(() { if (_seats > 1) _seats--; }),
                  ),

                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),

          // ━━ زر التالي ━━
          _NextButton(onTap: _onNext),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// مؤشر الخطوة
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator(
      {required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyColors.surface,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "الخطوة $currentStep من $totalSteps",
            style: AppTextStyles.labelMedium
                .copyWith(color: MyColors.textSecondary),
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentStep / totalSteps,
              backgroundColor: MyColors.surfaceAlt,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(MyColors.primary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// عنوان قسم
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: MyColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: MyColors.primary, size: 17),
        ),
        SizedBox(width: 8.w),
        Text(title, style: AppTextStyles.labelLarge),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// منتقي التاريخ الأفقي
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _DatePickerRow extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  const _DatePickerRow(
      {required this.selectedDate, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
        10, (i) => DateTime(today.year, today.month, today.day + i));

    return SizedBox(
      height: 80.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: days.length,
        separatorBuilder: (ctx, i) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final day = days[i];
          final isSelected = day.year == selectedDate.year &&
              day.month == selectedDate.month &&
              day.day == selectedDate.day;

          return GestureDetector(
            onTap: () => onSelect(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 90.w : 72.w,
              decoration: BoxDecoration(
                color:
                    isSelected ? MyColors.primary : MyColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: MyColors.shadowLight,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _arabicDays[day.weekday % 7],
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : MyColors.textSecondary,
                      fontSize: 9.sp,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    "${day.day}",
                    style: AppTextStyles.titleLarge.copyWith(
                      color: isSelected
                          ? Colors.white
                          : MyColors.textPrimary,
                      fontSize: isSelected ? 22.sp : 18.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _arabicMonths[day.month - 1],
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : MyColors.textSecondary,
                      fontSize: 9.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// صف فترات اليوم
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _TimeSlotRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _TimeSlotRow(
      {required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_timeSlots.length, (i) {
        final slot = _timeSlots[i];
        final isSelected = i == selectedIndex;

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                right: i < _timeSlots.length - 1 ? 8.w : 0,
              ),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? MyColors.primary
                    : MyColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: MyColors.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    slot.icon,
                    size: 24,
                    color: isSelected
                        ? Colors.white
                        : MyColors.accent,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    slot.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected
                          ? Colors.white
                          : MyColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    slot.range,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.75)
                          : MyColors.textSecondary,
                      fontSize: 9.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// عداد المقاعد
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SeatsCounter extends StatelessWidget {
  final int seats;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _SeatsCounter({
    required this.seats,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ━━ زر ناقص ━━
          _CounterButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            enabled: seats > 1,
          ),

          // ━━ العدد ━━
          Expanded(
            child: Column(
              children: [
                Text(
                  "$seats",
                  style: AppTextStyles.displayLarge.copyWith(
                    color: MyColors.primary,
                    fontSize: 40.sp,
                  ),
                ),
                Text(
                  "مقعد",
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.textSecondary),
                ),
              ],
            ),
          ),

          // ━━ زر زائد ━━
          _CounterButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            enabled: seats < 8,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? MyColors.primary
              : MyColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : MyColors.textHint,
          size: 22,
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// زر التالي
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _NextButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyColors.surface,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: MyColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          label: Text("التالي", style: AppTextStyles.buttonPrimary),
        ),
      ),
    );
  }
}
