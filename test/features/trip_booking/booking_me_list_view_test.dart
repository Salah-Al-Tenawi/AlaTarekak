import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/booking_me_list.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class MockBookingMeCubit extends MockCubit<BookingMeState>
    implements BookingMeCubit {}

/// اختبار شاشة "حجوزاتي" بكيوبت وهمي — يتحقق أن الواجهة ترسم
/// حالات Loading / Empty الصحيحة دون أي اتصال بالشبكة.
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

  setUp(() {
    cubit = MockBookingMeCubit();
  });

  group('BookingMeList — الحالات المرئية', () {
    testWidgets('حالة التحميل تعرض مؤشر التحميل', (tester) async {
      whenListen(
        cubit,
        const Stream<BookingMeState>.empty(),
        initialState: BookingMeListloading(),
      );

      await tester.pumpWidget(buildScreen());

      expect(find.byType(LoadingWidgetSize150), findsOneWidget);
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
}
