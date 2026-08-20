import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:alatarekak/core/utils/widgets/status_filter_bar.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/booking_me_list.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_details_sheet.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_item.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

class MockBookingMeCubit extends MockCubit<BookingMeState>
    implements BookingMeCubit {}

/// شاشة «حجوزاتي» بكيوبت وهمي — تتحقق من الحالات المرئية ومن تصنيف
/// الحجوزات دون أي اتصال بالشبكة.
void main() {
  late MockBookingMeCubit cubit;

  Widget buildScreen() {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider<BookingMeCubit>.value(
            value: cubit,
            child: const BookingMeList(),
          ),
        ),
      ),
    );
  }

  /// قائمة تغطّي المجموعات الأربع: طلب معلّق ومؤكَّدان وملغى ومرفوض
  /// ومنتهية — ستّة حجوزات بمعرّفات معلومة.
  final mixedBookings = [
    fakeBooking(bookingId: 1, status: 'pending', driverName: 'سالم'),
    fakeBooking(bookingId: 2, status: 'confirmed', driverName: 'أحمد'),
    fakeBooking(bookingId: 3, status: 'accepted', driverName: 'خالد'),
    fakeBooking(bookingId: 4, status: 'cancelled', driverName: 'زياد'),
    fakeBooking(bookingId: 5, status: 'rejected', driverName: 'مازن'),
    fakeBooking(bookingId: 6, status: 'completed', driverName: 'نبيل'),
  ];

  Future<void> pumpLoaded(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(
      cubit,
      const Stream<BookingMeState>.empty(),
      initialState: BookingMeListLoaded(bookings: mixedBookings),
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
  }

  /// نصّ داخل شريط التصنيف تحديداً: تسميات الرقاقات هي تسميات شارات
  /// الحالة نفسها — «قيد الانتظار» على الرقاقة وعلى بطاقة الطلب المعلّق —
  /// فالبحث العام يجد اثنين.
  Finder inBar(String text) => find.descendant(
        of: find.byType(StatusFilterBar),
        matching: find.text(text),
      );

  /// خمس رقاقات أعرض من شاشة الهاتف، فالشريط يمرّر أفقياً: الوصول إلى
  /// «ملغاة» يمرّ بالتمرير كما يفعل المستخدم.
  Future<void> tapFilter(WidgetTester tester, String label) async {
    await tester.ensureVisible(inBar(label));
    await tester.pumpAndSettle();
    await tester.tap(inBar(label));
    await tester.pumpAndSettle();
  }

  setUp(() {
    cubit = MockBookingMeCubit();
  });

  group('الحالات المرئية', () {
    testWidgets('حالة التحميل تعرض مؤشر التحميل', (tester) async {
      whenListen(
        cubit,
        const Stream<BookingMeState>.empty(),
        initialState: BookingMeListloading(),
      );

      await tester.pumpWidget(buildScreen());

      expect(find.byType(AppLoader), findsOneWidget);
    });

    testWidgets('قائمة فارغة تعرض رسالة "لا توجد حجوزات"', (tester) async {
      whenListen(
        cubit,
        const Stream<BookingMeState>.empty(),
        initialState: const BookingMeListLoaded(bookings: []),
      );

      await tester.pumpWidget(buildScreen());

      expect(find.text('لا توجد حجوزات'), findsOneWidget);
    });
  });

  group('التصنيف حسب الحالة', () {
    testWidgets('الافتراضي «الكل»: كل الحجوزات معروضة', (tester) async {
      await pumpLoaded(tester);

      // البطاقات تُبنى كسولاً في ListView، فالعدّاد أوثق من عدّ البطاقات
      expect(inBar('6'), findsOneWidget, reason: 'عدّاد «الكل»');
      expect(find.text('سالم'), findsOneWidget);
    });

    testWidgets('عدّاد كل مجموعة على رقاقتها', (tester) async {
      await pumpLoaded(tester);

      expect(inBar('الكل'), findsOneWidget);
      expect(inBar('قيد الانتظار'), findsOneWidget);
      expect(inBar('مؤكّدة'), findsOneWidget);

      // ملغاة = ملغى + مرفوض، ومؤكّدة = confirmed + accepted
      await tapFilter(tester, 'ملغاة');
      expect(inBar('2'), findsNWidgets(2));
    });

    testWidgets('«ملغاة» تعرض الملغى والمرفوض وحدهما', (tester) async {
      await pumpLoaded(tester);

      await tapFilter(tester, 'ملغاة');

      expect(find.byType(BookingItem), findsNWidgets(2));
      expect(find.text('زياد'), findsOneWidget);
      expect(find.text('مازن'), findsOneWidget);
      expect(find.text('أحمد'), findsNothing,
          reason: 'حجز مؤكَّد لا مكان له في تبويب الملغاة');
      expect(find.text('سالم'), findsNothing);
    });

    testWidgets('«قيد الانتظار» تعرض الطلب المعلّق وحده', (tester) async {
      await pumpLoaded(tester);

      await tapFilter(tester, 'قيد الانتظار');

      expect(find.byType(BookingItem), findsOneWidget);
      expect(find.text('سالم'), findsOneWidget);
    });

    testWidgets('الرجوع إلى «الكل» يُعيد الجميع', (tester) async {
      await pumpLoaded(tester);

      await tapFilter(tester, 'منتهية');
      expect(find.text('نبيل'), findsOneWidget);
      expect(find.text('سالم'), findsNothing);

      await tapFilter(tester, 'الكل');
      expect(find.text('سالم'), findsOneWidget);
    });

    testWidgets('مجموعة فارغة: رسالتها هي ومخرج إلى «الكل»', (tester) async {
      whenListen(
        cubit,
        const Stream<BookingMeState>.empty(),
        initialState: BookingMeListLoaded(bookings: [
          fakeBooking(bookingId: 1, status: 'confirmed'),
        ]),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tapFilter(tester, 'ملغاة');

      expect(find.text('لا حجوزات ملغاة'), findsOneWidget);
      expect(find.text('لا توجد حجوزات'), findsNothing,
          reason: 'الرسالة العامّة تُوهم أن الحجوزات كلها اختفت');
      expect(find.text('عرض كل الحجوزات'), findsOneWidget);

      await tester.tap(find.text('عرض كل الحجوزات'));
      await tester.pumpAndSettle();

      expect(find.byType(BookingItem), findsOneWidget);
    });
  });

  group('التفاصيل عند الطلب', () {
    testWidgets('الضغط على البطاقة يفتح ورقة تفاصيل الحجز', (tester) async {
      await pumpLoaded(tester);

      expect(find.text('تفاصيل الحجز'), findsNothing);
      // ولا أثر لتفاصيل الحجز في القائمة نفسها
      expect(find.text('رقم السائق'), findsNothing);

      await tester.tap(find.text('سالم'));
      await tester.pumpAndSettle();

      expect(find.text('تفاصيل الحجز'), findsOneWidget);
      expect(find.text('إلغاء الطلب'), findsOneWidget,
          reason: 'إجراء الحجز المعلّق يظهر في الورقة، وشريطه ثابت أسفلها');

      // ما اختفى من البطاقة موجود في الورقة — أسفل محتواها الممرَّر
      await tester.dragUntilVisible(
        find.text('رقم السائق'),
        find.descendant(
          of: find.byType(BookingDetailsContent),
          matching: find.byType(ListView),
        ),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      expect(find.text('رقم السائق'), findsOneWidget);
      expect(find.text('عرض تفاصيل الرحلة كاملة'), findsOneWidget);
    });

    testWidgets('إغلاق الورقة يُعيد القائمة كما كانت', (tester) async {
      await pumpLoaded(tester);

      await tester.tap(find.text('سالم'));
      await tester.pumpAndSettle();
      expect(find.text('تفاصيل الحجز'), findsOneWidget);

      // بالتلميح لا بالأيقونة: «إلغاء الطلب» في الورقة يحمل الأيقونة نفسها
      await tester.tap(find.byTooltip('إغلاق'));
      await tester.pumpAndSettle();

      expect(find.text('تفاصيل الحجز'), findsNothing);
      expect(find.text('سالم'), findsOneWidget);
    });
  });
}
