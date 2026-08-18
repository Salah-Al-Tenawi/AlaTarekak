import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/features/trip_search/presantion/view/widget/empty_trips_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «لا توجد رحلات» بعد بحث فارغ.
///
/// **بحث فارغ ليس خطأً**: الرحلة قد لا تكون أُنشئت بعد. فالنبرة اقتراح لا
/// اعتذار، والاقتراحات محدّدة (تاريخ آخر، موقع أقرب، معاودة لاحقاً) لا
/// جملة عامة واحدة، ومعها سبيل للعودة إلى معايير البحث.

Future<void> _pump(
  WidgetTester tester, {
  bool compact = false,
  VoidCallback? onAdjust,
  Size screen = const Size(390, 844),
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: screen,
      builder: (context, _) => MaterialApp(
        theme: ThemApp.lightThem,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: EmptyTripsContent(
                  compact: compact,
                  onAdjustSearch: onAdjust,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('المحتوى', () {
    testWidgets('عنوان وشرح واقتراحات ثلاثة', (tester) async {
      await _pump(tester);

      expect(find.text('لا توجد رحلات مطابقة'), findsOneWidget);
      expect(find.textContaining('لم يُنشئ أحد رحلة'), findsOneWidget);
      expect(find.textContaining('تاريخاً آخر'), findsOneWidget);
      expect(find.textContaining('مدينة قريبة'), findsOneWidget);
      expect(find.textContaining('تُضاف رحلات يومياً'), findsOneWidget);
    });

    testWidgets('لا نبرة اعتذار ولا لغة خطأ', (tester) async {
      await _pump(tester);

      expect(find.textContaining('خطأ'), findsNothing);
      expect(find.textContaining('عذر'), findsNothing);
    });
  });

  group('زرّ تعديل البحث', () {
    testWidgets('يظهر ويعمل حين يُمرَّر', (tester) async {
      var tapped = 0;
      await _pump(tester, onAdjust: () => tapped++);

      expect(find.text('عدّل البحث'), findsOneWidget);
      await tester.tap(find.text('عدّل البحث'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('لا يظهر حين لا إجراء', (tester) async {
      await _pump(tester);
      expect(find.text('عدّل البحث'), findsNothing);
    });

    testWidgets('لا يمتدّ بعرض الشاشة رغم الثيم', (tester) async {
      const screen = Size(390, 844);
      await _pump(tester, onAdjust: () {}, screen: screen);

      // ElevatedButton.icon يبني صنفاً مشتقّاً، وfind.byType يطابق النوع
      // بالضبط — فالبحث بالمُسنِد لا بالنوع
      final button = find.byWidgetPredicate((w) => w is ElevatedButton);
      final width = tester.getSize(button).width;

      expect(width, lessThan(screen.width * 0.7));
    });
  });

  group('الاستجابة للقياس', () {
    testWidgets('شاشة ضيّقة: بلا فيض', (tester) async {
      await _pump(tester, screen: const Size(320, 640), onAdjust: () {});
      expect(tester.takeException(), isNull);
    });

    testWidgets('وضع أفقي: بلا فيض', (tester) async {
      await _pump(tester, screen: const Size(740, 360), onAdjust: () {});
      expect(tester.takeException(), isNull);
    });

    testWidgets('شاشة عريضة: النصّ محصور لا يمتدّ', (tester) async {
      await _pump(tester, screen: const Size(1200, 900));

      final width =
          tester.getSize(find.textContaining('لم يُنشئ أحد رحلة')).width;
      expect(width, lessThanOrEqualTo(380));
    });

    testWidgets('النسخة المضغوطة (داخل الحوار) تعرض المحتوى نفسه',
        (tester) async {
      await _pump(tester, compact: true, onAdjust: () {});

      expect(find.text('لا توجد رحلات مطابقة'), findsOneWidget);
      expect(find.text('عدّل البحث'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
