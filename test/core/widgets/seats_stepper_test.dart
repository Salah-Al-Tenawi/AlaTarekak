import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/core/utils/widgets/seats_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// عدّاد مقاعد المركبة.
///
/// كان حقل نصّ حرّاً يقبل 40 أو 1000، فتُرفض المركبة عند الحفظ أو تُنشأ
/// رحلة بمقاعد لا وجود لها. والحدّ الأعلى ثمانية — يطابق حدّ الخادم في
/// الحجز («لا يمكن حجز أكثر من 8 مقاعد»).

Future<int?> _pump(
  WidgetTester tester, {
  required int value,
  Size screen = const Size(390, 844),
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  int? changed;
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: screen,
      builder: (context, _) => MaterialApp(
        theme: ThemApp.lightThem,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SeatsStepper(
                value: changed ?? value,
                onChanged: (v) => setState(() => changed = v),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return changed;
}

Future<void> _tapPlus(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add_rounded));
  await tester.pumpAndSettle();
}

Future<void> _tapMinus(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.remove_rounded));
  await tester.pumpAndSettle();
}

void main() {
  group('عدّاد لا حقل كتابة', () {
    testWidgets('لا حقل نصّ إطلاقاً', (tester) async {
      await _pump(tester, value: 4);

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    });

    testWidgets('يعرض القيمة والمدى', (tester) async {
      await _pump(tester, value: 4);

      expect(find.text('4'), findsOneWidget);
      expect(find.text('من 1 إلى 8'), findsOneWidget);
    });
  });

  group('الزيادة والنقص', () {
    testWidgets('الزيادة تُصعّد واحداً', (tester) async {
      await _pump(tester, value: 4);
      await _tapPlus(tester);

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('النقص يُنزل واحداً', (tester) async {
      await _pump(tester, value: 4);
      await _tapMinus(tester);

      expect(find.text('3'), findsOneWidget);
    });
  });

  group('الحدّ الأعلى ثمانية', () {
    testWidgets('لا يتجاوز الثمانية مهما ضُغط', (tester) async {
      await _pump(tester, value: 7);

      for (var i = 0; i < 6; i++) {
        await _tapPlus(tester);
      }

      expect(find.text('8'), findsOneWidget);
      expect(find.text('9'), findsNothing);
    });

    testWidgets('زرّ الزيادة معطَّل عند الثمانية', (tester) async {
      await _pump(tester, value: kMaxCarSeats);

      final button = tester.widget<InkWell>(
        find.ancestor(
          of: find.byIcon(Icons.add_rounded),
          matching: find.byType(InkWell),
        ),
      );

      expect(button.onTap, isNull, reason: 'زرّ يُضغط بلا أثر يربك المستخدم');
    });

    testWidgets('قيمة أكبر من الحدّ تُقصّ عند العرض', (tester) async {
      await _pump(tester, value: 40);

      expect(find.text('8'), findsOneWidget,
          reason: 'مركبة محفوظة بقيمة قديمة خاطئة لا تُعرض كما هي');
    });
  });

  group('الحدّ الأدنى واحد', () {
    testWidgets('لا ينزل تحت الواحد', (tester) async {
      await _pump(tester, value: 2);

      for (var i = 0; i < 5; i++) {
        await _tapMinus(tester);
      }

      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('زرّ النقص معطَّل عند الواحد', (tester) async {
      await _pump(tester, value: kMinCarSeats);

      final button = tester.widget<InkWell>(
        find.ancestor(
          of: find.byIcon(Icons.remove_rounded),
          matching: find.byType(InkWell),
        ),
      );

      expect(button.onTap, isNull);
    });
  });

  group('الاستجابة للقياس', () {
    testWidgets('شاشة ضيّقة: بلا فيض', (tester) async {
      await _pump(tester, value: 8, screen: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });

    testWidgets('شاشة عريضة: بلا فيض', (tester) async {
      await _pump(tester, value: 4, screen: const Size(1200, 900));
      expect(tester.takeException(), isNull);
    });
  });
}
