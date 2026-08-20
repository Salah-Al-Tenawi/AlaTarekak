import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/notification_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// أين يذهب المستخدم حين يضغط إشعار غياب.
///
/// الوجهات الثلاث الجديدة، ولكلٍّ سببها:
///
///   بلاغ عنك / حُسم لصالحك  →  الرحلة، أو «حجوزاتي» إن لم يصل `ride_id`
///   تعارض                    →  **قائمة** الشكاوى لا الشكوى بعينها
///
/// التعارض يصل **للطرفين** بالاسم نفسه وبرقم الشكوى نفسه، ولا حقل يقول
/// أيّهما أنت. والشكوى تُنسب إلى الراكب وحده فيجلبها السائق بـ 404 —
/// أي رسالة «الشكوى غير موجودة» في وجه من أخبرناه للتوّ أن شكوى فُتحت.
void main() {
  late List<String> visited;

  setUp(() {
    visited = [];
    Get.testMode = true;
  });

  /// يشغّل الموجِّه داخل تطبيق يسجّل المسار الذي انتُقل إليه.
  Future<void> tap(
    WidgetTester tester, {
    required String type,
    Map<String, dynamic> data = const {},
  }) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: const SizedBox.shrink(),
        onGenerateRoute: (settings) {
          visited.add(settings.name ?? '');
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        },
      ),
    );

    await NotificationRouter.open(type: type, category: 'ride', data: data);
    await tester.pumpAndSettle();
  }

  group('التعارض → قائمة الشكاوى لا الشكوى بعينها', () {
    testWidgets('ولو وصل رقم الشكوى', (tester) async {
      await tap(
        tester,
        type: 'noshow_conflict',
        data: {'ride_id': 5, 'complaint_id': 91},
      );

      expect(visited, contains(RouteName.complaintList));
      expect(visited, isNot(contains(RouteName.complaintDetail)),
          reason: 'السائق يجلبها بـ 404 — والموجِّه لا يعرف أيّ طرف يضغط');
      expect(visited, isNot(contains(RouteName.tripDetails)));
    });
  });

  group('بلاغ عنك → الرحلة', () {
    testWidgets('السائق أبلغ عن غياب الراكب', (tester) async {
      await tap(
        tester,
        type: 'noshow_driver_reported_you',
        data: {'ride_id': 5, 'booking_id': 7},
      );

      expect(visited, contains(RouteName.tripDetails));
    });

    testWidgets('الراكب أبلغ عن غياب السائق', (tester) async {
      await tap(
        tester,
        type: 'noshow_passenger_reported_you',
        data: {'ride_id': 5, 'report_id': 3},
      );

      expect(visited, contains(RouteName.tripDetails));
    });
  });

  group('حجز بلا رحلة → «حجوزاتي»', () {
    testWidgets('«حُسم لصالحك» لا يحمل إلا رقم الحجز', (tester) async {
      // كان يسقط إلى «لا وجهة معروفة» فلا يحدث شيء عند الضغط
      await tap(
        tester,
        type: 'noshow_resolved_in_your_favor',
        data: {'booking_id': 7},
      );

      expect(visited, contains(RouteName.bookingMeList));
    });

    testWidgets('والرحلة تُقدَّم حين تصل معه', (tester) async {
      await tap(
        tester,
        type: 'noshow_penalty_applied',
        data: {'ride_id': 5, 'booking_id': 7},
      );

      expect(visited, contains(RouteName.tripDetails));
      expect(visited, isNot(contains(RouteName.bookingMeList)));
    });
  });

  testWidgets('حمولة فارغة لا تنقل ولا ترمي', (tester) async {
    await tap(tester, type: 'noshow_penalty_applied');

    expect(visited, isEmpty);
  });
}
