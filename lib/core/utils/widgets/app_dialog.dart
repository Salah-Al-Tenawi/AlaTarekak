import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

/// حوار بهوية التطبيق — بديل `AlertDialog` الخام.
///
/// كانت كل شاشة تبني حوارها بنفسها، فاختلف الشكل بينها: هذا بعنوان في
/// صفّ وأيقونة صغيرة إلى جانبه، وذاك بزرّي نصّ بلا وزن بصري، وثالث بزرّ
/// يمتدّ بعرض الحوار لأن الثيم يفرض `minimumSize: double.infinity` على
/// الأزرار — مناسب لأسفل نموذج، لا لحوار.
///
/// الشكل هنا واحد: أيقونة في هالة من لونها، ثم عنوان، ثم شرح، ثم إجراء
/// أو إجراءان متساويا العرض.
///
/// يعيد `true` عند التأكيد، و`false` أو `null` عند الإلغاء أو الإغلاق.
Future<bool?> showAppDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? message,
  Color? accentColor,

  /// نصّ زرّ الإجراء. تركه فارغاً يعرض زرّاً محايداً واحداً — لحالات لا
  /// يملك فيها المستخدم إجراءً (طلب قيد المراجعة مثلاً).
  String? confirmLabel,
  String cancelLabel = 'إلغاء',

  /// إجراء لا رجعة فيه: يُلوَّن باللون التحذيري ولا يُجعل الافتراضي بصرياً.
  bool destructive = false,
  bool barrierDismissible = true,

  /// محتوى يُعرض تحت الرسالة — بطاقة كلفة الإجراء مثلاً. النصّ وحده لا
  /// يكفي حين يكون للقرار ثمنٌ يُقرأ في سطرين ملوّنين.
  Widget? content,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => AppDialogContent(
      icon: icon,
      title: title,
      message: message,
      content: content,
      accentColor: accentColor,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );
}

class AppDialogContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Color? accentColor;

  /// محتوى تحت الرسالة — انظر [showAppDialog].
  final Widget? content;
  final String? confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const AppDialogContent({
    super.key,
    required this.icon,
    required this.title,
    required this.onConfirm,
    required this.onCancel,
    this.message,
    this.accentColor,
    this.confirmLabel,
    this.cancelLabel = 'إلغاء',
    this.destructive = false,
    this.content,
  });

  /// حدّ أعلى بالبكسل المنطقي لا `.w`: الغاية ألّا يتمدّد الحوار على
  /// الأجهزة العريضة، ولو قِيس مع الشاشة لتمدّد معها.
  static const double _maxWidth = 400;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? (destructive ? MyColors.error : MyColors.primary);

    return Dialog(
      backgroundColor: MyColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        // الوضع الأفقي وشاشات الهواتف القصيرة: المحتوى يمرّر بدل أن يفيض
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Halo(icon: icon, color: color),
                SizedBox(height: 18.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium,
                ),
                if (message != null && message!.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: MyColors.textSecondary,
                      height: 1.8,
                    ),
                  ),
                ],
                if (content != null) ...[
                  SizedBox(height: 14.h),
                  content!,
                ],
                SizedBox(height: 24.h),
                _Actions(
                  confirmLabel: confirmLabel,
                  cancelLabel: cancelLabel,
                  color: color,
                  onConfirm: onConfirm,
                  onCancel: onCancel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Halo({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76.w,
      height: 76.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.5),
      ),
      child: Icon(icon, size: 34.sp, color: color),
    );
  }
}

class _Actions extends StatelessWidget {
  final String? confirmLabel;
  final String cancelLabel;
  final Color color;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _Actions({
    required this.confirmLabel,
    required this.cancelLabel,
    required this.color,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final height = 48.h;
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r));

    // لا إجراء يملكه المستخدم: زرّ إغلاق واحد ممتدّ، فلا يبحث عن أيّهما
    // يضغط بين زرّين أحدهما بلا معنى.
    if (confirmLabel == null) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: onCancel,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: shape,
          ),
          child: const Text('حسناً'),
        ),
      );
    }

    return Row(
      children: [
        // الإلغاء أولاً في اتجاه القراءة (يمين في العربية) والإجراء بعده:
        // الأثقل أثراً لا يقع تحت الإبهام مباشرة.
        Expanded(
          child: SizedBox(
            height: height,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: MyColors.textSecondary,
                side: BorderSide(color: MyColors.border),
                shape: shape,
                // الثيم يفرض عرضاً ممتداً؛ داخل Expanded يكفي صفر
                minimumSize: Size(0, height),
                padding: EdgeInsets.symmetric(horizontal: 8.w),
              ),
              child: FittedBox(child: Text(cancelLabel)),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: SizedBox(
            height: height,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: shape,
                minimumSize: Size(0, height),
                padding: EdgeInsets.symmetric(horizontal: 8.w),
              ),
              // نصّ طويل («إعادة التقديم») على شاشة ضيّقة يُصغَّر ولا يُقصّ
              child: FittedBox(child: Text(confirmLabel!)),
            ),
          ),
        ),
      ],
    );
  }
}
