import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// شريط الإشعار — النجاح أخضر والفشل أحمر، وشكلٌ واحد للآليتين.
///
/// كان لوناً مصمتاً بحدّ من ثلاثة بكسلات حول الشريط كلّه، بألوان مكتوبة
/// رقماً لا تعرف الوضع الليلي، وعنوانٌ عامّ («نجاح») يعلو رسالةً تقول ما
/// حدث أصلاً. وكان في التطبيق شريطان: ملوّن في شاشات، ورمادي واحد لكل
/// شيء في شاشات أخرى.
void main() {
  tearDown(() => MyColors.apply(false));

  Future<void> pumpContent(
    WidgetTester tester, {
    required SnackType type,
    String message = 'تم إلغاء الحجز',
    String? title,
    Size size = const Size(375, 812),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AppSnackContent(
                message: message,
                type: type,
                title: title,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// خلفية جسم الشريط.
  Color backgroundOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AppSnackContent),
            matching: find.byType(Container),
          )
          .first,
    );
    return ((container.decoration as BoxDecoration).color)!;
  }

  group('النبرة تُقرأ من اللون والأيقونة', () {
    testWidgets('النجاح أخضر بعلامة صحّ', (tester) async {
      await pumpContent(tester, type: SnackType.success);

      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(backgroundOf(tester), MyColors.successLight);
    });

    testWidgets('الفشل أحمر بعلامة خطأ', (tester) async {
      await pumpContent(tester, type: SnackType.error);

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(backgroundOf(tester), MyColors.errorLight);
    });

    testWidgets('التحذير كهرماني', (tester) async {
      await pumpContent(tester, type: SnackType.warning);

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(backgroundOf(tester), MyColors.warningLight);
    });

    testWidgets('المعلومة محايدة', (tester) async {
      await pumpContent(tester, type: SnackType.info);

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(backgroundOf(tester), MyColors.surface);
    });
  });

  group('يتبع الوضع الليلي', () {
    testWidgets('خلفية النجاح تتبدّل بتبدّل اللوحة', (tester) async {
      MyColors.apply(false);
      await pumpContent(tester, type: SnackType.success);
      final light = backgroundOf(tester);

      MyColors.apply(true);
      await pumpContent(tester, type: SnackType.success);
      final dark = backgroundOf(tester);

      expect(light, isNot(dark),
          reason: 'ألوان مكتوبة رقماً كانت تُبقيه فاتحاً في الظلام');
    });

    testWidgets('ونصّه يبقى مقروءاً — لونه من اللوحة لا ثابتاً',
        (tester) async {
      MyColors.apply(true);
      await pumpContent(tester, type: SnackType.error);

      final text = tester.widget<Text>(find.text('تم إلغاء الحجز'));
      expect(text.style!.color, MyColors.textPrimary);
    });
  });

  group('العنوان', () {
    testWidgets('لا عنوان عامّ يعلو الرسالة', (tester) async {
      await pumpContent(tester, type: SnackType.success);

      for (final generic in const ['نجاح', 'خطأ', 'تحذير', 'معلومة']) {
        expect(find.text(generic), findsNothing,
            reason: '«$generic» فوق رسالة تقول ما حدث تكرار');
      }
    });

    testWidgets('ويُعرض حين يُمرَّر صراحةً', (tester) async {
      await pumpContent(tester, type: SnackType.success, title: 'تم الحجز');

      expect(find.text('تم الحجز'), findsOneWidget);
    });

    testWidgets('وعنوان بمسافات وحدها لا يُعرض', (tester) async {
      await pumpContent(tester, type: SnackType.success, title: '   ');

      expect(find.byType(Column), findsWidgets);
      expect(find.text('   '), findsNothing);
    });
  });

  group('showMySnackBar يعرض الجسم نفسه', () {
    testWidgets('فلا يظهر في التطبيق شريطان لأمر واحد', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          child: MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showMySnackBar(
                      context,
                      'تم تأكيد وصولك',
                      type: SnackType.success,
                    ),
                    child: const Text('اعرض'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('اعرض'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AppSnackContent), findsOneWidget);
      expect(find.text('تم تأكيد وصولك'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });
  });

  group('الاستجابة للقياس', () {
    for (final size in const [
      Size(320, 568),
      Size(360, 740),
      Size(430, 932),
    ]) {
      testWidgets('عرض ${size.width.toInt()}: رسالة طويلة بلا فيض',
          (tester) async {
        await pumpContent(
          tester,
          type: SnackType.error,
          message: 'تعذّر إتمام العملية لأن الخادم لم يستجب في الوقت '
              'المحدّد، يرجى التحقق من اتصالك بالإنترنت وإعادة المحاولة '
              'بعد قليل. وإن تكرّر الأمر فراسل فريق الدعم.',
          size: size,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
