import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/them/my_colors.dart';

/// مؤشّر التحميل — **واحدٌ بشكلين، يختار بحسب المساحة**.
///
/// «الطريق» مرسوم بمقطع طريق كامل: حافّتان، وشرطات منتصف، وسيّارة بمقصورة
/// وأنف، ودبّوس وجهة ينبض عند الوصول. وذلك يحتاج مساحة — في مربّع من
/// اثنتين وعشرين نقطة تصير الشرطة بكسلاً والسيّارة ثلاثة، فيُقرأ الكلّ
/// لطخةً برتقالية.
///
/// فدونه [lottieThreshold] تُرسم **النسخة المصغّرة**: مضمار سميك وأثرٌ
/// وسيّارة كبيرة نسبةً إليه، وقد أُسقط منها ما لا يُرى. وهي مرسومة
/// بالأبيض ويُركَّب لونها بمرشّح، فتصلح فوق زرّ برتقالي وفوق سطح فاتح
/// بالملف نفسه.
///
/// وكان في التطبيق واحدٌ وثلاثون `CircularProgressIndicator` خامّاً، لكلٍّ
/// لونه وسماكته — فيختلف شكل الانتظار من زرّ إلى زرّ.
class AppLoader extends StatelessWidget {
  /// ضلع المربّع بالنقاط المنطقية.
  final double size;

  /// لون النسخة المصغّرة. الافتراضي لون الهوية، ويُمرَّر الأبيض فوق زرّ
  /// ممتلئ. لا أثر له على النسخة الكبيرة — تلك بألوان الهوية كلّها.
  final Color? color;

  const AppLoader({super.key, this.size = 88, this.color});

  /// داخل زرّ ممتلئ — مصغّرة وبيضاء.
  const AppLoader.onButton({super.key, this.color = Colors.white}) : size = 26;

  /// دون هذا الحدّ لا تُقرأ تفاصيل الطريق، فتُرسم النسخة المصغّرة.
  static const double lottieThreshold = 64;

  @override
  Widget build(BuildContext context) {
    final side = size.w;
    final isFull = size >= lottieThreshold;

    final Widget animation = Lottie.asset(
      isFull ? ImagesUrl.loadinglottie : ImagesUrl.loadinglottieMini,
      width: side,
      height: side,
      fit: BoxFit.contain,
    );

    return SizedBox(
      width: side,
      height: side,
      // المصغّرة بيضاء في ملفّها، فيُركَّب اللون عليها مع إبقاء الشفافية:
      // المضمار يبقى باهتاً والسيّارة صريحة، بلوّن واحد
      child: isFull
          ? animation
          : ColorFiltered(
              colorFilter: ColorFilter.mode(
                color ?? MyColors.accent,
                BlendMode.srcIn,
              ),
              child: animation,
            ),
    );
  }
}
