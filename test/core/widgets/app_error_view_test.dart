import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/core/utils/widgets/app_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// رسالة الخطأ المشتركة.
///
/// العيب الأصلي: ثيم التطبيق يفرض `minimumSize: Size(double.infinity, 52)`
/// على الأزرار — مناسب لزرّ في أسفل نموذج، فاجع لزرّ «أعد المحاولة» وسط
/// رسالة: يمتدّ من حافة الشاشة إلى حافتها فيبتلع الرسالة نفسها.

Widget _host(Widget child, {Size size = const Size(390, 844)}) {
  return ScreenUtilInit(
    designSize: size,
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      theme: ThemApp.lightThem,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    ),
  );
}

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_host(child, size: size));
  await tester.pumpAndSettle();
}

void main() {
  group('عرض الأزرار — العيب الأصلي', () {
    testWidgets('زرّ الإجراء لا يمتدّ بعرض الشاشة', (tester) async {
      const screen = Size(390, 844);
      await _pumpAt(
        tester,
        screen,
        AppErrorView(
          message: 'رصيد محفظتك غير كافٍ لإتمام الحجز',
          actionLabel: 'أعد المحاولة',
          onAction: () {},
        ),
      );

      final width = tester.getSize(find.byType(ElevatedButton)).width;

      expect(
        width,
        lessThan(screen.width * 0.75),
        reason: 'الزرّ يرث عرض الثيم الممتدّ ما لم يُلغَ محلياً',
      );
      expect(width, greaterThan(80), reason: 'ولا يكون أضيق من أن يُقرأ');
    });

    testWidgets('الزرّان معاً يبقيان محصورين ولا يفيضان', (tester) async {
      const screen = Size(360, 740); // من أضيق ما يُباع
      await _pumpAt(
        tester,
        screen,
        AppErrorView(
          message: 'رصيد محفظتك غير كافٍ لإتمام الحجز',
          actionLabel: 'اشحن محفظتي',
          onAction: () {},
          secondaryLabel: 'أعد المحاولة',
          onSecondary: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      for (final w in [
        tester.getSize(find.byType(ElevatedButton)).width,
        tester.getSize(find.byType(OutlinedButton)).width,
      ]) {
        expect(w, lessThan(screen.width));
      }
    });
  });

  group('المحتوى', () {
    testWidgets('العنوان والرسالة يظهران', (tester) async {
      await _pumpAt(
        tester,
        const Size(390, 844),
        const AppErrorView(
          title: 'رصيدك لا يكفي',
          message: 'اشحن محفظتك ثم أعد المحاولة',
        ),
      );

      expect(find.text('رصيدك لا يكفي'), findsOneWidget);
      expect(find.text('اشحن محفظتك ثم أعد المحاولة'), findsOneWidget);
    });

    testWidgets('بلا إجراءات: لا أزرار إطلاقاً', (tester) async {
      await _pumpAt(
        tester,
        const Size(390, 844),
        const AppErrorView(message: 'تعذّر إتمام العملية'),
      );

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('الضغط يُنفّذ الإجراء', (tester) async {
      var tapped = 0;
      await _pumpAt(
        tester,
        const Size(390, 844),
        AppErrorView(
          message: 'تعذّر إتمام العملية',
          actionLabel: 'أعد المحاولة',
          onAction: () => tapped++,
        ),
      );

      await tester.tap(find.text('أعد المحاولة'));
      await tester.pump();

      expect(tapped, 1);
    });
  });

  group('الاستجابة للقياس', () {
    testWidgets('شاشة قصيرة (وضع أفقي): تمرير بلا فيض', (tester) async {
      await _pumpAt(
        tester,
        const Size(740, 360),
        AppErrorView(
          title: 'رصيدك لا يكفي',
          message: 'رصيد محفظتك غير كافٍ لإتمام الحجز، اشحن محفظتك ثم أعد '
              'المحاولة. يمكنك الشحن من شاشة المحفظة مباشرة.',
          actionLabel: 'اشحن محفظتي',
          onAction: () {},
          secondaryLabel: 'أعد المحاولة',
          onSecondary: () {},
        ),
      );

      // الفيض في Flutter يُسجَّل استثناءً في الاختبار
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('شاشة عريضة (لوح): المحتوى محصور لا يتمدّد', (tester) async {
      await _pumpAt(
        tester,
        const Size(1200, 900),
        const AppErrorView(
          message: 'تعذّر إتمام العملية',
          title: 'حدث خطأ',
        ),
      );

      final textWidth = tester.getSize(find.text('تعذّر إتمام العملية')).width;
      expect(
        textWidth,
        lessThanOrEqualTo(420),
        reason: 'سطر بعرض 1200 بكسل لا يُقرأ',
      );
    });
  });
}
