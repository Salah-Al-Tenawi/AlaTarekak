import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';

class OtpTextform extends StatefulWidget {
  final void Function(String otp)? onCompleted;
  final void Function(String otp)? onChanged;

  const OtpTextform({
    super.key,
    this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpTextform> createState() => OtpTextformState();
}

class OtpTextformState extends State<OtpTextform> {
  static const int _length = 6;

  final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_length, (_) => FocusNode());

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Lifecycle
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  void initState() {
    super.initState();
    // أضف listener لكل focusNode لتحديث الـ fillColor
    for (final node in _focusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Methods
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  String getOtp() => _controllers.map((c) => c.text).join();

  void _onChanged(String value, int index) {
    final otp = _controllers.map((c) => c.text).join();

    // أرسل للـ Cubit في كل تغيير
    widget.onChanged?.call(otp);

    if (value.length == 1) {
      if (index < _length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        widget.onCompleted?.call(otp);
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Build
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Widget build(BuildContext context) {
    return Directionality(
       textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_length, (index) => _buildBox(index)),
      ),
    );
  }

  Widget _buildBox(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;

    return SizedBox(
      width: 46.w,
      height: 54.h,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
          color: MyColors.primary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          // ✅ ثلاث حالات للـ fillColor
          fillColor: isFilled
              ? MyColors.accentLight   // مكتوب
              : isFocused
                  ? MyColors.surface   // محدد فارغ
                  : MyColors.surfaceAlt, // فارغ عادي
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: MyColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: MyColors.accent,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: MyColors.error),
          ),
        ),
        onChanged: (value) {
          setState(() {}); // فقط لتحديث fillColor و isFilled
          _onChanged(value, index);
        },
      ),
    );
  }
}