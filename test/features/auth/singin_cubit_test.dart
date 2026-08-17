import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/sing_up_params.dart';
import 'package:alatarekak/features/auth/presentation/manger/singin_cubit/singin_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepo extends Mock implements AuthRepoIm {}

void main() {
  late MockAuthRepo repo;

  const testUser = UserModel(
    id: 1,
    firstName: 'يزن',
    lastName: 'صلاح',
    email: 'new@example.com',
    accessToken: 'access',
    refreshToken: 'refresh',
  );

  setUpAll(() {
    registerFallbackValue(SignUpParams(
      firstName: 'x',
      lastName: 'x',
      gender: 'M',
      email: 'x@x.com',
      address: 'x',
      password: 'x',
      confirmPassword: 'x',
      phoneNumber: '0999999999',
    ));
  });

  setUp(() {
    repo = MockAuthRepo();
  });

  group('SinginCubit — إنشاء حساب', () {
    blocTest<SinginCubit, SinginState>(
      'نجاح التسجيل: ينتقل لشاشة تحقق OTP بنفس البريد',
      build: () {
        when(() => repo.signIn(any())).thenAnswer((_) async => right(unit));
        return SinginCubit(repo);
      },
      act: (cubit) => cubit.signIn('يزن', 'صلاح', 'M', 'new@example.com',
          'دمشق', '12345678', '12345678', '0999999999'),
      expect: () => [
        isA<SinginLoading>(),
        isA<SingInGotoVerfiyOtp>()
            .having((s) => s.email, 'email', 'new@example.com'),
      ],
    );

    // كان هذا الاختبار يُثبّت تمرير النصّ الإنجليزي كما هو — والشاشة
    // تعرض `state.message` مباشرة، فيقرأ المستخدم رسالة الخادم بالإنجليزية.
    blocTest<SinginCubit, SinginState>(
      'بريد مسجل مسبقاً: رسالة عربية تدلّه على تسجيل الدخول',
      build: () {
        when(() => repo.signIn(any())).thenAnswer((_) async =>
            left(const Filuar(message: 'Email already registered')));
        return SinginCubit(repo);
      },
      act: (cubit) => cubit.signIn('يزن', 'صلاح', 'M', 'dup@example.com',
          'دمشق', '12345678', '12345678', '0999999999'),
      expect: () => [
        isA<SinginLoading>(),
        isA<SinginErorre>()
            .having((s) => s.message, 'message',
                'هذا البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول')
            .having((s) => s.message, 'بلا إنجليزية',
                isNot(contains('already registered'))),
      ],
    );

    blocTest<SinginCubit, SinginState>(
      'فشل تسجيل لا نعرفه لا يصل بنصّه الإنجليزي',
      build: () {
        when(() => repo.signIn(any())).thenAnswer((_) async =>
            left(const Filuar(message: 'Unexpected database failure')));
        return SinginCubit(repo);
      },
      act: (cubit) => cubit.signIn('يزن', 'صلاح', 'M', 'x@example.com',
          'دمشق', '12345678', '12345678', '0999999999'),
      expect: () => [
        isA<SinginLoading>(),
        isA<SinginErorre>().having(
            (s) => s.message, 'message', HandelErorrMessage.errServer),
      ],
    );
  });

  group('SinginCubit — تحقق OTP', () {
    blocTest<SinginCubit, SinginState>(
      'رمز أقصر من 6 أرقام: لا يُرسل أي طلب ولا تتغير الحالة',
      build: () => SinginCubit(repo),
      act: (cubit) async {
        cubit.onOtpChanged('123');
        await cubit.checkOtp('new@example.com');
      },
      expect: () => [isA<SinginOtpChanged>()],
      verify: (_) =>
          verifyNever(() => repo.verifySinginOtp(any(), any())),
    );

    blocTest<SinginCubit, SinginState>(
      'رمز صحيح مكتمل: SinginSuccess ببيانات المستخدم',
      build: () {
        when(() => repo.verifySinginOtp('new@example.com', '123456'))
            .thenAnswer((_) async => right(testUser));
        return SinginCubit(repo);
      },
      act: (cubit) async {
        cubit.onOtpChanged('123456');
        await cubit.checkOtp('new@example.com');
      },
      expect: () => [
        isA<SinginOtpChanged>(),
        isA<SinginLoading>(),
        isA<SinginSuccess>()
            .having((s) => s.authModel.email, 'email', 'new@example.com'),
      ],
    );

    blocTest<SinginCubit, SinginState>(
      'رمز خاطئ: SinginErorre',
      build: () {
        when(() => repo.verifySinginOtp(any(), any())).thenAnswer((_) async =>
            left(const Filuar(
                message: 'Invalid or expired verification code')));
        return SinginCubit(repo);
      },
      act: (cubit) async {
        cubit.onOtpChanged('000000');
        await cubit.checkOtp('new@example.com');
      },
      expect: () => [
        isA<SinginOtpChanged>(),
        isA<SinginLoading>(),
        isA<SinginErorre>()
            .having((s) => s.message, 'message',
                'الرمز غير صحيح أو منتهي الصلاحية')
            .having((s) => s.message, 'بلا إنجليزية',
                isNot(contains('Invalid or expired'))),
      ],
    );

    // نفس الحالة (SinginErorre) تُبثّ من التسجيل ومن تأكيد الرمز، فلا
    // تستطيع الشاشة أن تفرّق — لذلك تُترجم كلٌّ في موضعها من الكيوبت.
    blocTest<SinginCubit, SinginState>(
      'إعادة إرسال الرمز: فشلها معرَّب كذلك',
      build: () {
        when(() => repo.resendOtpSinging(any())).thenAnswer((_) async =>
            left(const Filuar(message: 'Failed to send verification email')));
        return SinginCubit(repo);
      },
      act: (cubit) => cubit.sendOtpAgain('new@example.com'),
      expect: () => [
        isA<SinginResendOtpLoading>(),
        isA<SinginResendOtpError>()
            .having((s) => s.message, 'message', 'تعذر إرسال البريد، حاول مجدداً')
            .having((s) => s.message, 'بلا إنجليزية',
                isNot(contains('Failed to send'))),
      ],
    );
  });

  group('SinginCubit — حالات الواجهة', () {
    blocTest<SinginCubit, SinginState>(
      'تغيير الجنس يحدّث الحقل ويصدر الحالة',
      build: () => SinginCubit(repo),
      act: (cubit) => cubit.emitChangeGender('F'),
      expect: () =>
          [isA<SinginChangeGender>().having((s) => s.gender, 'gender', 'F')],
      verify: (cubit) => expect(cubit.gender, 'F'),
    );
  });
}
