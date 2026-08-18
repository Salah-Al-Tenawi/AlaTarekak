import 'package:alatarekak/core/constant/address.dart';
import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/core/utils/widgets/province_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختيار المحافظة.
///
/// كان لكل شاشة اختيارها: ورقة سفلية مرتّبة في «تعديل المعلومات»، و
/// `DropdownButtonFormField` في إنشاء الحساب — قائمة النظام الرمادية
/// تفتح فوق الحقل. الشكل واحد الآن، ومشترك.

Future<void> _pump(
  WidgetTester tester, {
  String? value,
  required ValueChanged<String> onChanged,
  GlobalKey<FormState>? formKey,
  Size screen = const Size(390, 844),
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: screen,
      builder: (context, _) => MaterialApp(
        theme: ThemApp.lightThem,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Form(
              key: formKey,
              child: ProvinceField(value: value, onChanged: onChanged),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('الحقل', () {
    testWidgets('بلا قيمة يعرض التلميح', (tester) async {
      await _pump(tester, onChanged: (_) {});
      expect(find.text('اختر المحافظة'), findsOneWidget);
    });

    testWidgets('بقيمة يعرضها', (tester) async {
      await _pump(tester, value: 'حمص', onChanged: (_) {});
      expect(find.text('حمص'), findsOneWidget);
      expect(find.text('اختر المحافظة'), findsNothing);
    });
  });

  group('الورقة السفلية', () {
    testWidgets('تُفتح وتعرض المحافظات', (tester) async {
      await _pump(tester, onChanged: (_) {});

      await tester.tap(find.text('اختر المحافظة'));
      await tester.pumpAndSettle();

      // القائمة كسولة: يُبنى منها ما يظهر فقط، فنتحقّق من أوائلها
      expect(find.byType(ProvinceSheet), findsOneWidget);
      expect(find.text('دمشق'), findsOneWidget);
      expect(find.text('ريف دمشق'), findsOneWidget);
    });

    testWidgets('الاختيار يُبلّغ المستدعي ويظهر في الحقل', (tester) async {
      String? picked;
      await _pump(tester, onChanged: (v) => picked = v);

      await tester.tap(find.text('اختر المحافظة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('درعا').last);
      await tester.pumpAndSettle();

      expect(picked, 'درعا');
      expect(find.byType(ProvinceSheet), findsNothing);
      expect(find.text('درعا'), findsOneWidget);
    });

    testWidgets('الإغلاق بلا اختيار لا يغيّر شيئاً', (tester) async {
      String? picked;
      await _pump(tester, value: 'حمص', onChanged: (v) => picked = v);

      await tester.tap(find.text('حمص'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(ProvinceSheet))).pop();
      await tester.pumpAndSettle();

      expect(picked, isNull);
      expect(find.text('حمص'), findsOneWidget);
    });

    testWidgets('المحافظة المختارة معلَّمة في القائمة', (tester) async {
      await _pump(tester, value: 'حمص', onChanged: (_) {});

      await tester.tap(find.text('حمص'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('كل المحافظات متاحة بالتمرير', (tester) async {
      await _pump(tester, onChanged: (_) {});
      await tester.tap(find.text('اختر المحافظة'));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text(syrianProvinces.last),
        find.byType(ListView),
        const Offset(0, -80),
      );

      expect(find.text(syrianProvinces.last), findsOneWidget);
    });
  });

  group('التحقّق مع النموذج', () {
    testWidgets('بلا اختيار يفشل التحقّق ويظهر الخطأ في مكانه',
        (tester) async {
      final key = GlobalKey<FormState>();
      await _pump(tester, onChanged: (_) {}, formKey: key);

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('الرجاء اختيار المحافظة'), findsOneWidget);
    });

    testWidgets('بعد الاختيار ينجح التحقّق', (tester) async {
      final key = GlobalKey<FormState>();
      await _pump(tester, onChanged: (_) {}, formKey: key);

      await tester.tap(find.text('اختر المحافظة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('دمشق').last);
      await tester.pumpAndSettle();

      expect(key.currentState!.validate(), isTrue);
    });
  });

  group('الاستجابة للقياس', () {
    testWidgets('شاشة ضيّقة: بلا فيض', (tester) async {
      await _pump(tester, value: 'ريف دمشق', onChanged: (_) {},
          screen: const Size(320, 640));

      await tester.tap(find.text('ريف دمشق'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('وضع أفقي: الورقة تمرّر ولا تفيض', (tester) async {
      await _pump(tester, onChanged: (_) {}, screen: const Size(740, 360));

      await tester.tap(find.text('اختر المحافظة'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProvinceSheet), findsOneWidget);
    });
  });
}
