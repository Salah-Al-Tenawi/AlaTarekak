import 'package:alatarekak/features/booking_user_in_trip/presantion/manger/cubit/booking_user_in_trip_cubit.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/view/booking_user_in_trip.dart';
import 'package:alatarekak/features/trip_create/data/model/booking_model.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class MockBookingCubit extends MockCubit<BookingUserInTripState>
    implements BookingUserInTripCubit {}

/// بطاقة الحجز في شاشة حجوزات الرحلة.
///
/// كانت تبني الصورة والشارة والأسطر بمقاسات ثابتة بلا `.sp`، وتعرض
/// «1 مقاعد»، وأيقونة دولار على مبلغ بالليرة. وكان مؤشّر التحميل يستبدل
/// أزرار **كل** البطاقات لأن حالة التحميل بلا معرّف حجز.

BookingModel _booking({
  int id = 9001,
  String name = 'ليلى الحموي',
  double rating = 4.6,
  int seats = 2,
  String status = 'pending',
  int price = 14000,
  String bookedAt = '2026-08-16T21:52:11+00:00',
  String phone = '+963988626577',
}) =>
    BookingModel(
      id: id,
      userName: name,
      userId: 501,
      avatar: null,
      rating: rating,
      seats: seats,
      status: status,
      totaPrice: price,
      bookingat: bookedAt,
      numberPhone: phone,
    );

void main() {
  late MockBookingCubit cubit;

  setUp(() {
    cubit = MockBookingCubit();
    Get.testMode = true;
    // سقّالة المعاينة المؤقتة تعبّئ حجوزات وهمية وتُبطل اختبار الفراغ
    kPreviewSampleBookings = false;
  });

  Future<void> pump(
    WidgetTester tester,
    List<BookingModel> bookings, {
    BookingUserInTripState? state,
    /// موعد انطلاق الرحلة — بلاغ «لم يحضر» مرهون بمضيّ ساعة عليه.
    DateTime? departure,
    // حالة التحميل ترسم Lottie تدور بلا نهاية، فلا تستقرّ الشجرة أبداً
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(
      cubit,
      const Stream<BookingUserInTripState>.empty(),
      initialState: state ?? BookingUserInTripInitial(),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: GetMaterialApp(
          initialRoute: '/bookings',
          getPages: [
            GetPage(
              name: '/bookings',
              page: () => BlocProvider<BookingUserInTripCubit>.value(
                value: cubit,
                child: const BookingUserINTrip(),
              ),
            ),
          ],
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
    Get.offAllNamed('/bookings',
        arguments: {'bookings': bookings, 'departure': departure});
    if (settle) {
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
    } else {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  group('محتوى البطاقة', () {
    testWidgets('الاسم والمقاعد والسعر والموعد تظهر', (tester) async {
      await pump(tester, [_booking()]);

      expect(find.text('ليلى الحموي'), findsOneWidget);
      expect(find.text('مقعدان'), findsOneWidget);
      expect(find.text('14,000 ل.س'), findsOneWidget);
      expect(find.textContaining('آب'), findsOneWidget);
      expect(find.text('+963988626577'), findsOneWidget);
    });

    testWidgets('صيغة المقاعد عربية سليمة — لا «1 مقاعد»', (tester) async {
      await pump(tester, [
        _booking(id: 1, seats: 1),
        _booking(id: 2, seats: 2, phone: ''),
        _booking(id: 3, seats: 5, phone: ''),
      ]);

      expect(find.text('مقعد واحد'), findsOneWidget);
      expect(find.text('مقعدان'), findsOneWidget);
      expect(find.text('5 مقاعد'), findsOneWidget);
      expect(find.text('1 مقاعد'), findsNothing);
    });

    testWidgets('التقييم يظهر، والصفر يُكتب «راكب جديد»', (tester) async {
      await pump(tester, [
        _booking(id: 1, rating: 4.6),
        _booking(id: 2, rating: 0, phone: ''),
      ]);

      expect(find.text('4.6'), findsOneWidget);
      expect(find.text('راكب جديد'), findsOneWidget);
      expect(find.text('0.0'), findsNothing);
    });

    testWidgets('رقم تواصل فارغ يُخفى بلا رقم مُلفَّق', (tester) async {
      await pump(tester, [_booking(phone: '')]);
      expect(find.textContaining('+963'), findsNothing);
    });

    testWidgets('موعد غير صالح لا يُسقط البطاقة', (tester) async {
      await pump(tester, [_booking(bookedAt: 'غير-صالح')]);
      expect(tester.takeException(), isNull);
      expect(find.text('مقعدان'), findsOneWidget);
    });

    testWidgets('اسم فارغ يسقط إلى «راكب»', (tester) async {
      await pump(tester, [_booking(name: '  ')]);
      expect(find.text('راكب'), findsOneWidget);
    });
  });

  group('بطاقة الملخّص', () {
    testWidgets('العدّ والمقاعد بصياغة عربية سليمة', (tester) async {
      await pump(tester, [_booking(seats: 2)]);

      expect(find.text('حجوزات رحلتك'), findsOneWidget);
      expect(find.text('حجز واحد'), findsWidgets);
      expect(find.text('بمجموع مقعدين'), findsOneWidget);
    });

    testWidgets('حجزان بمجموع ثلاثة مقاعد', (tester) async {
      await pump(tester, [
        _booking(id: 1, seats: 2),
        _booking(id: 2, seats: 1, phone: ''),
      ]);
      expect(find.text('حجزان'), findsOneWidget);
      expect(find.text('بمجموع 3 مقاعد'), findsOneWidget);
    });

    testWidgets('الملغى لا يُحسب في المقاعد المشغولة', (tester) async {
      await pump(tester, [
        _booking(id: 1, seats: 2, status: 'confirmed'),
        _booking(id: 2, seats: 3, status: 'cancelled', phone: ''),
      ]);
      expect(find.text('بمجموع مقعدين'), findsOneWidget);
    });

    testWidgets('الطلبات المعلّقة تُبرز وحدها', (tester) async {
      await pump(tester, [
        _booking(id: 1, status: 'pending'),
        _booking(id: 2, status: 'confirmed', phone: ''),
      ]);
      expect(find.text('طلب بانتظارك'), findsOneWidget);
    });

    testWidgets('بلا طلبات معلّقة لا تظهر الشارة', (tester) async {
      await pump(tester, [_booking(status: 'confirmed')]);
      expect(find.textContaining('بانتظارك'), findsNothing);
    });
  });

  group('الخروج من الشاشة', () {
    testWidgets('زرّ رجوع موجود — الشاشة تُفتح بالدفع (الخطأ المُصلَح)',
        (tester) async {
      await pump(tester, [_booking()]);

      final back = find.byTooltip('رجوع');
      expect(back, findsOneWidget);
      expect(find.text('حجوزات الرحلة'), findsOneWidget);
    });
  });

  group('الإجراءات حسب الحالة', () {
    testWidgets('pending → قبول ورفض', (tester) async {
      await pump(tester, [_booking(status: 'pending')]);
      expect(find.text('قبول'), findsOneWidget);
      expect(find.text('رفض'), findsOneWidget);
    });

    testWidgets('confirmed → مراسلة، والبلاغ لا يظهر قبل موعد الانطلاق',
        (tester) async {
      await pump(
        tester,
        [_booking(status: 'confirmed')],
        departure: DateTime.now().add(const Duration(hours: 2)),
      );

      expect(find.text('مراسلة'), findsOneWidget);
      expect(find.text('قبول'), findsNothing);
      expect(find.text('لم يحضر'), findsNothing,
          reason: 'الرحلة لم تنطلق بعد — لا غياب يُبلَّغ عنه');
    });

    testWidgets('البلاغ لا يظهر قبل مضيّ ساعة على الانطلاق', (tester) async {
      await pump(
        tester,
        [_booking(status: 'confirmed')],
        departure: DateTime.now().subtract(const Duration(minutes: 40)),
      );

      expect(find.text('مراسلة'), findsOneWidget);
      expect(find.text('لم يحضر'), findsNothing,
          reason: 'تأخّر أربعين دقيقة زحمة سير لا غياب، والبلاغ يخصم نقاطاً');
    });

    testWidgets('بعد ساعة من الانطلاق يظهر البلاغ', (tester) async {
      await pump(
        tester,
        [_booking(status: 'confirmed')],
        departure: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
      );

      expect(find.text('مراسلة'), findsOneWidget);
      expect(find.text('لم يحضر'), findsOneWidget);
    });

    testWidgets('بلا موعد معروف لا يظهر البلاغ إطلاقاً', (tester) async {
      await pump(tester, [_booking(status: 'confirmed')]);

      expect(find.text('مراسلة'), findsOneWidget);
      expect(find.text('لم يحضر'), findsNothing,
          reason: 'بلاغ بلا موعد قد يُرسَل قبل أن تبدأ الرحلة');
    });

    testWidgets('cancelled → لا أزرار، والشارة وحدها تكفي', (tester) async {
      await pump(tester, [_booking(status: 'cancelled')]);
      expect(find.text('قبول'), findsNothing);
      expect(find.text('مراسلة'), findsNothing);
      expect(find.text('ملغي'), findsOneWidget);
    });

    testWidgets('الحالة المحدَّثة محلياً تسبق حالة النموذج', (tester) async {
      await pump(
        tester,
        [_booking(status: 'pending')],
        state: const BookingUserInTripUpdated(
            bookingId: 9001, statusRide: 'confirmed'),
      );

      expect(find.text('مراسلة'), findsOneWidget);
      expect(find.text('قبول'), findsNothing);
    });
  });

  group('مؤشّر التحميل يخصّ حجزه وحده (الخطأ المُصلَح)', () {
    testWidgets('البطاقة المعنيّة تفقد أزرارها والأخرى تحتفظ بها',
        (tester) async {
      await pump(
        tester,
        [
          _booking(id: 9001, status: 'pending'),
          _booking(id: 9002, status: 'pending', phone: ''),
        ],
        state: const BookingUserInTripLoading(bookingId: 9001),
        settle: false,
      );

      // حجز واحد فقط ما زال يعرض زرَّي القبول والرفض
      expect(find.text('قبول'), findsOneWidget);
      expect(find.text('رفض'), findsOneWidget);
    });
  });

  group('الحالة الفارغة', () {
    testWidgets('قائمة فارغة تعرض رسالة مطمئنة', (tester) async {
      await pump(tester, []);
      expect(find.text('لا توجد حجوزات بعد'), findsOneWidget);
      expect(find.textContaining('سنُشعرك فوراً'), findsOneWidget);
    });
  });
}
