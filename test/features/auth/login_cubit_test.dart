import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'package:alatarekak/features/auth/presentation/manger/login_cubit/login_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepo extends Mock implements AuthRepoIm {}

void main() {
  late MockAuthRepo authRepo;

  const testUser = UserModel(
    id: 1,
    firstName: 'يزن',
    lastName: 'صلاح',
    email: 'test@example.com',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  );

  setUp(() {
    authRepo = MockAuthRepo();
  });

  group('LoginCubit', () {
    test('الحالة الابتدائية LoginInitial', () {
      expect(LoginCubit(authRepo).state, isA<LoginInitial>());
    });

    blocTest<LoginCubit, LoginState>(
      'نجاح الدخول: Loading ثم Success',
      build: () {
        when(() => authRepo.signInWithEmail('test@example.com', '12345678'))
            .thenAnswer((_) async => right(testUser));
        return LoginCubit(authRepo);
      },
      act: (cubit) => cubit.login('test@example.com', '12345678'),
      expect: () => [isA<LoginLoading>(), isA<LoginSuccess>()],
      verify: (_) {
        verify(() =>
                authRepo.signInWithEmail('test@example.com', '12345678'))
            .called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      'فشل الدخول: Loading ثم Error برسالة الباك إند',
      build: () {
        when(() => authRepo.signInWithEmail(any(), any())).thenAnswer(
            (_) async => left(const Filuar(message: 'Invalid credentials')));
        return LoginCubit(authRepo);
      },
      act: (cubit) => cubit.login('test@example.com', 'wrong-pass'),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginError>()
            .having((s) => s.message, 'message', 'Invalid credentials'),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'التنقل لإنشاء حساب ثم العودة للحالة الابتدائية',
      build: () => LoginCubit(authRepo),
      act: (cubit) => cubit.emitgotoSingin(),
      expect: () => [isA<LoginNavigateToSignup>(), isA<LoginInitial>()],
    );

    blocTest<LoginCubit, LoginState>(
      'التنقل لاستعادة كلمة المرور ثم العودة للحالة الابتدائية',
      build: () => LoginCubit(authRepo),
      act: (cubit) => cubit.emitGotoForgetPassword(),
      expect: () =>
          [isA<LoginNavigationToForgetPassword>(), isA<LoginInitial>()],
    );
  });
}
