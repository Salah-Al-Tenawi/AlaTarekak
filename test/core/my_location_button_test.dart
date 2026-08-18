import 'package:alatarekak/core/service/location_service.dart';
import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';
import 'package:alatarekak/core/utils/widgets/my_location_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// زرّ «موقعي» في اختيار نقطة الانطلاق والوجهة.
///
/// كان على الراكب أن يجد بيته على الخريطة بإصبعه في كل بحث، وعلى السائق
/// كذلك في كل رحلة — وهو أكثر ما يُكرَّر في التطبيق.
///
/// ولكل تعذّر تصرّفه: المطفأة تُشغَّل، والمرفوضة دائماً تُفتح من
/// الإعدادات، والخارجة عن سوريا تُصحَّح على الخريطة. رسالة عامة واحدة
/// لثلاث حالات تترك المستخدم لا يدري ما يفعل.

const _damascus = LatLng(33.5138, 36.2765);

Future<List<LatLng>> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final located = <LatLng>[];
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        theme: ThemApp.lightThem,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: MyLocationButton(onLocated: located.add),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return located;
}

void main() {
  tearDown(() => LocationService.debugOverride = null);

  group('النجاح', () {
    testWidgets('يُبلّغ بالنقطة التي حُدِّدت', (tester) async {
      LocationService.debugOverride =
          () async => const LocationSuccess(_damascus);

      final located = await _pump(tester);
      await tester.tap(find.text('موقعي الحالي'));
      await tester.pumpAndSettle();

      expect(located, [_damascus]);
      expect(find.byType(AppDialogContent), findsNothing);
    });

    testWidgets('يعرض حالة انتظار أثناء التحديد', (tester) async {
      LocationService.debugOverride = () async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return const LocationSuccess(_damascus);
      };

      await _pump(tester);
      await tester.tap(find.text('موقعي الحالي'));
      await tester.pump();

      expect(find.text('جارٍ التحديد…'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('لكل تعذّر رسالته', () {
    Future<void> expectMessage(
      WidgetTester tester,
      LocationFailure reason,
      Pattern shown,
    ) async {
      LocationService.debugOverride = () async => LocationDenied(reason);

      await _pump(tester);
      await tester.tap(find.text('موقعي الحالي'));
      await tester.pumpAndSettle();

      expect(find.byType(AppDialogContent), findsOneWidget);
      expect(find.textContaining(shown), findsOneWidget);
    }

    testWidgets('خدمة الموقع مطفأة', (tester) async {
      await expectMessage(tester, LocationFailure.serviceDisabled, 'شغّلها');
    });

    testWidgets('رُفض الإذن هذه المرّة', (tester) async {
      await expectMessage(tester, LocationFailure.denied, 'لم يُسمح');
    });

    testWidgets('مرفوض دائماً: يُفتح باب الإعدادات', (tester) async {
      await expectMessage(
          tester, LocationFailure.deniedForever, 'إعدادات التطبيق');

      expect(find.text('فتح الإعدادات'), findsOneWidget,
          reason: 'الرفض الدائم لا يُسأل بعده — الحلّ من النظام');
    });

    testWidgets('خارج سوريا: يُوجَّه إلى الخريطة', (tester) async {
      await expectMessage(tester, LocationFailure.outsideSyria, 'خارج سوريا');

      expect(find.text('فتح الإعدادات'), findsNothing,
          reason: 'لا شأن للإعدادات هنا');
    });

    testWidgets('تعذّر تقني', (tester) async {
      await expectMessage(tester, LocationFailure.unavailable, 'الإشارة');
    });

    testWidgets('لا نقطة تُبلَّغ عند أي تعذّر', (tester) async {
      LocationService.debugOverride =
          () async => const LocationDenied(LocationFailure.denied);

      final located = await _pump(tester);
      await tester.tap(find.text('موقعي الحالي'));
      await tester.pumpAndSettle();

      expect(located, isEmpty);
    });
  });

  group('الضغط المتكرّر', () {
    testWidgets('لا يُطلق طلبين متزامنين', (tester) async {
      var calls = 0;
      LocationService.debugOverride = () async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return const LocationSuccess(_damascus);
      };

      await _pump(tester);
      await tester.tap(find.text('موقعي الحالي'));
      await tester.pump();
      await tester.tap(find.text('جارٍ التحديد…'));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });
  });
}
