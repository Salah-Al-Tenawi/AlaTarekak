import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/core/utils/widgets/status_filter_bar.dart';
import 'package:alatarekak/features/trip_me/presantion/manger/cubit/trip_me_cubit.dart';
import 'package:alatarekak/features/trip_me/presantion/view/trip_me_list.dart';
import 'package:alatarekak/features/trip_me/presantion/view/widget/trip_item.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockTripMeCubit extends MockCubit<TripMeState> implements TripMeCubit {}

/// تصنيف «رحلاتي» على الشاشة، بكيوبت وهمي بلا شبكة.
///
/// كانت الرحلات كلها في قائمة واحدة: ملغاة ومنتهية ومتاحة معاً، فالسؤال
/// «أيّ رحلاتي ما زالت تحتاج ركّاباً؟» يُجاب بالتمرير والقراءة.
void main() {
  late MockTripMeCubit cubit;

  Widget buildScreen() {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider<TripMeCubit>.value(
            value: cubit,
            child: const TripMeList(),
          ),
        ),
      ),
    );
  }

  /// خمس رحلات تغطّي المجموعات الأربع، مميّزة بوجهاتها.
  final mixedTrips = [
    fakeTrip(id: 1, status: 'active', destination: 'حماة'),
    fakeTrip(id: 2, status: 'full', destination: 'حلب'),
    fakeTrip(id: 3, status: 'cancelled', destination: 'اللاذقية'),
    fakeTrip(id: 4, status: 'finished', destination: 'طرطوس'),
    fakeTrip(id: 5, status: 'no_show', destination: 'درعا'),
  ];

  Finder inBar(String text) => find.descendant(
        of: find.byType(StatusFilterBar),
        matching: find.text(text),
      );

  /// الرقاقات أعرض من شاشة الهاتف، فالشريط يمرّر أفقياً: الوصول إلى
  /// «ملغاة» يمرّ بالتمرير كما يفعل المستخدم.
  Future<void> tapFilter(WidgetTester tester, String label) async {
    await tester.ensureVisible(inBar(label));
    await tester.pumpAndSettle();
    await tester.tap(inBar(label));
    await tester.pumpAndSettle();
  }

  Future<void> pumpLoaded(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(
      cubit,
      const Stream<TripMeState>.empty(),
      initialState: TripMeListLoaded(trips: mixedTrips),
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
  }

  setUp(() {
    cubit = MockTripMeCubit();
    // `initState` يجلب ما لم تكن القائمة محمّلة — والوهمي لا يفعل شيئاً
    when(() => cubit.getMeTrips()).thenAnswer((_) async {});
  });

  group('الحالات المرئية', () {
    testWidgets('حالة التحميل تعرض مؤشر التحميل', (tester) async {
      whenListen(
        cubit,
        const Stream<TripMeState>.empty(),
        initialState: TripMeLoading(),
      );

      await tester.pumpWidget(buildScreen());

      expect(find.byType(LoadingWidgetSize150), findsOneWidget);
    });

    testWidgets('قائمة فارغة تعرض رسالة "لا توجد رحلات"', (tester) async {
      whenListen(
        cubit,
        const Stream<TripMeState>.empty(),
        initialState: const TripMeListLoaded(trips: []),
      );

      await tester.pumpWidget(buildScreen());

      expect(find.text('لا توجد رحلات'), findsOneWidget);
    });
  });

  group('التصنيف حسب الحالة', () {
    testWidgets('الافتراضي «الكل»: كل الرحلات معروضة', (tester) async {
      await pumpLoaded(tester);

      expect(inBar('5'), findsOneWidget, reason: 'عدّاد «الكل»');
      expect(find.text('حماة'), findsOneWidget);
    });

    testWidgets('رقاقات المجموعات الخمس موجودة', (tester) async {
      await pumpLoaded(tester);

      expect(inBar('الكل'), findsOneWidget);
      expect(inBar('متاحة'), findsOneWidget);
      expect(inBar('ممتلئة'), findsOneWidget);
      await tapFilter(tester, 'منتهية');
      expect(inBar('ملغاة'), findsOneWidget);
    });

    testWidgets('«متاحة» تعرض الرحلة المفتوحة للحجز وحدها', (tester) async {
      await pumpLoaded(tester);

      await tapFilter(tester, 'متاحة');

      expect(find.byType(ItemTrip), findsOneWidget);
      expect(find.text('حماة'), findsOneWidget);
      expect(find.text('حلب'), findsNothing,
          reason: 'الممتلئة لا تحتاج ركّاباً، فلا مكان لها في «متاحة»');
    });

    testWidgets('«ملغاة» تجمع الملغاة وعدم الحضور', (tester) async {
      await pumpLoaded(tester);

      await tapFilter(tester, 'ملغاة');

      expect(find.byType(ItemTrip), findsNWidgets(2));
      expect(find.text('اللاذقية'), findsOneWidget);
      expect(find.text('درعا'), findsOneWidget);
      expect(find.text('حماة'), findsNothing);
    });

    testWidgets('الرجوع إلى «الكل» يُعيد الجميع', (tester) async {
      await pumpLoaded(tester);

      await tapFilter(tester, 'منتهية');
      expect(find.text('طرطوس'), findsOneWidget);
      expect(find.text('حماة'), findsNothing);

      await tapFilter(tester, 'الكل');
      expect(find.text('حماة'), findsOneWidget);
    });

    testWidgets('مجموعة فارغة: رسالتها هي ومخرج إلى «الكل»', (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      whenListen(
        cubit,
        const Stream<TripMeState>.empty(),
        initialState: TripMeListLoaded(trips: [fakeTrip(id: 1)]),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tapFilter(tester, 'ملغاة');

      expect(find.text('لا رحلات ملغاة'), findsOneWidget);
      expect(find.text('لا توجد رحلات'), findsNothing,
          reason: 'الرسالة العامّة تُوهم أن الرحلات كلها اختفت');

      await tester.tap(find.text('عرض كل الرحلات'));
      await tester.pumpAndSettle();

      expect(find.byType(ItemTrip), findsOneWidget);
    });
  });

  group('أثناء الإلغاء', () {
    testWidgets('الرحلات تبقى معروضة، ويظهر شريط تقدّم', (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // الكيوبت يمرّ بـ TripMeLoading بين الإلغاء وإعادة الجلب
      whenListen(
        cubit,
        Stream<TripMeState>.fromIterable([TripMeLoading()]),
        initialState: TripMeListLoaded(trips: mixedTrips),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();
      // مهلة تكفي لمؤقّتات ظهور البطاقات المتدرّج. و`pumpAndSettle` لا
      // تصلح هنا: شريط التقدّم غير المحدَّد لا يهدأ أبداً.
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('حماة'), findsOneWidget,
          reason: 'كانت القائمة تُستبدل بمؤشّر دوّار فتختفي الرحلات');
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
