import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/them/my_colors.dart';

/// مؤشّر التحميل — **واحدٌ بشكلين، يختار بحسب المساحة**.
///
/// مؤشّر «الطريق» مرسوم بمقطع طريق وسيّارة وعلامة وجهة، وذلك يحتاج
/// مساحة: في مربّع من اثنتين وعشرين نقطة تصير السيّارة أربع بكسلات
/// والشرطات نقاطاً — فيبدو حلقةً برتقالية مشوّشة، وهو أسوأ من دوّار
/// نظيف. فدونه حدٌّ يُرسم تحته دوّارٌ بلون الهوية.
///
/// وكان في التطبيق واحدٌ وثلاثون `CircularProgressIndicator` خامّاً، لكلٍّ
/// لونه وسماكته — فيختلف شكل الانتظار من زرّ إلى زرّ.
class AppLoader extends StatelessWidget {
  /// ضلع المربّع بالنقاط المنطقية.
  final double size;

  /// لون الدوّار حين يكون الحجم دون الحدّ. الافتراضي لون الهوية،
  /// ويُمرَّر الأبيض فوق زرّ ممتلئ.
  final Color? color;

  const AppLoader({super.key, this.size = 150, this.color});

  /// دوّار داخل زرّ ممتلئ — أبيض وصغير.
  const AppLoader.onButton({super.key})
      : size = 22,
        color = Colors.white;

  /// دون هذا الحدّ لا تُقرأ تفاصيل الطريق، فيُرسم الدوّار.
  static const double lottieThreshold = 64;

  @override
  Widget build(BuildContext context) {
    final side = size.w;

    if (size >= lottieThreshold) {
      return SizedBox(
        width: side,
        height: side,
        child: Lottie.asset(
          ImagesUrl.loadinglottie,
          width: side,
          height: side,
          fit: BoxFit.contain,
        ),
      );
    }

    // السماكة تتبع الحجم فلا تبدو خيطاً على دائرة كبيرة ولا حلقة على صغيرة
    return SizedBox(
      width: side,
      height: side,
      child: CircularProgressIndicator(
        strokeWidth: (side / 11).clamp(2.0, 4.0),
        color: color ?? MyColors.accent,
      ),
    );
  }
}
