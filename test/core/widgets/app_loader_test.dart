import 'dart:ui' as ui;

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// مؤشّر التحميل — واحدٌ بشكلين، يختار بحسب المساحة.
///
/// «الطريق» بتفاصيله — حافّتان وشرطات ودبّوس وجهة — يحتاج مساحة: في مربّع
/// من ستٍّ وعشرين نقطة تصير الشرطة بكسلاً والسيّارة ثلاثة، فيُقرأ لطخةً.
/// فدون الحدّ تُرسم نسخة مصغّرة أُسقط منها ما لا يُرى.
///
/// **وملفّات Lottie تفشل صامتة**: يُقبل الملف ويُبنى الودجت ثم لا يُرسم
/// شيء. فلا يكفي وجود [LottieBuilder] في الشجرة — تُقرأ البكسلات.
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
      expect(find.byType(ColorFiltered), findsNothing,
          reason: 'الكبيرة بألوان الهوية كما رُسمت — لا تُلوَّن');
    });

    testWidgets('وعند الحدّ تماماً: الطريق أيضاً', (tester) async {
      await pump(tester, const AppLoader(size: AppLoader.lottieThreshold));

      expect(find.byType(ColorFiltered), findsNothing);
    });

    testWidgets('دون الحدّ: المصغّرة — لا دوّار عامّ', (tester) async {
      await pump(tester, const AppLoader(size: 32));

      expect(find.byType(LottieBuilder), findsOneWidget,
          reason: 'الطريق باقٍ هويّةً وإن صغر');
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ColorFiltered), findsOneWidget);
    });
  });

  group('داخل الزرّ', () {
    testWidgets('أبيض — فوق زرّ ممتلئ بلون الهوية', (tester) async {
      await pump(tester, const AppLoader.onButton());

      final filtered =
          tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(filtered.colorFilter,
          const ColorFilter.mode(Colors.white, BlendMode.srcIn));
    });

    testWidgets('وحجمه لا يطغى على الزرّ', (tester) async {
      await pump(tester, const AppLoader.onButton());

      final box = tester.getSize(find.byType(AppLoader));
      expect(box.width, lessThan(30));
    });

    testWidgets('ولون آخر حين يكون الزرّ فاتحاً', (tester) async {
      await pump(tester, AppLoader.onButton(color: MyColors.primary));

      final filtered =
          tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(filtered.colorFilter,
          ColorFilter.mode(MyColors.primary, BlendMode.srcIn));
    });

    testWidgets('والافتراضي دون الحدّ بلون الهوية لا بلون الثيم',
        (tester) async {
      await pump(tester, const AppLoader(size: 30));

      final filtered =
          tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(filtered.colorFilter,
          ColorFilter.mode(MyColors.accent, BlendMode.srcIn));
    });
  });

  group('الملفّان يُرسمان فعلاً', () {
    /// يرسم الودجت ثم يقرأ بكسلاته — الفحص الوحيد الذي لا يخدعه ملفّ
    /// Lottie مقبولٌ شكلاً لا يُنتج صورة.
    Future<({int painted, int green, int neutral})> paintCount(
      WidgetTester tester,
      Widget child,
      double side,
    ) async {
      final key = GlobalKey();

      tester.view.physicalSize = Size(side, side);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: Container(color: Colors.black, child: Center(child: child)),
          ),
        ),
      );

      var painted = 0;
      var green = 0;
      var neutral = 0;

      // مهلة حقيقية: تحميل الملف من الحزمة وفكّ ترميزه لا يجريان في
      // الزمن المزيّف، ثم `toImage` نفسها تحتاج إطاراً حقيقياً
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

        for (var i = 0; i < bytes!.lengthInBytes; i += 4) {
          final r = bytes.getUint8(i);
          final g = bytes.getUint8(i + 1);
          final b = bytes.getUint8(i + 2);

          // الأرضية سوداء: أي بكسل غيرها رسمَه المؤشّر
          if (r + g + b > 24) {
            painted++;

            // المضمار مرسوم بشفافية، فيخرج فوق السواد أخضر خافتاً لا
            // مشبعاً — المهم أن الأخضر يغلب، لا أن يبلغ حدّه
            if (g > r + 20 && g > b + 20) green++;

            // رمادي: القنوات الثلاث متساوية — أي أبيضُ الملف كما هو
            if ((r - g).abs() < 8 && (g - b).abs() < 8) neutral++;
          }
        }
        image.dispose();
      });

      return (painted: painted, green: green, neutral: neutral);
    }

    testWidgets('الكبيرة ترسم طريقاً — لا لوحة فارغة', (tester) async {
      final result = await paintCount(tester, const AppLoader(size: 150), 200);

      expect(result.painted, greaterThan(1200),
          reason: 'ملف Lottie لا يُنتج صورة يمرّ من كل فحص إلا هذا');
    });

    testWidgets('والمصغّرة ترسم في ستٍّ وعشرين نقطة', (tester) async {
      final result = await paintCount(tester, const AppLoader.onButton(), 40);

      expect(result.painted, greaterThan(120),
          reason: 'لو ضاعت في هذا المقاس لكان الزرّ ينتظر بلا مؤشّر');
    });

    testWidgets('واللون يُركَّب عليها — أبيضها ليس مصيرها', (tester) async {
      final result = await paintCount(
        tester,
        const AppLoader.onButton(color: Color(0xFF00FF00)),
        40,
      );

      expect(result.green, greaterThan(result.painted ~/ 2),
          reason: 'الأخضر يغلب على ما رُسم');
      expect(result.neutral, lessThan(result.painted ~/ 20),
          reason: 'ولا يبقى أبيض الملف — المرشّح بدّله ولم يطمس شفافيته');
    });
  });
}
