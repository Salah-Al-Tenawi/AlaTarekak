import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/presantion/trip_created_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// المكدّس بعد إنشاء الرحلة.
///
/// كان الانتقال يمسح المكدّس كلّه ويضع شاشة «هل ترغب بإنشاء رحلة
/// للعودة؟» وحدها فيه. فمن ضغط «رجوع» عليها — أو على شاشة من معالج
/// العودة فوقها — لم يجد تحتها شيئاً **فخرج من التطبيق**.
TripFrom _trip() => TripFrom(
      startLat: '33.51',
      startLng: '36.29',
      endLat: '34.73',
      endLng: '36.71',
      startName: 'دمشق',
      endName: 'حمص',
      date: '2026-09-20 14:30:00',
      numberSeats: 3,
      price: 25000,
    );

/// شاشات وهمية بأسماء المسارات الحقيقية — الغاية المكدّس لا المحتوى.
Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: RouteName.home,
      getPages: [
        GetPage(
            name: RouteName.home,
            page: () => const Scaffold(body: Text('الرئيسية'))),
        GetPage(
            name: RouteName.tripDidYouBack,
            page: () => const Scaffold(body: Text('رحلة العودة؟'))),
        GetPage(
            name: RouteName.tripSelectDateAndSeats,
            page: () => const Scaffold(body: Text('الموعد والمقاعد'))),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => Get.testMode = false);

  testWidgets('شاشة العودة تُعرض بعد الإنشاء', (tester) async {
    await _pumpApp(tester);

    goToReturnTripPrompt(_trip());
    await tester.pumpAndSettle();

    expect(find.text('رحلة العودة؟'), findsOneWidget);
    expect(Get.arguments, isA<TripFrom>());
  });

  testWidgets('**والرجوع منها يعود إلى الرئيسية لا يخرج من التطبيق**',
      (tester) async {
    await _pumpApp(tester);

    goToReturnTripPrompt(_trip());
    await tester.pumpAndSettle();

    Get.back();
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget,
        reason: 'كان المكدّس يُمسح كلّه فلا يبقى تحتها شيء');
  });

  testWidgets('ومن معالج العودة يعود إليها ثم إلى الرئيسية', (tester) async {
    await _pumpApp(tester);

    goToReturnTripPrompt(_trip());
    await tester.pumpAndSettle();

    // «نعم، أنشئ رحلة العودة» تدفع أولى شاشات المعالج
    Get.toNamed(RouteName.tripSelectDateAndSeats, arguments: _trip());
    await tester.pumpAndSettle();
    expect(find.text('الموعد والمقاعد'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();
    expect(find.text('رحلة العودة؟'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();
    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('ولا يعود الرجوع إلى معالج الإنشاء — فلا تُنشأ رحلة مرّتين',
      (tester) async {
    await _pumpApp(tester);

    // المستخدم كان في معالج الإنشاء حين نجحت العملية
    Get.toNamed(RouteName.tripSelectDateAndSeats, arguments: _trip());
    await tester.pumpAndSettle();

    goToReturnTripPrompt(_trip());
    await tester.pumpAndSettle();

    Get.back();
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الموعد والمقاعد'), findsNothing,
        reason: 'معالج الإنشاء وراءنا وقد تمّ عمله');
  });
}
