import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_did_you_back.dart';
import 'package:alatarekak/features/trip_create/presantion/view/widget/trip_did_you_back_text_and_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// شاشة نجاح إنشاء الرحلة.
///
/// كانت حالة رحلة العودة زرّاً فيه صورة سيارة **بلا نصّ**، وكانت الشاشة
/// لا تعرض شيئاً عمّا نُشر. وكان قلب المسار يُقلب الإحداثيات ويترك
/// العنوانين على حالهما.

TripFrom _trip({bool reverse = false}) => TripFrom(
      startLat: '33.51',
      startLng: '36.29',
      endLat: '34.73',
      endLng: '36.71',
      startName: 'دمشق',
      endName: 'حمص',
      date: '2026-09-20 14:30:00',
      numberSeats: 3,
      price: 25000,
      reverseTripRoute: reverse,
    );

/// الشاشة تقرأ `Get.arguments`، ويُمرَّر عبر التوجيه لا عبر المُنشئ.
Future<void> _pumpWithArgs(WidgetTester tester, TripFrom? trip) async {
  Get.testMode = true;
  // سطح بمقاس هاتف حقيقي: الافتراضي 800×600 يضخّم كل `.sp` بمقدار ٢.١٣
  // لأن designSize هو 375، فتظهر فيوضات لا وجود لها على جهاز فعلي
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      child: GetMaterialApp(
        initialRoute: '/success',
        getPages: [
          GetPage(name: '/success', page: () => const TripDidYouBack()),
          // بالأسماء الحقيقية: الشاشة تنتقل إليها فعلاً عند الضغط
          GetPage(
              name: RouteName.tripSelectDateAndSeats,
              page: () => const Scaffold(body: Text('شاشة الموعد'))),
          GetPage(
              name: RouteName.home,
              page: () => const Scaffold(body: Text('الرئيسية'))),
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pump();
  Get.offAllNamed('/success', arguments: trip);
  await tester.pumpAndSettle(const Duration(milliseconds: 600));
}

void main() {
  group('حالة رحلة الذهاب — عرض إنشاء العودة', () {
    testWidgets('تعرض تأكيد النشر وملخص الرحلة', (tester) async {
      await _pumpWithArgs(tester, _trip());

      expect(find.text('تم نشر رحلتك بنجاح'), findsOneWidget);
      expect(find.text('ملخص رحلتك'), findsOneWidget);
      expect(find.text('دمشق'), findsOneWidget);
      expect(find.text('حمص'), findsOneWidget);
      expect(find.text('الانطلاق'), findsOneWidget);
      expect(find.text('الوجهة'), findsOneWidget);
    });

    testWidgets('الموعد والمقاعد والسعر تظهر', (tester) async {
      await _pumpWithArgs(tester, _trip());

      expect(find.textContaining('أيلول'), findsOneWidget);
      expect(find.text('02:30 م'), findsOneWidget);
      expect(find.text('3 مقاعد'), findsOneWidget);
      expect(find.text('25,000 ل.س / راكب'), findsOneWidget);
    });

    testWidgets('السؤال وزرّاه بنصوص واضحة', (tester) async {
      await _pumpWithArgs(tester, _trip());

      expect(find.text('هل ترغب بإنشاء رحلة للعودة؟'), findsOneWidget);
      expect(find.text('نعم، أنشئ رحلة العودة'), findsOneWidget);
      expect(find.text('لا شكراً، إلى الرئيسية'), findsOneWidget);
    });

    testWidgets('الضغط على «نعم» يقلب العناوين والإحداثيات معاً',
        (tester) async {
      final trip = _trip();
      await _pumpWithArgs(tester, trip);

      // الزرّ أسفل الطيّة على شاشة الهاتف — يُمرَّر إليه قبل النقر
      await tester.ensureVisible(find.text('نعم، أنشئ رحلة العودة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('نعم، أنشئ رحلة العودة'));
      await tester.pump();

      expect(trip.startName, 'حمص', reason: 'العنوان لم يُقلب');
      expect(trip.endName, 'دمشق', reason: 'العنوان لم يُقلب');
      expect(trip.startLat, '34.73');
      expect(trip.endLat, '33.51');
      expect(trip.reverseTripRoute, isTrue);
    });
  });

  group('حالة رحلة العودة — لا سيارة بلا نصّ', () {
    testWidgets('تعرض تأكيداً خاصاً بالعودة وزرّاً مكتوباً', (tester) async {
      await _pumpWithArgs(tester, _trip(reverse: true));

      expect(find.text('تم نشر رحلة العودة'), findsOneWidget);
      expect(find.text('رحلتان منشورتان'), findsOneWidget);
      expect(find.text('رحلة العودة'), findsOneWidget);
      expect(find.text('العودة إلى الرئيسية'), findsOneWidget);
    });

    testWidgets('لا يظهر عرض إنشاء عودة ثانية', (tester) async {
      await _pumpWithArgs(tester, _trip(reverse: true));

      expect(find.text('هل ترغب بإنشاء رحلة للعودة؟'), findsNothing);
      expect(find.byType(TripDidYouBackTextAndButtons), findsNothing);
    });

    testWidgets('الملخص ما زال معروضاً', (tester) async {
      await _pumpWithArgs(tester, _trip(reverse: true));
      expect(find.text('3 مقاعد'), findsOneWidget);
    });
  });

  group('متانة الشاشة', () {
    testWidgets('وسيط غائب لا يُسقط شاشة النجاح', (tester) async {
      await _pumpWithArgs(tester, null);

      expect(tester.takeException(), isNull);
      expect(find.text('العودة إلى الرئيسية'), findsOneWidget);
    });

    testWidgets('تاريخ غير صالح يُخفي رقاقة الموعد بلا انهيار',
        (tester) async {
      final trip = _trip()..date = 'غير-صالح';
      await _pumpWithArgs(tester, trip);

      expect(tester.takeException(), isNull);
      expect(find.text('3 مقاعد'), findsOneWidget);
    });

    testWidgets('صفر مقاعد يُصاغ نصاً لا رقماً عارياً', (tester) async {
      final trip = _trip()..numberSeats = 0;
      await _pumpWithArgs(tester, trip);
      expect(find.text('المقاعد غير محدّدة'), findsOneWidget);
    });
  });
}
