import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_body.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

/// قائمة «حسابي».
///
/// التطبيق كلّه RTL (`main.dart`)، فـ`Row` يوزّع أبناءه من اليمين — لكن
/// سطر القائمة كان مكتوباً معكوساً بيده (السهم أولاً والأيقونة آخراً)،
/// فوقعت الأيقونة أقصى **اليسار** والسهم أقصى اليمين: مقلوب عن كل قائمة
/// عربية، ومقلوب عن بقية سطور الشاشة نفسها.

ProfileEntity _profile({int score = 72}) => ProfileEntity(
      fullname: 'يزن صلاح',
      profilePhoto: null,
      numberOfides: 12,
      totalRating: 8,
      averageRating: 4.5,
      verification: 'approved',
      description: 'وصف',
      address: 'دمشق',
      gender: 'M',
      car: null,
      comments: const [],
      documents: null,
      scoreValue: score,
    );

void main() {
  late MockProfileCubit cubit;

  setUp(() {
    cubit = MockProfileCubit();
    Get.testMode = true;
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(
      cubit,
      const Stream<ProfileState>.empty(),
      initialState: ProfileLoadedState(
        mode: ProfileMode.myView,
        profileEntity: _profile(),
      ),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: GetMaterialApp(
          // اتجاه التطبيق الحقيقي — هو ما يجعل الترتيب مرئياً أصلاً
          textDirection: TextDirection.rtl,
          locale: const Locale('ar'),
          home: BlocProvider<ProfileCubit>.value(
            value: cubit,
            child: ProfileBody(onRefresh: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// مركز أيقونة السطر الذي يحمل [label] أفقياً.
  double iconCenterX(WidgetTester tester, IconData icon) =>
      tester.getCenter(find.byIcon(icon)).dx;

  double textCenterX(WidgetTester tester, String label) =>
      tester.getCenter(find.text(label)).dx;

  group('اتجاه سطور قائمة حسابي', () {
    testWidgets('الأيقونة يمين الاسم لا يساره', (tester) async {
      await pump(tester);

      for (final row in const [
        (Icons.person_outline_rounded, 'المعلومات الشخصية'),
        (Icons.account_balance_wallet_outlined, 'محفظتي'),
        (Icons.directions_car_outlined, 'مركباتي'),
        (Icons.settings_outlined, 'الإعدادات'),
      ]) {
        expect(
          iconCenterX(tester, row.$1),
          greaterThan(textCenterX(tester, row.$2)),
          reason: '«${row.$2}»: الأيقونة يجب أن تسبق الاسم قراءةً — أي '
              'تقع يمينه في شاشة عربية',
        );
      }
    });

    testWidgets('الأيقونة ملتصقة بحافة السطر اليمنى', (tester) async {
      await pump(tester);

      final tile = find.ancestor(
        of: find.text('محفظتي'),
        matching: find.byType(InkWell),
      ).first;
      final tileRight = tester.getRect(tile).right;
      final iconRight =
          tester.getRect(find.byIcon(Icons.account_balance_wallet_outlined))
              .right;

      // الحشو الأفقي 16 + هامش الحاوية — المهم أنها في النصف الأيمن
      expect(tileRight - iconRight, lessThan(40),
          reason: 'الأيقونة عند حافة السطر لا في وسطه');
    });

    testWidgets('السهم أقصى اليسار — جهة الدخول في RTL', (tester) async {
      await pump(tester);

      final tile = find.ancestor(
        of: find.text('محفظتي'),
        matching: find.byType(InkWell),
      ).first;
      final tileRect = tester.getRect(tile);
      final arrows = find.descendant(
        of: tile,
        matching: find.byIcon(Icons.arrow_forward_ios_rounded),
      );

      expect(arrows, findsOneWidget);
      expect(tester.getCenter(arrows).dx, lessThan(tileRect.center.dx),
          reason: 'السهم في النصف الأيسر من السطر');
    });

    testWidgets('السهم يُعكس تلقائياً فيشير يساراً', (tester) async {
      await pump(tester);

      // matchTextDirection يجعل Flutter يعكس الأيقونة في RTL بلا تدخّل
      expect(Icons.arrow_forward_ios_rounded.matchTextDirection, isTrue);
    });
  });

  group('الشارة بين الاسم والسهم', () {
    testWidgets('شارة نقاط الثقة تقع يسار اسمها ويمين السهم',
        (tester) async {
      await pump(tester);

      final badgeX = textCenterX(tester, '72');
      final labelX = textCenterX(tester, 'نقاط الثقة');
      final tile = find.ancestor(
        of: find.text('نقاط الثقة'),
        matching: find.byType(InkWell),
      ).first;
      final arrowX = tester
          .getCenter(find.descendant(
            of: tile,
            matching: find.byIcon(Icons.arrow_forward_ios_rounded),
          ))
          .dx;

      expect(badgeX, lessThan(labelX), reason: 'الشارة بعد الاسم قراءةً');
      expect(arrowX, lessThan(badgeX), reason: 'والسهم بعدها');
    });
  });

  group('أسماء الخيارات', () {
    // اسم الشاشة واسم مدخلها واحد: من ضغط «الشكاوي الخاصة بي» لا يصحّ
    // أن يصل شاشةً بعنوان آخر.
    testWidgets('«الشكاوي الخاصة بي» لا «شكاواي»', (tester) async {
      await pump(tester);

      expect(find.text('الشكاوي الخاصة بي'), findsOneWidget);
      expect(find.text('شكاواي'), findsNothing);
    });
  });
}
