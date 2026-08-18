import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/features/trip_create/presantion/view/widget/price_ranking_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// إعلام السائق أن سعره يؤثّر في ترتيب ظهور رحلته.
///
/// كان يضع سعراً مرتفعاً ثم يتساءل لماذا لا تصله حجوزات — والنتائج
/// مرتَّبة لا معروضة كيفما اتفق. **إعلام لا منع**: السعر يبقى قراره.

const int _suggested = 270;

Future<void> _pump(WidgetTester tester, int price) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        theme: ThemApp.lightThem,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: PriceRankingHint(price: price, suggested: _suggested),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('الرسالة تتبع السعر', () {
    testWidgets('عند المقترح: موضع جيّد', (tester) async {
      await _pump(tester, _suggested);

      expect(find.textContaining('موضع جيّد'), findsOneWidget);
    });

    testWidgets('دون المقترح: موضع جيّد كذلك', (tester) async {
      await _pump(tester, 200);

      expect(find.textContaining('موضع جيّد'), findsOneWidget);
    });

    testWidgets('أعلى قليلاً: أثره محدود', (tester) async {
      await _pump(tester, 300); // +11٪

      expect(find.textContaining('أثره في الترتيب محدود'), findsOneWidget);
    });

    testWidgets('أعلى بربع: قد تظهر بعد غيرها', (tester) async {
      await _pump(tester, 340); // +26٪

      expect(find.textContaining('قد تظهر بعد'), findsOneWidget);
    });

    testWidgets('أعلى بكثير: آخر النتائج', (tester) async {
      await _pump(tester, 420); // +55٪

      expect(find.textContaining('آخر النتائج'), findsOneWidget);
    });
  });

  group('النبرة: إعلام لا منع', () {
    testWidgets('لا لغة منع ولا خطأ مهما ارتفع السعر', (tester) async {
      await _pump(tester, 440);

      expect(find.textContaining('خطأ'), findsNothing);
      expect(find.textContaining('لا يمكن'), findsNothing);
      expect(find.textContaining('ممنوع'), findsNothing);
    });

    testWidgets('العنوان يقول ما هو دون أمر', (tester) async {
      await _pump(tester, _suggested);

      expect(find.text('موضع رحلتك في نتائج البحث'), findsOneWidget);
    });
  });

  group('شرح المعايير', () {
    testWidgets('يُفتح بطلب السائق لا يُفرض عليه', (tester) async {
      await _pump(tester, _suggested);

      expect(find.byType(RankingCriteriaSheet), findsNothing);

      await tester.tap(find.text('ما المعايير؟'));
      await tester.pumpAndSettle();

      expect(find.byType(RankingCriteriaSheet), findsOneWidget);
    });

    testWidgets('يعرض المعايير كلها ومنها السعر', (tester) async {
      await _pump(tester, _suggested);
      await tester.tap(find.text('ما المعايير؟'));
      await tester.pumpAndSettle();

      expect(find.text('كيف تُرتَّب نتائج البحث؟'), findsOneWidget);
      for (final (_, title, _) in kSearchRankingCriteria) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('السعر'), findsOneWidget);
    });

    testWidgets('يذكّر أن السعر معيار من عدّة معايير', (tester) async {
      await _pump(tester, _suggested);
      await tester.tap(find.text('ما المعايير؟'));
      await tester.pumpAndSettle();

      expect(find.textContaining('معيار من عدّة معايير'), findsOneWidget);
    });
  });

  group('الحالات الحدّية', () {
    testWidgets('بلا مسافة (مقترح صفر) لا ينهار', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            theme: ThemApp.lightThem,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: const Scaffold(
                body: PriceRankingHint(price: 0, suggested: 0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('شاشة ضيّقة: بلا فيض', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pump(tester, 420);

      expect(tester.takeException(), isNull);
    });
  });
}
