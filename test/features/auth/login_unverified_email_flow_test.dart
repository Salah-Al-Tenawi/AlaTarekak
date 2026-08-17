import 'dart:async';

import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/auth/presentation/manger/login_cubit/login_cubit.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/buttons_login.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

/// الدخول ببريد غير مؤكَّد.
///
/// الخادم يردّ 403 مع `code: EMAIL_NOT_VERIFIED`، وكانت الشاشة تعرضه
/// كفشل دخول عادي: رسالة تقول «حدث خطأ غير متوقع» (لأن النصّ لم يكن في
/// خريطة الترجمة) ولا سبيل للمستخدم إلى إدخال رمزه ولا طلب رمز جديد.

class _Recorder extends NavigatorObserver {
  final List<String> routes = [];
  final List<Object?> arguments = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) {
      routes.add(name);
      arguments.add(route.settings.arguments);
    }
    super.didPush(route, previousRoute);
  }
}

void main() {
  late MockLoginCubit cubit;
  late _Recorder recorder;

  setUp(() {
    cubit = MockLoginCubit();
    recorder = _Recorder();
    Get.testMode = true;
  });

  Future<void> pump(WidgetTester tester, LoginState state) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // البثّ بيدنا لا من قائمة جاهزة: القائمة تُسلَّم لحظة الاستماع أثناء
    // أول pump، فتضيع الانتقالات قبل أن نُصفّر الراصد من مسار الجذر
    final controller = StreamController<LoginState>.broadcast();
    addTearDown(controller.close);
    whenListen(cubit, controller.stream, initialState: LoginInitial());

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: GetMaterialApp(
          navigatorObservers: [recorder],
          textDirection: TextDirection.rtl,
          locale: const Locale('ar'),
          home: Scaffold(
            body: BlocProvider<LoginCubit>.value(
              value: cubit,
              child: ColumnButtonsLogin(
                phone: TextEditingController(),
                password: TextEditingController(),
                formKey: GlobalKey<FormState>(),
              ),
            ),
          ),
          getPages: [
            GetPage(
              name: RouteName.verfiyEmailSingin,
              page: () => const Scaffold(body: Text('شاشة الرمز')),
            ),
            GetPage(
              name: RouteName.home,
              page: () => const Scaffold(body: Text('الرئيسية')),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    // مسار الجذر دُفع عند الإقلاع — لا يعنينا
    recorder.routes.clear();
    recorder.arguments.clear();

    controller.add(state);
    await tester.pumpAndSettle();
  }

  testWidgets('بريد غير مؤكَّد ينقل إلى شاشة الرمز حاملاً البريد',
      (tester) async {
    await pump(tester, const LoginEmailNotVerified('itsalah736@gmail.com'));

    expect(recorder.routes, contains(RouteName.verfiyEmailSingin));
    expect(recorder.arguments.last, 'itsalah736@gmail.com',
        reason: 'شاشة الرمز تحتاج البريد للتحقق ولإعادة الإرسال');
  });

  testWidgets('يُشرح له بالعربية ما ينقصه', (tester) async {
    await pump(tester, const LoginEmailNotVerified('itsalah736@gmail.com'));

    expect(find.textContaining('لم يتم تأكيد بريدك'), findsWidgets);
  });

  testWidgets('فشل دخول عادي لا ينقل إلى شاشة الرمز', (tester) async {
    await pump(tester, const LoginError('Invalid credentials'));

    expect(recorder.routes, isNot(contains(RouteName.verfiyEmailSingin)));
  });

  group('نصّ الخطأ لو تعذّر الانتقال', () {
    test('رسالة البريد غير المؤكَّد معرَّبة لا عامة', () {
      const raw = 'Your email address is not verified. Please check your '
          'inbox for the verification code.';

      expect(HandelErorrMessage.isEmailNotVerified(raw), isTrue);
      expect(HandelErorrMessage.login(raw),
          isNot(HandelErorrMessage.errServer));
      expect(HandelErorrMessage.login(raw), contains('لم يتم تأكيد بريدك'));
    });

    test('الكاشف لا يُطلق على أخطاء الدخول الأخرى', () {
      expect(HandelErorrMessage.isEmailNotVerified('Invalid credentials'),
          isFalse);
    });
  });
}
