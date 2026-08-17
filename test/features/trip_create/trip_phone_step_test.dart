import 'package:alatarekak/core/utils/class/syrian_phone.dart';
import 'package:alatarekak/core/utils/widgets/syrian_phone_field.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/data/repo/trip_create_repo_im.dart';
import 'package:alatarekak/features/trip_create/presantion/manger/cubit/push_ride_cubit.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_add_number_phone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTripCreateRepo extends Mock implements TripCreateRepoIm {}

/// خطوة رقم التواصل في إنشاء الرحلة.
///
/// كانت تعرض التلميح `09XXXXXXXX` بلا مفتاح دولي، فلا يعرف السائق أن
/// الرقم سوري حصراً إلا من رفض الخادم. وصارت تشترك مع بقية مواضع الرقم
/// في [SyrianPhoneField] بدل حقل مكتوب بيدها.

void main() {
  late MockTripCreateRepo repo;
  late PushRideCubit cubit;

  setUp(() {
    repo = MockTripCreateRepo();
    cubit = PushRideCubit(repo);
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, {TripFrom? trip}) async {
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
              body: BlocProvider<PushRideCubit>.value(
                value: cubit,
                child: TripAddNumberPhone(
                  tripFrom: trip ?? TripFrom(),
                  // onNext غير فارغ ⇒ وضع المعالج: بلا Scaffold ولا تنقّل
                  onNext: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('المفتاح «963+» ظاهر في خطوة رقم التواصل', (tester) async {
    await pump(tester);

    expect(find.byType(SyrianPhoneField), findsOneWidget);
    expect(find.text('+963'), findsOneWidget);
    // التلميح وحده — لا عنوان داخلي يكرّره
    expect(find.text(SyrianPhoneField.hint), findsOneWidget);
  });

  testWidgets('مؤشّر الصحّة يضيء على الرقم بلا صفر — كما يوحي المفتاح',
      (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    await tester.enterText(find.byType(TextFormField), '988626577');
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget,
        reason: 'حارس الزرّ يقرأ الرقم عبر SyrianPhone فيقبل الصيغتين');
  });

  testWidgets('مؤشّر الصحّة لا يضيء على رقم غير سوري', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField), '0888626577');
    await tester.pump();

    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
  });

  testWidgets('الرقم يُحفَظ في النموذج مع الكتابة ويُطبَّع قبل الإرسال',
      (tester) async {
    final trip = TripFrom();
    await pump(tester, trip: trip);
    await tester.enterText(find.byType(TextFormField), '988626577');
    await tester.pump();

    expect(trip.numberPhone, '988626577', reason: 'يُحفظ كما كُتب');
    expect(SyrianPhone.normalize(trip.numberPhone), '0988626577',
        reason: 'ومصدر البيانات يُطبّعه إلى صيغة الخادم قبل الإرسال');
  });
}
