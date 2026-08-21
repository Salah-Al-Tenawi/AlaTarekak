import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'package:alatarekak/features/auth/presentation/manger/login_cubit/login_cubit.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/buttons_login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepo extends Mock implements AuthRepoIm {}

/// الدخول بحسابٍ اجتماعي — مخفيّ لا محذوف.
///
/// زرّ Google كان معروضاً و`onPressed` فارغة: يضغطه المستخدم فلا يقع
/// شيء. ولا شيء خلفه أصلاً — لا مسار عند الخادم ولا دالّة في الكيوبت.
/// وفاصلُه «أو عبر الوسائل الاجتماعي» أُخفي معه: فاصلٌ يَعِد بوسيلةٍ لا
/// وجود لها أسوأ من غيابه.
void main() {
  late MockAuthRepo repo;

  setUp(() {
    repo = MockAuthRepo();
    Get.testMode = true;
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
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
            child: BlocProvider<LoginCubit>(
              create: (_) => LoginCubit(repo),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: ColumnButtonsLogin(
                    phone: TextEditingController(),
                    password: TextEditingController(),
                    formKey: GlobalKey<FormState>(),
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

  testWidgets('لا زرّ Google في شاشة الدخول', (tester) async {
    await pump(tester);

    expect(find.text('Google'), findsNothing);
  });

  testWidgets('ولا فاصلَه الذي يَعِد بوسيلة لا وجود لها', (tester) async {
    await pump(tester);

    expect(find.textContaining('الوسائل الاجتماعي'), findsNothing);
  });

  testWidgets('وما يخصّ الدخول بالبريد باقٍ كما هو', (tester) async {
    await pump(tester);

    expect(find.textContaining('ليس لديك حساب؟'), findsOneWidget,
        reason: 'الإخفاء يخصّ القسم الاجتماعي وحده');
  });

  test('العلم مطفأ — ويُعاد القسم بتحويله وحده', () {
    expect(kSocialLoginEnabled, isFalse);
  });
}
