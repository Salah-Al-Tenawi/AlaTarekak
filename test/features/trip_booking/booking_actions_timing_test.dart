import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/data/repo/booking_me_repo.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockBookingMeRepo extends Mock implements BookingMeRepo {}

class MockChatRepo extends Mock implements ChatRepo {}

/// أزرار حجز «حجوزاتي» عبر الزمن.
///
/// انتقلت من البطاقة إلى ورقة التفاصيل حين صارت البطاقة ملخّصاً، والقواعد
/// الزمنية ثلاث مراحل:
///   قبل الانطلاق           → إلغاء الحجز
///   مع الانطلاق            → تأكيد الوصول
///   بعد دقيقة من الانطلاق  → يُضاف بلاغ «السائق لم يحضر»
///
/// كان البلاغ يظهر مع الانطلاق مباشرة، ثم أُخّر ساعة، ثم قُصّرت المهلة
/// إلى دقيقة (2026-08-20). وهو **مخفيّ** قبل أوانه لا معطّلاً بعدّاده:
/// بلاغ غياب على حجز مؤكَّد لم تنطلق رحلته إنذارٌ في غير موضعه.
void main() {
  late MockBookingMeRepo repo;
  late MockChatRepo chatRepo;
  late BookingMeCubit cubit;

  setUp(() {
    repo = MockBookingMeRepo();
    chatRepo = MockChatRepo();
    Get.testMode = true;
    cubit = BookingMeCubit(repo, chatRepo: chatRepo);
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, BookingMe booking) async {
    tester.view.physicalSize = const Size(420, 1600);
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
            child: BlocProvider<BookingMeCubit>.value(
              value: cubit,
              child: Scaffold(
                body: BookingDetailsContent(booking: booking),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('قبل الانطلاق', () {
    testWidgets('إلغاء الحجز وحده — لا تأكيد ولا بلاغ', (tester) async {
      await pump(tester, fakeBooking(departsIn: const Duration(hours: 3)));

      expect(find.text('إلغاء الحجز'), findsOneWidget);
      expect(find.text('تأكيد الوصول'), findsNothing);
      expect(find.text('لم يحضر'), findsNothing);
    });
  });

  group('مع الانطلاق', () {
    testWidgets('تأكيد الوصول يظهر، والبلاغ لا', (tester) async {
      await pump(tester, fakeBooking(departsIn: const Duration(seconds: -30)));

      expect(find.text('تأكيد الوصول'), findsOneWidget);
      expect(find.text('لم يحضر'), findsNothing,
          reason: 'من انطلق قبل نصف دقيقة ليس غائباً');
      expect(find.textContaining('بعد '), findsNothing,
          reason: 'ولا عدّاد ينتظره: الزرّ مخفيّ حتى تُفتح بوابته');
    });
  });

  group('بعد دقيقة من الانطلاق', () {
    testWidgets('التأكيد والبلاغ معاً', (tester) async {
      await pump(tester, fakeBooking(departsIn: const Duration(minutes: -2)));

      expect(find.text('تأكيد الوصول'), findsOneWidget);
      expect(find.text('لم يحضر'), findsOneWidget);
    });

    testWidgets('وبعد ساعة كذلك', (tester) async {
      await pump(
          tester,
          fakeBooking(
              departsIn: const Duration(hours: -1, minutes: -10)));

      expect(find.text('تأكيد الوصول'), findsOneWidget);
      expect(find.text('لم يحضر'), findsOneWidget);
    });
  });

  group('حالات لا إجراء فيها', () {
    testWidgets('طلب معلّق: إلغاء الطلب مهما كان الوقت', (tester) async {
      await pump(
        tester,
        fakeBooking(
            departsIn: const Duration(hours: -3), status: 'pending'),
      );

      expect(find.text('إلغاء الطلب'), findsOneWidget);
      expect(find.text('لم يحضر'), findsNothing);
    });

    testWidgets('حجز ملغى: لا تأكيد ولا بلاغ', (tester) async {
      await pump(
        tester,
        fakeBooking(
            departsIn: const Duration(hours: -3), status: 'cancelled'),
      );

      expect(find.text('الحجز ملغى'), findsOneWidget);
      expect(find.text('لم يحضر'), findsNothing);
    });

    testWidgets('حالة بأحرف كبيرة تُقرأ كما هي بالصغيرة', (tester) async {
      await pump(
        tester,
        fakeBooking(
            departsIn: const Duration(hours: -3), status: 'CANCELLED'),
      );

      expect(find.text('الحجز ملغى'), findsOneWidget,
          reason: 'الخادم أرسل الحالة بأحرف كبيرة في بعض الردود');
    });
  });
}
