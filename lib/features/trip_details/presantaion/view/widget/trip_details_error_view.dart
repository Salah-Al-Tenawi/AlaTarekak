import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/app_error_view.dart';

/// خطأ شاشة تفاصيل الرحلة — جلباً كان أو حجزاً.
///
/// **«أعد المحاولة» ليست الإجابة دائماً.** نقص الرصيد لا يزول بإعادة
/// الطلب: الطلب نفسه سيعود بالخطأ نفسه ما دام الرصيد كما هو. فالإجراء
/// الأول يصير «اشحن محفظتي» وينقل إلى المحفظة فعلاً، وتبقى الإعادة
/// ثانوية لمن شحن من مكان آخر وعاد.
///
/// ولا عنوان في الحالة العامة: رسائل `bookAset` جمل تامّة
/// («هذه الرحلة لم تعد متاحة للحجز») فعنوانٌ فوقها تكرار.
class TripDetailsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TripDetailsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final lowBalance = HandelErorrMessage.isInsufficientBalance(message);

    return AppErrorView(
      icon: lowBalance
          ? Icons.account_balance_wallet_outlined
          : Icons.error_outline_rounded,
      // نقص الرصيد حالة يعالجها المستخدم لا عطل — التحذيري أصدق من الأحمر
      accentColor: lowBalance ? MyColors.warning : MyColors.error,
      title: lowBalance ? 'رصيدك لا يكفي' : null,
      message: message,
      actionLabel: lowBalance ? 'اشحن محفظتي' : 'أعد المحاولة',
      onAction: lowBalance ? () => Get.toNamed(RouteName.wallet) : onRetry,
      secondaryLabel: lowBalance ? 'أعد المحاولة' : null,
      onSecondary: lowBalance ? onRetry : null,
    );
  }
}
