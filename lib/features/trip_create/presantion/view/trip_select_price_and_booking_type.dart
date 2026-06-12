import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

class TripSelectPriceAndBookingType extends StatefulWidget {
  const TripSelectPriceAndBookingType({
    super.key,
    this.tripFrom,
    this.onNext,
    this.onBack,
  });

  final TripFrom? tripFrom;
  final void Function(TripFrom)? onNext;
  final VoidCallback? onBack;

  @override
  State<TripSelectPriceAndBookingType> createState() =>
      _TripSelectPriceAndBookingTypeState();
}

class _TripSelectPriceAndBookingTypeState
    extends State<TripSelectPriceAndBookingType> {
  late TripFrom _tripFrom;
  late int _price;
  String _cashType = 'cash';
  String _bookingType = 'Direct';
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.tripFrom != null) {
      _tripFrom = widget.tripFrom!;
    } else {
      _tripFrom = Get.arguments as TripFrom;
    }
    _price = _calcSuggestedPrice(_tripFrom.distance);
    _tripFrom.price = _price;
    _cashType = _tripFrom.cashType;
    _bookingType = _tripFrom.bookingType;
    _notesController.text = _tripFrom.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int _calcSuggestedPrice(dynamic distanceKm) {
    final km = (distanceKm as num?)?.toDouble() ?? 0;
    final raw = km <= 65 ? km * 500 : km * 700;
    return (raw ~/ 1000) * 1000;
  }

  void _adjustPrice(bool increase) {
    setState(() {
      if (increase) {
        if (_price < 20000) {
          _price += 2000;
        } else if (_price < 40000) {
          _price += 5000;
        } else {
          _price += 5000;
        }
      } else {
        if (_price > 40000) {
          _price -= 10000;
        } else if (_price > 20000) {
          _price -= 5000;
        } else if (_price > 2000) {
          _price -= 2000;
        }
      }
      _tripFrom.price = _price;
    });
  }

  void _onNext() {
    _tripFrom
      ..price = _price
      ..cashType = _cashType
      ..bookingType = _bookingType
      ..notes = _notesController.text.trim();

    if (widget.onNext != null) {
      widget.onNext!(_tripFrom);
    } else {
      Get.toNamed(RouteName.tripAddNumberPhone, arguments: _tripFrom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    // Wizard mode: no Scaffold needed, wizard provides it
    if (widget.onNext != null) return content;

    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded,
              color: MyColors.primary, size: 20),
          onPressed: widget.onBack ?? () => Get.back(),
        ),
        title:
            Text("إضافة رحلة جديدة", style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: content,
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.monetization_on_outlined,
                  title: "السعر للراكب (ل.س)",
                ),
                SizedBox(height: 14.h),
                _PriceSelector(
                  price: _price,
                  onIncrease: () => _adjustPrice(true),
                  onDecrease: () => _adjustPrice(false),
                ),
                SizedBox(height: 24.h),
                _SectionHeader(
                  icon: Icons.payment_outlined,
                  title: "طريقة الدفع",
                ),
                SizedBox(height: 14.h),
                _OptionRow<String>(
                  options: const [
                    _OptionData(
                        value: 'cash',
                        label: 'كاش',
                        icon: FontAwesomeIcons.moneyBillWave),
                    _OptionData(
                        value: 'e-pay',
                        label: 'إلكتروني',
                        icon: FontAwesomeIcons.creditCard),
                  ],
                  selected: _cashType,
                  onSelect: (v) => setState(() {
                    _cashType = v;
                    _tripFrom.cashType = v;
                  }),
                ),
                SizedBox(height: 24.h),
                _SectionHeader(
                  icon: Icons.bookmark_border_rounded,
                  title: "نوع الحجز",
                ),
                SizedBox(height: 8.h),
                _BookingTypeNote(),
                SizedBox(height: 10.h),
                _OptionRow<String>(
                  options: const [
                    _OptionData(
                        value: 'Direct',
                        label: 'أي شخص',
                        icon: FontAwesomeIcons.userGroup),
                    _OptionData(
                        value: 'request',
                        label: 'بعد الموافقة',
                        icon: FontAwesomeIcons.userCheck),
                  ],
                  selected: _bookingType,
                  onSelect: (v) => setState(() {
                    _bookingType = v;
                    _tripFrom.bookingType = v;
                  }),
                ),
                SizedBox(height: 24.h),
                _SectionHeader(
                  icon: Icons.notes_rounded,
                  title: "ملاحظات (اختياري)",
                ),
                SizedBox(height: 10.h),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: "أضف أي تفاصيل إضافية...",
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textHint),
                    filled: true,
                    fillColor: MyColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: MyColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(color: MyColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: const BorderSide(
                          color: MyColors.primary, width: 1.5),
                    ),
                    contentPadding: EdgeInsets.all(12.w),
                  ),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: MyColors.textPrimary),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
        _BottomNavBar(
          onBack: widget.onBack ?? () => Get.back(),
          onNext: _onNext,
          isInWizard: widget.onNext != null,
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

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

class _PriceSelector extends StatelessWidget {
  final int price;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  const _PriceSelector(
      {required this.price,
      required this.onIncrease,
      required this.onDecrease});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [
          BoxShadow(color: MyColors.shadowLight, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          _CounterBtn(icon: Icons.remove_rounded, onTap: onDecrease),
          Expanded(
            child: Column(
              children: [
                Text(
                  _formatPrice(price),
                  style: AppTextStyles.displayLarge
                      .copyWith(color: MyColors.primary, fontSize: 36.sp),
                ),
                Text("ليرة سورية",
                    style: AppTextStyles.labelSmall
                        .copyWith(color: MyColors.textSecondary)),
              ],
            ),
          ),
          _CounterBtn(icon: Icons.add_rounded, onTap: onIncrease),
        ],
      ),
    );
  }

  String _formatPrice(int p) {
    if (p >= 1000) {
      return '${(p / 1000).toStringAsFixed(p % 1000 == 0 ? 0 : 1)}k';
    }
    return '$p';
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: MyColors.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: Colors.white, size: 22.sp),
      ),
    );
  }
}

class _OptionData<T> {
  final T value;
  final String label;
  final IconData icon;
  const _OptionData(
      {required this.value, required this.label, required this.icon});
}

class _OptionRow<T> extends StatelessWidget {
  final List<_OptionData<T>> options;
  final T selected;
  final ValueChanged<T> onSelect;
  const _OptionRow(
      {required this.options,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isSelected = opt.value == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                  left: options.last == opt ? 0 : 8.w),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: isSelected ? MyColors.primary : MyColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: const [
                  BoxShadow(
                      color: MyColors.shadowLight,
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(opt.icon,
                      size: 24.sp,
                      color: isSelected ? Colors.white : MyColors.accent),
                  SizedBox(height: 6.h),
                  Text(opt.label,
                      style: AppTextStyles.labelLarge.copyWith(
                          color: isSelected
                              ? Colors.white
                              : MyColors.textPrimary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BookingTypeNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: MyColors.accentLight,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: MyColors.accent, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              "\"أي شخص\" يعني قبول الحجز فوراً، \"بعد الموافقة\" يعني مراجعتك أولاً.",
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool isInWizard;
  const _BottomNavBar(
      {required this.onBack,
      required this.onNext,
      required this.isInWizard});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MyColors.surface,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: Row(
        children: [
          if (isInWizard)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MyColors.primary,
                  side: const BorderSide(color: MyColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                  minimumSize: Size(double.infinity, 52.h),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 18.sp),
              ),
            ),
          if (isInWizard) SizedBox(width: 10.w),
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
                minimumSize: Size(double.infinity, 52.h),
                elevation: 0,
              ),
              icon: Icon(Icons.arrow_back_rounded, size: 20.sp),
              label: Text("التالي", style: AppTextStyles.buttonLarge),
            ),
          ),
        ],
      ),
    );
  }
}
