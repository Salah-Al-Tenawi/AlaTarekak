import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/reset_password_params.dart';
import 'package:alatarekak/features/auth/presentation/manger/forget_password_cubit/forget_password_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepo extends Mock implements AuthRepoIm {}

void main() {
  late MockAuthRepo repo;

  setUpAll(() {
    registerFallbackValue(ResetPasswordParams(
      resetToken: 'x',
      newPassword: 'x',
      confirmPassword: 'x',
    ));
  });

  setUp(() {
    repo = MockAuthRepo();
  });

  group('ForgetPasswordCubit — الخطوة 1: إرسال البريد', () {
    blocTest<ForgetPasswordCubit, ForgetPasswordState>(
      'نجاح الإرسال: ينتقل لشاشة OTP',
      build: () {
        when(() => repo.forgotPassword('me@example.com'))
            .thenAnswer((_) async => right(unit));
        return ForgetPasswordCubit(repo);
      },
      act: (cubit) => cubit.sendEmail('me@example.com'),
      expect: () => [
        isA<ForgetPasswordLoading>(),
        isA<ForgetPasswordGoToOtp>()
            .having((s) => s.email, 'email', 'me@example.com'),
      ],
    );

    blocTest<ForgetPasswordCubit, ForgetPasswordState>(
      'بريد غير مسجل: ForgetPasswordErorr',
      build: () {
        when(() => repo.forgotPassword(any())).thenAnswer((_) async =>
            left(const Filuar(message: 'No account found with this email')));
        return ForgetPasswordCubit(repo);
      },
      act: (cubit) => cubit.sendEmail('ghost@example.com'),
      expect: () =>
          [isA<ForgetPasswordLoading>(), isA<ForgetPasswordErorr>()],
    );
  });

  group('ForgetPasswordCubit — الخطوة 2: تحقق OTP', () {
    blocTest<ForgetPasswordCubit, ForgetPasswordState>(
      'رمز غير مكتمل: لا طلب ولا حالة جديدة',
      build: () => ForgetPasswordCubit(repo),
      act: (cubit) async {
        cubit.onOtpChanged('12');
        await cubit.verifyOtp('me@example.com');
      },
      expect: () => [isA<ForgetPasswordOtpChanged>()],
      verify: (_) =>
          verifyNever(() => repo.verifyOtpResetPassword(any(), any())),
    );

    blocTest<ForgetPasswordCubit, ForgetPasswordState>(
      'رمز صحيح: OtpVerified يحمل resetToken من الخادم',
      build: () {
        when(() => repo.verifyOtpResetPassword('me@example.com', '123456'))
            .thenAnswer((_) async => right('reset-token-xyz'));
        return ForgetPasswordCubit(repo);
      },
      act: (cubit) async {
        cubit.onOtpChanged('123456');
        await cubit.verifyOtp('me@example.com');
      },
      expect: () => [
        isA<ForgetPasswordOtpChanged>(),
        isA<ForgetPasswordLoading>(),
        isA<ForgetPasswordOtpVerified>()
            .having((s) => s.resetToken, 'resetToken', 'reset-token-xyz')
            .having((s) => s.email, 'email', 'me@example.com'),
      ],
    );
  });

  group('ForgetPasswordCubit — الخطوة 3: إعادة التعيين', () {
    blocTest<ForgetPasswordCubit, ForgetPasswordState>(
      'نجاح إعادة تعيين كلمة المرور',
      build: () {
        when(() => repo.resetPassword(any()))
            .thenAnswer((_) async => right(unit));
        return ForgetPasswordCubit(repo);
      },
      act: (cubit) => cubit.resetPassword(
          resetToken: 'reset-token-xyz', newPassword: 'newPass123'),
      expect: () =>
          [isA<ForgetPasswordLoading>(), isA<ForgetPasswordResetSuccess>()],
    );

    blocTest<ForgetPasswordCubit, ForgetPasswordState>(
      'رمز إعادة تعيين منتهي: ForgetPasswordErorr',
      build: () {
        when(() => repo.resetPassword(any())).thenAnswer((_) async => left(
            const Filuar(
                message: 'Reset token expired or has already been used')));
        return ForgetPasswordCubit(repo);
      },
      act: (cubit) => cubit.resetPassword(
          resetToken: 'stale', newPassword: 'newPass123'),
      expect: () =>
          [isA<ForgetPasswordLoading>(), isA<ForgetPasswordErorr>()],
    );

    blocTest<ForgetPasswordCubit, ForgetPasswordState>(
      'تبديل إظهار كلمتي المرور يصدر حالة الرؤية الصحيحة',
      build: () => ForgetPasswordCubit(repo),
      act: (cubit) {
        cubit.toggleNewPassword();
        cubit.toggleConfirmPassword();
      },
      expect: () => [
        isA<ForgetPasswordPasswordVisible>()
            .having((s) => s.isNewVisible, 'new', isTrue)
            .having((s) => s.isConfirmVisible, 'confirm', isFalse),
        isA<ForgetPasswordPasswordVisible>()
            .having((s) => s.isNewVisible, 'new', isTrue)
            .having((s) => s.isConfirmVisible, 'confirm', isTrue),
      ],
    );
  });
}
