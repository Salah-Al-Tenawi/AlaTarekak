import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';
import 'package:alatarekak/features/score/presantion/manger/cubit/score_cubit.dart';
import 'package:alatarekak/features/score/presantion/view/profile_score.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScoreCubit extends MockCubit<ScoreState> implements ScoreCubit {}

/// شاشة نقاط الثقة: النقاط في الأعلى وسجلّ الحركة في الأسفل.

ScoreEntity _score({
  int score = 85,
  String tier = 'gold',
  bool canCreate = true,
  bool canBook = true,
}) =>
    ScoreEntity(
      score: score,
      tier: tier,
      cancelRate: 3.5,
      totalRides: 40,
      totalCancellations: 2,
      canCreateRides: canCreate,
      canBookRides: canBook,
    );

ScoreHistoryEntity _entry({
  int id = 1,
  String action = 'ride_completed',
  String points = '+10',
  int newScore = 85,
  bool highCancel = false,
}) =>
    ScoreHistoryEntity(
      id: id,
      action: action,
      points: points,
      previousScore: 75,
      newScore: newScore,
      reason: 'Completed a ride',
      highCancelRateApplied: highCancel,
      createdAt: DateTime(2026, 8, 16, 21, 52),
    );

void main() {
  late MockScoreCubit cubit;

  setUp(() {
    cubit = MockScoreCubit();
    when(() => cubit.loadHistory()).thenAnswer((_) async {});
    when(() => cubit.loadMoreHistory()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, ScoreState state) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(cubit, const Stream<ScoreState>.empty(), initialState: state);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider<ScoreCubit>.value(
              value: cubit,
              child: const ProfileScoreScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // تدرّج ظهور عناصر السجل (StaggeredItem) يُنشئ Timers — نمرّر الوقت
    // حتى تنتهي وإلا سقط الاختبار بـ «Timer is still pending». ولا يصلح
    // pumpAndSettle لأن مؤشّر التحميل رسمة Lottie تدور بلا نهاية.
    await tester.pump(const Duration(milliseconds: 1200));
  }

  group('رأس الشاشة — النقاط في الأعلى', () {
    testWidgets('الرقم والمستوى والإحصاءات', (tester) async {
      await pump(tester, ScoreLoaded(score: _score()));

      expect(find.text('85'), findsWidgets);
      expect(find.text('نقاط الثقة'), findsOneWidget);
      expect(find.text('المستوى: ذهبي'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('3.5%'), findsOneWidget);
    });

    testWidgets('المستوى المقيَّد يُعرض بالعربية لا Restricted', (tester) async {
      await pump(
          tester, ScoreLoaded(score: _score(score: 10, tier: 'Restricted')));
      expect(find.text('المستوى: مقيَّد'), findsOneWidget);
      expect(find.textContaining('Restricted'), findsNothing);
    });
  });

  group('ما تسمح به النقاط', () {
    testWidgets('نقاط كافية → متاح لك', (tester) async {
      await pump(tester, ScoreLoaded(score: _score()));
      expect(find.text('إنشاء الرحلات'), findsOneWidget);
      expect(find.text('حجز الرحلات'), findsOneWidget);
      expect(find.text('متاح لك'), findsNWidgets(2));
    });

    testWidgets('نقاط ناقصة تقول كم ينقص بالعربية', (tester) async {
      await pump(
        tester,
        ScoreLoaded(
            score: _score(score: 45, canCreate: false, canBook: true)),
      );
      // 50 - 45 = 5 نقاط
      expect(find.textContaining('ينقصك 5 نقاط'), findsOneWidget);
      expect(find.text('متاح لك'), findsOneWidget);
    });
  });

  group('السجل في الأسفل', () {
    testWidgets('الزيادة والخصم بالصياغة المطلوبة', (tester) async {
      await pump(
        tester,
        ScoreHistoryLoaded(score: _score(), history: [
          _entry(id: 1, points: '+10'),
          _entry(id: 2, points: '-5', action: 'ride_cancelled', newScore: 80),
        ]),
      );

      expect(find.text('تمت إضافة 10 نقاط'), findsOneWidget);
      expect(find.text('تم خصم 5 نقاط'), findsOneWidget);
      expect(find.text('إكمال رحلة'), findsOneWidget);
      expect(find.text('إلغاء رحلة'), findsOneWidget);
    });

    testWidgets('الرصيد بعد الحركة وتاريخها يظهران', (tester) async {
      await pump(
        tester,
        ScoreHistoryLoaded(
            score: _score(), history: [_entry(newScore: 80)]),
      );
      expect(find.text('80'), findsOneWidget);
      expect(find.textContaining('آب'), findsOneWidget);
    });

    testWidgets('تنبيه جزاء معدّل الإلغاء يظهر عند تطبيقه', (tester) async {
      await pump(
        tester,
        ScoreHistoryLoaded(
            score: _score(), history: [_entry(highCancel: true)]),
      );
      expect(find.textContaining('جزاء معدّل الإلغاء'), findsOneWidget);
    });

    testWidgets('action مجهول لا يُظهر نصّ الخادم الإنجليزي', (tester) async {
      await pump(
        tester,
        ScoreHistoryLoaded(
            score: _score(), history: [_entry(action: 'mystery_action')]),
      );
      expect(find.text('تمت إضافة 10 نقاط'), findsOneWidget);
      expect(find.textContaining('Completed a ride'), findsNothing);
    });

    testWidgets('سجل فارغ يشرح ما سيظهر لاحقاً', (tester) async {
      await pump(tester,
          ScoreHistoryLoaded(score: _score(), history: const []));
      expect(find.text('لا حركات على نقاطك بعد'), findsOneWidget);
    });
  });

  // السجلّ يصل مُرقَّماً (20 حركة في الصفحة) — الشاشة تطلب التالية عند
  // اقتراب القاع، وتقول للمستخدم إن ما يراه جزء من سجلّ أطول.
  group('صفحات السجلّ', () {
    ScoreHistoryLoaded loaded({
      int count = 20,
      bool hasMore = true,
      bool loadingMore = false,
      int total = 84,
    }) =>
        ScoreHistoryLoaded(
          score: _score(),
          history: [
            for (int i = 0; i < count; i++) _entry(id: i + 1),
          ],
          hasMore: hasMore,
          loadingMore: loadingMore,
          total: total,
        );

    testWidgets('الإجمالي من meta يظهر بجانب العنوان', (tester) async {
      await pump(tester, loaded(count: 20, total: 84));
      expect(find.text('سجلّ النقاط'), findsOneWidget);
      expect(find.text('84'), findsOneWidget);
    });

    testWidgets('لا عدد حين لا يزيد الإجمالي عمّا هو معروض', (tester) async {
      await pump(tester, loaded(count: 3, total: 3, hasMore: false));
      expect(find.text('3'), findsNothing);
    });

    testWidgets('مؤشّر أسفل القائمة أثناء جلب الصفحة التالية',
        (tester) async {
      await pump(tester, loaded(loadingMore: true));
      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pump();

      expect(find.byType(AppLoader), findsOneWidget);
    });

    testWidgets('نهاية السجل: لا مؤشّر ولا دعوة للمزيد', (tester) async {
      await pump(tester, loaded(count: 3, hasMore: false, total: 3));
      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('اسحب للأسفل لعرض المزيد'), findsNothing);
    });

    testWidgets('الوصول لقاع القائمة يطلب الصفحة التالية', (tester) async {
      await pump(tester, loaded());
      verifyNever(() => cubit.loadMoreHistory());

      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pump();

      verify(() => cubit.loadMoreHistory()).called(greaterThan(0));
    });

    testWidgets('البقاء في أعلى القائمة لا يطلب صفحة', (tester) async {
      await pump(tester, loaded());
      await tester.drag(find.byType(ListView), const Offset(0, -60));
      await tester.pump();

      verifyNever(() => cubit.loadMoreHistory());
    });
  });

  group('حالات الشاشة', () {
    testWidgets('التحميل يعرض مؤشراً', (tester) async {
      await pump(tester, ScoreLoading());
      expect(find.text('سجلّ النقاط'), findsNothing);
    });

    testWidgets('خطأ بلا بيانات يعرض إعادة المحاولة', (tester) async {
      await pump(tester, ScoreError(message: 'تعذّر الاتصال بالخادم'));
      expect(find.text('تعذّر الاتصال بالخادم'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('السحب للتحديث متاح فوق المحتوى', (tester) async {
      await pump(tester, ScoreLoaded(score: _score()));
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
