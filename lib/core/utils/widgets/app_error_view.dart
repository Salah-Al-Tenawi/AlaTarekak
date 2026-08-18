import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

/// رسالة خطأ بهوية التطبيق — بديل `Text("خطأ: …")` مع زرّ عارٍ.
///
/// **لماذا مكوّن مشترك:** كانت كل شاشة تصوغ خطأها بنفسها، فاختلفت
/// الألوان والمسافات وأحجام الأزرار بين شاشة وأخرى، وظهر في بعضها
/// `Colors.grey[200]` و`Colors.red` الخام لا ألوان الهوية.
///
/// **عرض الأزرار:** ثيم التطبيق يفرض `minimumSize: Size(double.infinity, 52)`
/// على `ElevatedButton` و`OutlinedButton` — مناسب لزرّ «تسجيل الدخول» في
/// أسفل نموذج، وغير مناسب إطلاقاً لزرّ «أعد المحاولة» وسط رسالة، حيث
/// يمتدّ من حافة إلى حافة فيبتلع الرسالة نفسها. نلغيه هنا محلياً.
///
/// **الاستجابة للقياس:** المحتوى محصور بعرض أقصى فلا يتمدّد على الأجهزة
/// العريضة، وقابل للتمرير فلا يفيض في الوضع الأفقي أو على الشاشات
/// القصيرة، والزرّان في `Wrap` فينزل الثاني تحت الأول حين يضيق العرض.
class AppErrorView extends StatelessWidget {
  final IconData icon;

  /// سطر عنوان قصير فوق الرسالة — يُغني عن بادئة «خطأ:».
  final String? title;

  final String message;

  final String? actionLabel;
  final VoidCallback? onAction;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// لون الأيقونة وهالتها. الأحمر ليس دائماً الصحيح: نقص الرصيد حالة
  /// يعالجها المستخدم لا عطل، فالتحذيري أصدق منه.
  final Color? accentColor;

  const AppErrorView({
    super.key,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.title,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.accentColor,
  });

  /// أقصى عرض للمحتوى بالبكسل المنطقي — رقم ثابت لا `.w`: الغاية حدّ
  /// أعلى على الأجهزة العريضة، ولو تُرك ليتمدّد مع القياس لتمدّد معه.
  static const double _maxContentWidth = 420;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? MyColors.error;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: _maxContentWidth),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Halo(icon: icon, color: color),
                      SizedBox(height: 20.h),
                      if (title != null) ...[
                        Text(
                          title!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium,
                        ),
                        SizedBox(height: 8.h),
                      ],
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: MyColors.textSecondary,
                          height: 1.7,
                        ),
                      ),
                      if (onAction != null || onSecondary != null)
                        SizedBox(height: 24.h),
                      _Actions(
                        actionLabel: actionLabel,
                        onAction: onAction,
                        secondaryLabel: secondaryLabel,
                        onSecondary: onSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// الأيقونة داخل هالة دائرية من لونها — نفس لغة البطاقات في التطبيق.
class _Halo extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Halo({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92.w,
      height: 92.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.5),
      ),
      child: Icon(icon, size: 42.sp, color: color),
    );
  }
}

class _Actions extends StatelessWidget {
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _Actions({
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (actionLabel != null && onAction != null)
        ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            // يلغي عرض الثيم الممتد — انظر شرح AppErrorView
            minimumSize: Size(0, 46.h),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(actionLabel!),
        ),
      if (secondaryLabel != null && onSecondary != null)
        OutlinedButton(
          onPressed: onSecondary,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, 46.h),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(secondaryLabel!),
        ),
    ];

    if (buttons.isEmpty) return const SizedBox.shrink();

    // Wrap لا Row: زرّان بنصّين طويلين على شاشة ضيّقة يفيضان في Row،
    // وهنا ينزل الثاني تحت الأول من تلقائه.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12.w,
      runSpacing: 10.h,
      children: buttons,
    );
  }
}
