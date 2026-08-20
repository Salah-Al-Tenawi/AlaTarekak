import 'package:alatarekak/core/utils/widgets/seats_stepper.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/cancel_seats_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// ورقة إلغاء المقاعد.
///
/// كانت حوارين متتاليين: أوّلهما يختار العدد بعدّاد مبنيّ يدوياً، وثانيهما
/// يسأل «هل أنت متأكد؟» بنصّ لا يتغيّر بما اختير. والسؤال المنفصل لا يضيف
/// يقيناً حين يكرّر ما قيل للتوّ — الأنفع أن يُرى **أثر الاختيار** قبل
/// الضغط.
void main() {
  setUp(() => Get.testMode = true);

  Future<void> pump(
    WidgetTester tester, {
    int bookedSeats = 3,
    double pricePerSeat = 25000,
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
        child: GetMaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: CancelSeatsSheet(
                bookedSeats: bookedSeats,
                pricePerSeat: pricePerSeat,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapPlus(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
  }

  group('العدّاد هو المشترك لا نسخة ثالثة', () {
    testWidgets('يستعمل SeatsStepper', (tester) async {
      await pump(tester);

      expect(find.byType(SeatsStepper), findsOneWidget);
    });

    testWidgets('حجز بمقعد واحد: لا عدّاد — لا خيار فيه', (tester) async {
      await pump(tester, bookedSeats: 1);

      expect(find.byType(SeatsStepper), findsNothing);
      expect(find.textContaining('يُلغى الحجز بالكامل'), findsOneWidget);
    });
  });

  group('أثر الاختيار يُعرض قبل الضغط', () {
    testWidgets('مقعد من ثلاثة: يبقى مقعدان', (tester) async {
      await pump(tester, bookedSeats: 3);

      expect(find.textContaining('يبقى لك مقعدين'), findsOneWidget);
    });

    testWidgets('اثنان من ثلاثة: يبقى مقعد واحد', (tester) async {
      await pump(tester, bookedSeats: 3);
      await tapPlus(tester);

      expect(find.textContaining('يبقى لك مقعداً واحداً'), findsOneWidget);
    });

    testWidgets('الثلاثة كلها: يُلغى الحجز بالكامل', (tester) async {
      await pump(tester, bookedSeats: 3);
      await tapPlus(tester);
      await tapPlus(tester);

      expect(find.textContaining('يُلغى الحجز بالكامل'), findsOneWidget);
      // نصّ الإلغاء الكامل يقول «ولا يبقى لك مقعد» — فالنفي على صيغ
      // «ما بقي» لا على الجملة التي تنفيه بنفسها
      expect(find.textContaining('يبقى لك مقعدين'), findsNothing);
      expect(find.textContaining('يبقى لك مقعداً واحداً'), findsNothing);
    });

    testWidgets('نصّ الزرّ يتبع الاختيار', (tester) async {
      // «إلغاء الحجز» عنوانُ الورقة أيضاً — فالبحث محصور في الزرّ
      Finder button(String label) =>
          find.widgetWithText(ElevatedButton, label);

      await pump(tester, bookedSeats: 3);
      expect(button('إلغاء مقعداً واحداً'), findsOneWidget);

      await tapPlus(tester);
      expect(button('إلغاء مقعدين'), findsOneWidget);

      await tapPlus(tester);
      expect(button('إلغاء الحجز'), findsOneWidget,
          reason: 'إلغاء الكل ليس إلغاء مقاعد بل إلغاء حجز');
    });
  });

  group('قيمة ما يُلغى', () {
    testWidgets('تُحسب من سعر المقعد وتتبع العدّاد', (tester) async {
      await pump(tester, bookedSeats: 3, pricePerSeat: 25000);

      expect(find.text('25,000 ل.س'), findsOneWidget);

      await tapPlus(tester);
      expect(find.text('50,000 ل.س'), findsOneWidget);
    });

    testWidgets('سعر صفر لا يعرض سطر القيمة', (tester) async {
      await pump(tester, bookedSeats: 2, pricePerSeat: 0);

      expect(find.text('قيمة ما يُلغى'), findsNothing);
    });

    testWidgets('سياسة الإلغاء مذكورة وقابلة للفتح', (tester) async {
      await pump(tester);

      expect(find.textContaining('قد يُخصم جزء من المبلغ'), findsOneWidget);
      expect(find.text('اطّلع على سياسة الإلغاء'), findsOneWidget);
    });
  });

  group('النتيجة', () {
    testWidgets('«تراجع» يُغلق بلا إلغاء', (tester) async {
      int? result;

      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          child: GetMaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      result = await CancelSeatsSheet.show(
                        context,
                        bookedSeats: 3,
                        pricePerSeat: 25000,
                      );
                    },
                    child: const Text('افتح'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تراجع'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('التأكيد يُعيد العدد المختار', (tester) async {
      int? result;

      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          child: GetMaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () async {
                      result = await CancelSeatsSheet.show(
                        context,
                        bookedSeats: 3,
                        pricePerSeat: 25000,
                      );
                    },
                    child: const Text('افتح'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      await tapPlus(tester);
      await tester.tap(find.text('إلغاء مقعدين'));
      await tester.pumpAndSettle();

      expect(result, 2);
    });
  });

  group('الاستجابة للقياس', () {
    for (final size in const [
      Size(320, 568),
      Size(360, 740),
      Size(430, 932),
    ]) {
      testWidgets('عرض ${size.width.toInt()}: بلا فيض', (tester) async {
        await pump(tester, bookedSeats: 8, pricePerSeat: 1250000, size: size);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
