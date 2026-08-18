import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:flutter/services.dart';
import 'package:alatarekak/features/trip_create/domin/ride_price_rules.dart';
import 'package:alatarekak/features/trip_create/presantion/view/widget/price_ranking_hint.dart';

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

  /// مسافة الرحلة بالكيلومترات — عليها يُبنى التسعير كلّه.
  late double _km;

  /// سبب رفض السعر المكتوب يدوياً، يُعرض تحت الحقل.
  String? _priceError;
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
    // السعر المقترح يُحسب مرة واحدة فقط. كان يُحسب في كل بناء ويكتب فوق
    // ما اختاره السائق، فيفقد سعره كلما رجع خطوة وعاد.
    _km = (_tripFrom.distance as num?)?.toDouble() ?? 0;
    final suggested = RidePriceRules.suggestedFor(_km);
    _tripFrom.recomandedPrice = suggested.toDouble();
    _price = _tripFrom.price > 0 ? _tripFrom.price : suggested;
    _tripFrom.price = _price;

    _cashType = _tripFrom.cashType;
    _bookingType = _tripFrom.bookingType;
    _notesController.text = _tripFrom.notes;

    // الملاحظات كانت تُحفظ عند الانتقال فقط، فتضيع لو رجع قبله
    _notesController.addListener(
      () => _tripFrom.notes = _notesController.text.trim(),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _suggested => RidePriceRules.suggestedFor(_km);

  void _setPrice(int value, {String? error}) {
    setState(() {
      _price = value;
      _priceError = error;
      _tripFrom.price = _price;
    });
  }

  void _adjustPrice(bool increase) => _setPrice(
        RidePriceRules.nextPrice(_km, _price, increase: increase),
      );

  void _resetToSuggested() => _setPrice(_suggested);

  /// السعر المكتوب باليد: يُقبل ما دام دون سقف الكيلومتر.
  ///
  /// **نقترح ولا نُجبر** — فالخطأ يُعرض ولا يُعاد الرقم قسراً إلى المدى،
  /// كي يرى السائق ما كتبه ويصحّحه بنفسه.
  void _onManualPrice(String raw) {
    final parsed = int.tryParse(raw.trim());
    final error = RidePriceRules.validate(_km, parsed);

    setState(() {
      _priceError = error;
      if (parsed != null && parsed > 0) {
        _price = parsed;
        _tripFrom.price = parsed;
      }
    });
  }

  void _onNext() {
    // سعر خارج الحدّين يرفضه الخادم — نمنعه هنا فلا يُهدر باقي المعالج
    final error = RidePriceRules.validate(_km, _price);
    if (error != null) {
      setState(() => _priceError = error);
      return;
    }

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
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded,
              size: 20),
          onPressed: widget.onBack ?? () => Get.back(),
        ),
        title:
            Text("إضافة رحلة جديدة", style: AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
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
                  km: _km,
                  suggested: _suggested,
                  error: _priceError,
                  onIncrease: () => _adjustPrice(true),
                  onDecrease: () => _adjustPrice(false),
                  onManual: _onManualPrice,
                  onResetSuggested: _resetToSuggested,
                ),
                SizedBox(height: 12.h),
                // السعر يؤثّر في ترتيب ظهور الرحلة — يستحقّ السائق أن
                // يعرف ذلك قبل أن ينتظر حجوزات لا تأتي
                PriceRankingHint(price: _price, suggested: _suggested),
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
                      borderSide: BorderSide(color: MyColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: MyColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(
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

/// اختيار السعر: مقترح يقبله السائق أو يناغشه أو يكتب غيره.
///
/// كان عدّاداً وحده بلا سقف ولا سبيل لكتابة رقم — فمن أراد سعراً بعيداً
/// عن المقترح ضغط عشرين ضغطة، ومن أراد رقماً غير مضاعفات الخطوة لم يجد
/// إليه سبيلاً.
class _PriceSelector extends StatefulWidget {
  final int price;
  final double km;
  final int suggested;
  final String? error;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final ValueChanged<String> onManual;
  final VoidCallback onResetSuggested;

  const _PriceSelector({
    required this.price,
    required this.km,
    required this.suggested,
    required this.error,
    required this.onIncrease,
    required this.onDecrease,
    required this.onManual,
    required this.onResetSuggested,
  });

  @override
  State<_PriceSelector> createState() => _PriceSelectorState();
}

class _PriceSelectorState extends State<_PriceSelector> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.price}');
  final _focus = FocusNode();

  @override
  void didUpdateWidget(covariant _PriceSelector old) {
    super.didUpdateWidget(old);
    // العدّاد يغيّر الرقم من خارج الحقل — نزامنه ما لم يكن السائق يكتب
    if (widget.price != old.price && !_focus.hasFocus) {
      _controller.text = '${widget.price}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rate = RidePriceRules.ratePerKm(widget.km, widget.price);
    final isSuggested = widget.price == widget.suggested;
    final hasError = widget.error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: MyColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
                color: hasError ? MyColors.error : MyColors.border),
            boxShadow: [
              BoxShadow(
                  color: MyColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _CounterBtn(
                      icon: Icons.remove_rounded, onTap: widget.onDecrease),
                  // الرقم حقل كتابة لا نصّاً: يُلمس فيُكتب مباشرةً
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      onChanged: widget.onManual,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayLarge.copyWith(
                          color: hasError ? MyColors.error : MyColors.primary,
                          fontSize: 32.sp),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  _CounterBtn(icon: Icons.add_rounded, onTap: widget.onIncrease),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                widget.km > 0
                    ? 'ليرة سورية · ${rate.round()} ل.س للكيلومتر'
                    : 'ليرة سورية',
                style: AppTextStyles.labelSmall
                    .copyWith(color: MyColors.textSecondary),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 15.sp, color: MyColors.error),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  widget.error!,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.error, height: 1.5),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 10.h),
        // الاقتراح ظاهر دائماً وسبيل العودة إليه بضغطة — نقترح ولا نُجبر
        _SuggestionHint(
          suggested: widget.suggested,
          isApplied: isSuggested,
          onApply: widget.onResetSuggested,
        ),
      ],
    );
  }
}

class _SuggestionHint extends StatelessWidget {
  final int suggested;
  final bool isApplied;
  final VoidCallback onApply;

  const _SuggestionHint({
    required this.suggested,
    required this.isApplied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    if (suggested <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: MyColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: MyColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isApplied ? Icons.check_circle_rounded : Icons.lightbulb_outline,
            size: 16.sp,
            color: isApplied ? MyColors.success : MyColors.accent,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              isApplied
                  ? 'هذا هو السعر المقترح لرحلتك'
                  : 'السعر المقترح $suggested ل.س',
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary, height: 1.4),
            ),
          ),
          if (!isApplied)
            TextButton(
              onPressed: onApply,
              style: TextButton.styleFrom(
                minimumSize: Size(0, 32.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                visualDensity: VisualDensity.compact,
              ),
              child: Text('استعمله',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.primary)),
            ),
        ],
      ),
    );
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
              duration: Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                  left: options.last == opt ? 0 : 8.w),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: isSelected ? MyColors.primary : MyColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
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
                  side: BorderSide(color: MyColors.primary),
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
