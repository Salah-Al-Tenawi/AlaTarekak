import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

/// بطاقة «حجوزاتي» ملخّص لا ملفّ.
///
/// كانت تعرض كل ما يصل من الخادم — المسار والموعد والعدّاد وثلاث خانات
/// رقمية ورقمَي تواصل ونوع المركبة وطريقة الدفع وزرّ الإجراء — فبلغ
/// ارتفاعها شاشة كاملة، وصار على من له خمسة حجوزات أن يمرّر خمس شاشات.
/// هذه الاختبارات تثبّت ما يبقى في الملخّص وما ينتقل إلى ورقة التفاصيل.
void main() {
  Future<void> pump(
    WidgetTester tester,
    BookingMe booking, {
    VoidCallback? onTap,
  }) async {
    // مقاس التصميم نفسه: عندها يكون 1 منطقي = 1 فيزيائي في ScreenUtil،
    // فيُقرأ ارتفاع البطاقة المقيس بالأرقام التي كُتب بها التصميم.
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
              // كما في القائمة: البطاقة تأخذ ارتفاع محتواها لا ارتفاع
              // الشاشة، وإلا صار قياس الارتفاع قياساً للشاشة.
              body: SingleChildScrollView(
                child: BookingItem(booking: booking, onTap: onTap ?? () {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ما تعرضه البطاقة', () {
    testWidgets('السائق ورقم الحجز والمسار والمقاعد والإجمالي',
        (tester) async {
      await pump(tester, fakeBooking());

      expect(find.text('أحمد'), findsOneWidget);
      expect(find.text('حجز رقم 10'), findsOneWidget);
      expect(find.text('دمشق'), findsOneWidget);
      expect(find.text('حمص'), findsOneWidget);
      expect(find.text('2 مقعد'), findsOneWidget);
      expect(find.text('50,000 ل.س'), findsOneWidget);
    });

    testWidgets('اسم بديل حين لا يرسل الخادم اسم السائق', (tester) async {
      await pump(tester, fakeBooking(driverName: '  '));

      expect(find.text('سائق الرحلة'), findsOneWidget);
    });

    testWidgets('عنوان فارغ يُرسم شرطة لا فراغاً', (tester) async {
      await pump(tester, fakeBooking(destination: ''));

      expect(find.text('—'), findsOneWidget);
    });
  });

  group('العدّاد — للحجوزات القائمة وحدها', () {
    testWidgets('حجز مؤكَّد قبل الانطلاق: يظهر ما بقي', (tester) async {
      await pump(tester, fakeBooking(departsIn: const Duration(hours: 3)));

      expect(find.textContaining('باقٍ على الانطلاق'), findsOneWidget);
    });

    testWidgets('حجز ملغى: لا عدّاد — الرحلة لم تعد تعنيه', (tester) async {
      await pump(
        tester,
        fakeBooking(status: 'cancelled', departsIn: const Duration(hours: 3)),
      );

      expect(find.textContaining('باقٍ على الانطلاق'), findsNothing);
    });

    testWidgets('موعد مضى: لا عدّاد ولو كان الحجز مؤكَّداً', (tester) async {
      await pump(tester, fakeBooking(departsIn: const Duration(hours: -2)));

      expect(find.textContaining('باقٍ على الانطلاق'), findsNothing);
    });
  });

  group('ما انتقل إلى ورقة التفاصيل', () {
    testWidgets('لا أرقام تواصل ولا طريقة دفع ولا أزرار إجراء',
        (tester) async {
      await pump(tester, fakeBooking());

      expect(find.text('رقم السائق'), findsNothing);
      expect(find.text('0988888888'), findsNothing);
      expect(find.text('رقمي في هذا الحجز'), findsNothing);
      expect(find.text('من المحفظة'), findsNothing);
      expect(find.text('إلغاء الحجز'), findsNothing,
          reason: 'الإجراءات كلها في الورقة — البطاقة للقراءة');
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    });

    testWidgets('البطاقة تبقى في حدود ارتفاع معقول', (tester) async {
      await pump(tester, fakeBooking());

      // كانت تتجاوز 700 — شاشة كاملة لحجز واحد. الآن نحو 205، أي أربع
      // بطاقات في الشاشة الواحدة.
      expect(tester.getSize(find.byType(BookingItem)).height, lessThan(230));
    });
  });

  testWidgets('الضغط على البطاقة يطلب التفاصيل', (tester) async {
    var tapped = 0;
    await pump(tester, fakeBooking(), onTap: () => tapped++);

    await tester.tap(find.text('أحمد'));
    await tester.pump();

    expect(tapped, 1);
  });
}
