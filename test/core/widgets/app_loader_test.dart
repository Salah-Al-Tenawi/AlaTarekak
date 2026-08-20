import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// مؤشّر التحميل — واحدٌ بشكلين، يختار بحسب المساحة.
///
/// مؤشّر «الطريق» مرسوم بمقطع طريق وسيّارة وعلامة وجهة، وذلك يحتاج مساحة:
/// في مربّع صغير تصير السيّارة أربع بكسلات فيبدو حلقةً مشوّشة، وهو أسوأ
/// من دوّار نظيف.
///
/// وكان في التطبيق واحد وثلاثون `CircularProgressIndicator` خامّاً لكلٍّ
/// لونه وسماكته — فيختلف شكل الانتظار من زرّ إلى زرّ.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    // مقاس التصميم نفسه: عندها يكون 1 منطقي = 1 فيزيائي في ScreenUtil،
    // فتُقرأ المقاسات بالأرقام التي كُتبت بها
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(home: Scaffold(body: Center(child: child))),
      ),
    );
    await tester.pump();
  }

  group('يختار الشكل بحسب الحجم', () {
    testWidgets('الحجم الكبير: الطريق بكامل تفاصيله', (tester) async {
      await pump(tester, const AppLoader(size: 150));

      expect(find.byType(LottieBuilder), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('وعند الحدّ تماماً: الطريق أيضاً', (tester) async {
      await pump(tester, const AppLoader(size: AppLoader.lottieThreshold));

      expect(find.byType(LottieBuilder), findsOneWidget);
    });

    testWidgets('دون الحدّ: دوّار — الطريق لا يُقرأ في هذه المساحة',
        (tester) async {
      await pump(tester, const AppLoader(size: 32));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LottieBuilder), findsNothing);
    });
  });

  group('الدوّار داخل الزرّ', () {
    testWidgets('أبيض — فوق زرّ ممتلئ بلون الهوية', (tester) async {
      await pump(tester, const AppLoader.onButton());

      final spinner = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));
      expect(spinner.color, Colors.white);
    });

    testWidgets('وحجمه لا يطغى على الزرّ', (tester) async {
      await pump(tester, const AppLoader.onButton());

      final box = tester.getSize(find.byType(CircularProgressIndicator));
      expect(box.width, lessThan(30));
    });

    testWidgets('والافتراضي بلون الهوية لا بلون الثيم', (tester) async {
      await pump(tester, const AppLoader(size: 30));

      final spinner = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));
      expect(spinner.color, MyColors.accent);
    });

    testWidgets('السماكة تتبع الحجم — لا خيط على دائرة ولا حلقة على نقطة',
        (tester) async {
      await pump(tester, const AppLoader(size: 16));
      final thin = tester
          .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator))
          .strokeWidth!;

      await pump(tester, const AppLoader(size: 60));
      final thick = tester
          .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator))
          .strokeWidth!;

      expect(thick, greaterThan(thin));
      expect(thin, greaterThanOrEqualTo(2.0));
      expect(thick, lessThanOrEqualTo(4.0));
    });
  });

  testWidgets('مؤشّر الشاشة الكاملة يفوّض إلى اللبنة نفسها', (tester) async {
    await pump(tester, const LoadingWidgetSize150());

    expect(find.byType(AppLoader), findsOneWidget);
    expect(find.byType(LottieBuilder), findsOneWidget,
        reason: 'مئة وخمسون نقطة فوق الحدّ — الطريق يُرسم');
  });
}
