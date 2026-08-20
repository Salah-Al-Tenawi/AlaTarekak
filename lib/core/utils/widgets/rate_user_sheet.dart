import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/trip_card_parts.dart';

/// ما خرج به المستخدم من ورقة التقييم.
class RateUserResult {
  final double rating;

  /// تعليق اختياري — `null` إن تُرك فارغاً.
  final String? comment;

  const RateUserResult({required this.rating, this.comment});
}

/// أقصى طول للتعليق. يطابق حدّ الخادم، ويُحرَس هنا فلا يُرفض بعد الإرسال.
const int kMaxCommentLength = 500;

/// ورقة تقييم شخص — **واحدة للطرفين**: الراكب يقيّم سائقه، والسائق يقيّم
/// راكبه.
///
/// كان التقييم حواراً مبنيّاً يدوياً بمقاسات ثابتة (`itemSize: 28.0`
/// و`const EdgeInsets`) لا تتبع الشاشة، ونجومه بلا تسمية تقول ماذا تعني
/// الثلاث من الخمس، وبلا موضع لتعليق — والمسار موجود في الخادم ولا يناديه
/// أحد.
///
/// وهي ورقة سفلية لا حواراً: التعليق حقل كتابة، ولوحة المفاتيح تغطّي
/// نصف الحوار المتوسّط بينما الورقة ترتفع فوقها.
class RateUserSheet extends StatefulWidget {
  /// اسم من يُقيَّم — يظهر في السؤال فلا يُقيَّم أحدٌ بالخطأ.
  final String name;

  final String? avatar;

  /// «كيف كانت رحلتك مع أحمد؟» للراكب، و«كيف كان أحمد راكباً؟» للسائق.
  final String question;

  const RateUserSheet({
    super.key,
    required this.name,
    required this.question,
    this.avatar,
  });

  /// يفتحها ويُعيد ما اختاره المستخدم — `null` إن أغلقها بلا إرسال.
  static Future<RateUserResult?> show(
    BuildContext context, {
    required String name,
    required String question,
    String? avatar,
  }) {
    return showModalBottomSheet<RateUserResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: MyColors.navy.withValues(alpha: 0.45),
      builder: (_) => RateUserSheet(
        name: name,
        question: question,
        avatar: avatar,
      ),
    );
  }

  @override
  State<RateUserSheet> createState() => _RateUserSheetState();
}

class _RateUserSheetState extends State<RateUserSheet> {
  final TextEditingController _comment = TextEditingController();
  double _rating = 0;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  /// ماذا تعني كل درجة — نجومٌ بلا كلمة تترك المستخدم يخمّن الفرق بين
  /// الثلاث والأربع، فيميل الجميع إلى الخمس ويفقد التقييم معناه.
  String get _ratingLabel => switch (_rating.round()) {
        1 => 'سيّئة',
        2 => 'مقبولة',
        3 => 'جيدة',
        4 => 'جيدة جداً',
        5 => 'ممتازة',
        _ => '',
      };

  Color get _ratingColor => switch (_rating.round()) {
        1 || 2 => MyColors.error,
        3 => MyColors.warning,
        _ => MyColors.success,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      // لوحة المفاتيح ترفع الورقة بدل أن تغطّي حقل التعليق
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: MyColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _grabHandle(),
                SizedBox(height: 14.h),
                TripAvatar(avatar: widget.avatar, size: 64),
                SizedBox(height: 12.h),
                Text(
                  widget.question,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 16.sp),
                ),
                SizedBox(height: 18.h),
                _stars(),
                SizedBox(height: 8.h),
                _ratingCaption(),
                SizedBox(height: 18.h),
                _commentField(),
                SizedBox(height: 18.h),
                _actions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grabHandle() => Container(
        width: 44.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: MyColors.border,
          borderRadius: BorderRadius.circular(4.r),
        ),
      );

  Widget _stars() {
    return RatingBar.builder(
      initialRating: 0,
      minRating: 1,
      direction: Axis.horizontal,
      // **بلا أنصاف**: خمس درجات مسمّاة أوضح من عشر بلا أسماء، والنصف
      // على شاشة لمس يقع سهواً أكثر ممّا يُقصد.
      allowHalfRating: false,
      itemCount: 5,
      itemSize: 40.sp,
      glow: false,
      itemPadding: EdgeInsets.symmetric(horizontal: 4.w),
      unratedColor: MyColors.border,
      itemBuilder: (context, _) =>
          Icon(Icons.star_rounded, color: MyColors.warning),
      onRatingUpdate: (value) => setState(() => _rating = value),
    );
  }

  /// مساحة التسمية محجوزة سلفاً فلا يقفز ما تحتها عند أول نجمة.
  Widget _ratingCaption() => SizedBox(
        height: 22.h,
        child: Center(
          child: Text(
            _ratingLabel,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: _ratingColor,
            ),
          ),
        ),
      );

  Widget _commentField() {
    return TextField(
      controller: _comment,
      maxLines: 3,
      minLines: 2,
      maxLength: kMaxCommentLength,
      textInputAction: TextInputAction.newline,
      style: TextStyle(fontSize: 13.5.sp, color: MyColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'أضف تعليقاً (اختياري)',
        hintStyle: TextStyle(fontSize: 13.sp, color: MyColors.textHint),
        // العدّاد يظهر مع الكتابة لا قبلها — «0/500» فوق حقل فارغ ضجيج
        counterText: '',
        filled: true,
        fillColor: MyColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
          borderSide: BorderSide(color: MyColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _actions() {
    final canSubmit = _rating > 0;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48.h,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: MyColors.textSecondary,
                side: BorderSide(color: MyColors.border, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text('لاحقاً',
                  style: TextStyle(
                      fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48.h,
            child: ElevatedButton(
              // **معطّل حتى تُختار نجمة**: زرٌّ يُضغط فلا يحدث شيء كان
              // يبدو عطلاً، والتقييم بلا درجة لا معنى له.
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.accent,
                foregroundColor: MyColors.textOnDark,
                disabledBackgroundColor:
                    MyColors.accent.withValues(alpha: 0.30),
                disabledForegroundColor:
                    MyColors.textOnDark.withValues(alpha: 0.75),
                elevation: canSubmit ? 2 : 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text(
                'إرسال التقييم',
                style:
                    TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    final text = _comment.text.trim();
    Navigator.of(context).pop(RateUserResult(
      rating: _rating,
      comment: text.isEmpty ? null : text,
    ));
  }
}
