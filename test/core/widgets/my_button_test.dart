import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// يغلف الويدجت بنفس إعداد التطبيق (ScreenUtil بمقاس التصميم 375×812 + RTL).
Widget wrapForTest(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('MyButton', () {
    testWidgets('يعرض المحتوى وينفذ onPressed عند الضغط', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrapForTest(
        MyButton(
          onPressed: () => pressed = true,
          child: const Text('احجز الآن'),
        ),
      ));

      expect(find.text('احجز الآن'), findsOneWidget);

      await tester.tap(find.text('احجز الآن'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('يكون معطلاً عندما تكون onPressed = null', (tester) async {
      await tester.pumpWidget(wrapForTest(
        MyButton(onPressed: null, child: const Text('معطل')),
      ));

      final button =
          tester.widget<MaterialButton>(find.byType(MaterialButton));
      expect(button.enabled, isFalse);
    });

    testWidgets('يطبق الحواف الدائرية عند borderRadius = true',
        (tester) async {
      await tester.pumpWidget(wrapForTest(
        MyButton(
          onPressed: () {},
          borderRadius: true,
          child: const Text('زر'),
        ),
      ));

      final button =
          tester.widget<MaterialButton>(find.byType(MaterialButton));
      expect(button.shape, isA<RoundedRectangleBorder>());
    });
  });
}
