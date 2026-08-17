import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/notification_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// وجهة الإشعار عند الضغط عليه.
///
/// للإشعار مدخلان: بطاقة في قائمة الإشعارات، وإشعار نظام من Firebase يصل
/// والتطبيق في الخلفية أو مغلق. كان لكل مدخل توجيهه — القائمة تفتح
/// المحادثة والشكوى والرحلة، وFCM يفتح المحادثة **وحدها** فيضغط المستخدم
/// إشعار «قُبل حجزك» أو «رُدَّ على شكواك» فلا يحدث شيء.

/// وجهة وهمية تلتقط ما نُقل إليه بدل بناء الشاشات الحقيقية.
class _Recorder extends NavigatorObserver {
  final List<String> routes = [];
  final List<Object?> arguments = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) {
      routes.add(name);
      arguments.add(route.settings.arguments);
    }
    super.didPush(route, previousRoute);
  }
}

void main() {
  late _Recorder recorder;

  setUp(() {
    recorder = _Recorder();
    Get.testMode = true;
  });

  /// يبني تطبيقاً بمسارات فارغة يسجّل الانتقالات إليها.
  Future<void> pumpApp(WidgetTester tester) async {
    Widget blank(String name) => Scaffold(body: Text(name));

    await tester.pumpWidget(
      GetMaterialApp(
        navigatorObservers: [recorder],
        home: const Scaffold(body: SizedBox.shrink()),
        getPages: [
          for (final name in const [
            RouteName.chatScreen,
            RouteName.chatListScreen,
            RouteName.tripDetails,
            RouteName.complaintDetail,
          ])
            GetPage(name: name, page: () => blank(name)),
        ],
      ),
    );
    await tester.pump();
    // مسار الجذر يُدفع عند الإقلاع — لا يعنينا، نبدأ العدّ بعده
    recorder.routes.clear();
    recorder.arguments.clear();
  }

  Future<void> openPush(
      WidgetTester tester, Map<String, dynamic> data) async {
    await NotificationRouter.openFromPush(data);
    await tester.pumpAndSettle();
  }

  group('حمولة FCM — كل قيمها نصوص', () {
    testWidgets('conversation_id نصاً يفتح المحادثة', (tester) async {
      await pumpApp(tester);
      // FCM يُسطّح الحمولة إلى نصوص دائماً، ولو أُرسل الحقل رقماً
      await openPush(tester, {'conversation_id': '42', 'title': 'أحمد'});

      expect(recorder.routes, contains(RouteName.chatScreen));
      final args = recorder.arguments.last as Map;
      expect(args['conversationId'], 42, reason: 'يُقرأ رقماً لا نصاً');
      expect(args['title'], 'أحمد');
    });

    testWidgets('complaint_id يفتح تفاصيل الشكوى — كان يُتجاهل في FCM',
        (tester) async {
      await pumpApp(tester);
      await openPush(tester, {'complaint_id': '7'});

      expect(recorder.routes, contains(RouteName.complaintDetail));
      expect(recorder.arguments.last, 7);
    });

    testWidgets('ride_id يفتح تفاصيل الرحلة — كان يُتجاهل في FCM',
        (tester) async {
      await pumpApp(tester);
      await openPush(tester, {'ride_id': '13'});

      expect(recorder.routes, contains(RouteName.tripDetails));
      expect(recorder.arguments.last, 13);
    });

    testWidgets('تصنيف chat بلا معرّف يفتح قائمة المحادثات', (tester) async {
      await pumpApp(tester);
      await openPush(tester, {'category': 'chat'});

      expect(recorder.routes, contains(RouteName.chatListScreen));
    });

    testWidgets('حمولة فارغة لا تنقل ولا ترمي', (tester) async {
      await pumpApp(tester);
      await openPush(tester, {});

      expect(recorder.routes, isEmpty);
    });

    testWidgets('معرّف غير رقمي يُعامَل كغائب', (tester) async {
      await pumpApp(tester);
      await openPush(tester, {'ride_id': 'ليس رقماً'});

      expect(recorder.routes, isEmpty);
    });
  });

  group('الأولوية بين المعرّفات', () {
    testWidgets('المحادثة تسبق الشكوى والرحلة', (tester) async {
      await pumpApp(tester);
      await openPush(tester, {
        'conversation_id': '5',
        'complaint_id': '7',
        'ride_id': '13',
      });

      expect(recorder.routes.single, RouteName.chatScreen);
    });

    testWidgets('الشكوى تسبق الرحلة', (tester) async {
      await pumpApp(tester);
      await openPush(tester, {'complaint_id': '7', 'ride_id': '13'});

      expect(recorder.routes.single, RouteName.complaintDetail);
    });
  });

  group('المصدران يتّفقان', () {
    testWidgets('بطاقة القائمة وإشعار FCM يقودان الوجهة نفسها',
        (tester) async {
      const payload = {'ride_id': '13'};

      await pumpApp(tester);
      // مسار بطاقة القائمة: الحقول من الكيان
      await NotificationRouter.open(
        type: 'ride_cancelled',
        category: 'ride',
        data: const {'ride_id': 13},
      );
      await tester.pumpAndSettle();
      final fromCard = recorder.routes.last;
      final argsFromCard = recorder.arguments.last;

      // مسار FCM: الحقول نصوص داخل data
      await openPush(tester, payload);

      expect(recorder.routes.last, fromCard);
      expect(recorder.arguments.last, argsFromCard);
    });
  });
}
