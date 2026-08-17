import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/profiles/data/model/documents_model.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile_driver_verification.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/verification_type_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// نوع التوثيق بعد الرفض.
///
/// سياسة التطبيق تترك للمستخدم أن يوثّق حسابه كراكب **أو** كسائق. لكن
/// شاشة الحالة كانت تستنتج النوع من مستندات الطلب السابق وتُمرّره ثابتاً
/// إلى شاشة الرفع — فمن رُفض طلبه كراكب لم يجد إلا «توثيق كراكب» ولا
/// سبيل له إلى التقديم كسائق.

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

  Future<void> pumpStatusScreen(
    WidgetTester tester, {
    required String status,
    required String userType,
  }) async {
    tester.view.physicalSize = const Size(375, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: GetMaterialApp(
          navigatorObservers: [recorder],
          textDirection: TextDirection.rtl,
          locale: const Locale('ar'),
          home: const Scaffold(body: SizedBox.shrink()),
          getPages: [
            GetPage(
              name: '/status',
              page: () => const ProfileDriverVerificationScreen(),
            ),
            GetPage(
              name: RouteName.verfiyUser,
              page: () => const Scaffold(body: Text('شاشة الرفع')),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // الشاشة تقرأ Get.arguments، وهو يُملأ من نداء التنقّل لا من GetPage
    Get.toNamed('/status', arguments: <String, dynamic>{
      'status': status,
      'userType': userType,
      'documents': null as DocumentsModel?,
    });
    await tester.pumpAndSettle();

    recorder.routes.clear();
    recorder.arguments.clear();
  }

  group('شاشة التوثيق المرفوض', () {
    testWidgets('«إعادة التقديم» تعرض النوعين لا نوعاً واحداً',
        (tester) async {
      await pumpStatusScreen(tester, status: 'rejected', userType: 'passenger');

      await tester.tap(find.text('إعادة التقديم'));
      await tester.pumpAndSettle();

      expect(find.text('توثيق كمستخدم'), findsOneWidget);
      expect(find.text('توثيق كسائق'), findsOneWidget,
          reason: 'من رُفض كراكب له أن يتقدّم كسائق');
    });

    testWidgets('اختيار «سائق» بعد رفض كراكب ينقل بالنوع الصحيح',
        (tester) async {
      await pumpStatusScreen(tester, status: 'rejected', userType: 'passenger');

      await tester.tap(find.text('إعادة التقديم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('توثيق كسائق'));
      await tester.pumpAndSettle();

      expect(recorder.routes, contains(RouteName.verfiyUser));
      expect(recorder.arguments.last, 'driver');
    });

    testWidgets('اختيار «راكب» بعد رفض كسائق متاح كذلك', (tester) async {
      await pumpStatusScreen(tester, status: 'rejected', userType: 'driver');

      await tester.tap(find.text('إعادة التقديم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('توثيق كمستخدم'));
      await tester.pumpAndSettle();

      expect(recorder.arguments.last, 'passenger');
    });
  });

  group('الترجيح لا يقفل', () {
    testWidgets('النوع السابق يُبرَز بإطار والآخر يبقى قابلاً للاختيار',
        (tester) async {
      await pumpStatusScreen(tester, status: 'rejected', userType: 'driver');
      await tester.tap(find.text('إعادة التقديم'));
      await tester.pumpAndSettle();

      final options = tester
          .widgetList<VerificationTypeOption>(
              find.byType(VerificationTypeOption))
          .toList();

      expect(options, hasLength(2));
      expect(options.where((o) => o.highlighted), hasLength(1),
          reason: 'واحد مُرجَّح لا أكثر');
      expect(
          options.firstWhere((o) => o.highlighted).title, 'توثيق كسائق');
    });
  });
}
