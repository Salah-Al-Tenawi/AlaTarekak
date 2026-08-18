import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/features/trip_search/presantion/view/widget/empty_trips_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// نصوص القائمة الفارغة تتبع ما فعله المستخدم.
///
/// «غيّر التاريخ أو الموقع» نصيحة لا معنى لها لمن ضغط «بحث» بلا إدخال
/// شيء — لم يُدخل تاريخاً ولا موقعاً ليغيّره.

Future<void> _pump(WidgetTester tester, {required bool fromCity}) async {
  tester.view.physicalSize = const Size(390, 1200);
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
            body: SingleChildScrollView(
              child: EmptyTripsContent(fromCity: fromCity),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('نتيجة «رحلات مدينتي» الفارغة', () {
    testWidgets('عنوان ونصّ يخصّان المدينة', (tester) async {
      await _pump(tester, fromCity: true);

      expect(find.text('لا رحلات في مدينتك الآن'), findsOneWidget);
      expect(find.textContaining('تنطلق من مدينتك'), findsOneWidget);
    });

    testWidgets('لا نصيحة بتغيير تاريخ لم يُدخَل', (tester) async {
      await _pump(tester, fromCity: true);

      expect(find.textContaining('جرّب تاريخاً آخر'), findsNothing);
      expect(find.textContaining('وسّع نقطة الانطلاق'), findsNothing);
    });

    testWidgets('توجّهه إلى محافظته في «حسابي» — عليها تُبنى القائمة',
        (tester) async {
      await _pump(tester, fromCity: true);

      expect(find.textContaining('محافظتك'), findsOneWidget);
      expect(find.textContaining('حدّد مساراً وتاريخاً'), findsOneWidget);
    });
  });

  group('نتيجة البحث بمعايير الفارغة', () {
    testWidgets('النصّ الأصلي كما هو', (tester) async {
      await _pump(tester, fromCity: false);

      expect(find.text('لا توجد رحلات مطابقة'), findsOneWidget);
      expect(find.textContaining('جرّب تاريخاً آخر'), findsOneWidget);
      expect(find.textContaining('محافظتك'), findsNothing);
    });
  });
}
