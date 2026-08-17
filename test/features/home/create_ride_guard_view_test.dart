import 'package:alatarekak/features/profiles/domain/entity/car_entity.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/trip_create/presantion/create_ride_guard.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

/// زرّ إنشاء الرحلة في الرئيسية.
///
/// الشاشة كاملة ثقيلة (خرائط، سوكيت، تبويبات) فلا تُبنى هنا. المُختبَر هو
/// السلوك الذي أُضيف: الضغط يفحص الملف أولاً ويمنع بحوار مفهوم بدل ترك
/// المستخدم يُدخل الرحلة كاملة ثم يرفضها الخادم.
///
/// الفحص نفسه مُختبَر بمعزل في `create_ride_gate_test.dart`.

ProfileEntity _profile({
  String verification = 'approved',
  CarEntity? car = const CarEntity(type: 'Toyota Corolla', seats: 4),
}) =>
    ProfileEntity(
      fullname: 'أحمد',
      profilePhoto: null,
      numberOfides: 0,
      totalRating: 0,
      averageRating: 0,
      verification: verification,
      description: '',
      address: 'دمشق',
      gender: 'M',
      car: car,
      comments: const [],
      documents: null,
    );

void main() {
  late MockProfileCubit cubit;

  setUp(() {
    cubit = MockProfileCubit();
  });

  /// يبني زرّاً يستدعي المنطق نفسه الذي يستدعيه زرّ الرئيسية، عبر
  /// [CreateRideGuard] المكشوف للاختبار.
  Future<void> pumpButton(WidgetTester tester, ProfileState state) async {
    whenListen(cubit, const Stream<ProfileState>.empty(),
        initialState: state);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider<ProfileCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => CreateRideGuard.run(
                      context,
                      onAllowed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const Scaffold(
                                body: Text('معالج إنشاء الرحلة'))),
                      ),
                    ),
                    child: const Text('أنشئ'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester) async {
    await tester.tap(find.text('أنشئ'));
    await tester.pumpAndSettle();
  }

  group('يُسمح بالمتابعة', () {
    testWidgets('موثّق ولديه مركبة → يفتح المعالج بلا حوار', (tester) async {
      await pumpButton(
        tester,
        ProfileLoadedState(
            mode: ProfileMode.myView, profileEntity: _profile()),
      );
      await tap(tester);

      expect(find.text('معالج إنشاء الرحلة'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('يُمنع قبل إدخال أي شيء (الخطأ المُصلَح)', () {
    testWidgets('غير موثّق → حوار «حسابك غير موثّق» ولا يفتح المعالج',
        (tester) async {
      await pumpButton(
        tester,
        ProfileLoadedState(
            mode: ProfileMode.myView,
            profileEntity: _profile(verification: 'none')),
      );
      await tap(tester);

      expect(find.text('حسابك غير موثّق'), findsOneWidget);
      expect(find.text('ابدأ التوثيق'), findsOneWidget);
      expect(find.text('معالج إنشاء الرحلة'), findsNothing);
    });

    testWidgets('موثّق بلا مركبة → حوار «لا توجد مركبة»', (tester) async {
      await pumpButton(
        tester,
        ProfileLoadedState(
            mode: ProfileMode.myView, profileEntity: _profile(car: null)),
      );
      await tap(tester);

      expect(find.text('لا توجد مركبة في حسابك'), findsOneWidget);
      expect(find.text('أضف مركبتك'), findsOneWidget);
      expect(find.text('معالج إنشاء الرحلة'), findsNothing);
    });

    testWidgets('قيد المراجعة → حوار بلا زرّ إجراء', (tester) async {
      await pumpButton(
        tester,
        ProfileLoadedState(
            mode: ProfileMode.myView,
            profileEntity: _profile(verification: 'pending')),
      );
      await tap(tester);

      expect(find.text('طلب التوثيق قيد المراجعة'), findsOneWidget);
      expect(find.text('حسناً'), findsOneWidget);
      expect(find.text('ابدأ التوثيق'), findsNothing);
      expect(find.text('معالج إنشاء الرحلة'), findsNothing);
    });

    testWidgets('«لاحقاً» يُغلق الحوار بلا انتقال', (tester) async {
      await pumpButton(
        tester,
        ProfileLoadedState(
            mode: ProfileMode.myView, profileEntity: _profile(car: null)),
      );
      await tap(tester);

      await tester.tap(find.text('لاحقاً'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('معالج إنشاء الرحلة'), findsNothing);
    });
  });

  group('الملف غير محمَّل', () {
    testWidgets('يُجلب ثم يُفحَص — والفشل لا يمنع المحاولة', (tester) async {
      when(() => cubit.showMyProfile())
          .thenThrow(Exception('لا يوجد اتصال'));

      await pumpButton(tester, const ProfileInitialState());
      await tap(tester);

      verify(() => cubit.showMyProfile()).called(1);
      // فشل الجلب: نسمح بالمتابعة والخادم يحسم
      expect(find.text('معالج إنشاء الرحلة'), findsOneWidget);
    });

    testWidgets('يُجلب فيتبيّن أنه بلا مركبة → يُمنع', (tester) async {
      when(() => cubit.showMyProfile())
          .thenAnswer((_) async => _profile(car: null));

      await pumpButton(tester, const ProfileInitialState());
      await tap(tester);

      expect(find.text('لا توجد مركبة في حسابك'), findsOneWidget);
      expect(find.text('معالج إنشاء الرحلة'), findsNothing);
    });
  });
}
