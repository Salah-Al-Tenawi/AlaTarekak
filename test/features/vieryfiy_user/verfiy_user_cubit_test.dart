import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/vieryfiy_user/data/model/verifiy_user_modle.dart';
import 'package:alatarekak/features/vieryfiy_user/data/repo/verfiy_user_repo.dart';
import 'package:alatarekak/features/vieryfiy_user/presintion/manger/cubit/verfiy_user_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockVerfiyRepo extends Mock implements VerfiYUserRepo {}

class FakeXFile extends Fake implements XFile {}

/// شاشة التوثيق كانت تعرض رسالة الخادم كما وصلت:
/// «You already have a pending verification request» بالإنجليزية،
/// رغم أن الترجمة جاهزة في ملف الرسائل منذ كُتب.

void main() {
  late MockVerfiyRepo repo;

  setUpAll(() {
    registerFallbackValue(FakeXFile());
  });

  setUp(() {
    repo = MockVerfiyRepo();
  });

  void stubDriver(Either<Filuar, VerifiyUserModle> result) {
    when(() => repo.verfiyDriver(any(), any(), any(), any()))
        .thenAnswer((_) async => result);
  }

  void stubPassenger(Either<Filuar, VerifiyUserModle> result) {
    when(() => repo.verfiyPassanger(any(), any()))
        .thenAnswer((_) async => result);
  }

  group('VerifyUserCubit — توثيق السائق', () {
    blocTest<VerifyUserCubit, VerfiyUserState>(
      'طلب معلّق: رسالة عربية لا نصّ الخادم',
      build: () {
        stubDriver(left(const Filuar(
            message: 'You already have a pending verification request')));
        return VerifyUserCubit(verfiYUserRepo: repo);
      },
      act: (cubit) => cubit.submitDriverImages(),
      expect: () => [
        isA<VerfiyLoading>(),
        isA<VerfiyError>()
            .having((s) => s.message, 'message',
                'لديك طلب توثيق قيد المراجعة بالفعل')
            .having((s) => s.message, 'بلا إنجليزية',
                isNot(contains('pending'))),
      ],
    );

    blocTest<VerifyUserCubit, VerfiyUserState>(
      'صورة مرفوضة: شرح الصيغة والحجم بالعربية',
      build: () {
        stubDriver(left(const Filuar(
            message: 'The face id pic must be an image of type: jpg, png.')));
        return VerifyUserCubit(verfiYUserRepo: repo);
      },
      act: (cubit) => cubit.submitDriverImages(),
      expect: () => [
        isA<VerfiyLoading>(),
        isA<VerfiyError>().having((s) => s.message, 'message',
            'يجب أن تكون الصورة بصيغة JPG أو PNG وبحجم أقصى 2 ميغابايت'),
      ],
    );

    blocTest<VerifyUserCubit, VerfiyUserState>(
      'جلسة منتهية أثناء الرفع تُقال صراحةً',
      build: () {
        stubDriver(left(const Filuar(message: 'Unauthenticated.')));
        return VerifyUserCubit(verfiYUserRepo: repo);
      },
      act: (cubit) => cubit.submitDriverImages(),
      expect: () => [
        isA<VerfiyLoading>(),
        isA<VerfiyError>().having(
            (s) => s.message, 'message', HandelErorrMessage.errSession),
      ],
    );
  });

  group('VerifyUserCubit — توثيق الراكب', () {
    blocTest<VerifyUserCubit, VerfiyUserState>(
      'طلب معلّق: الرسالة نفسها معرّبة',
      build: () {
        stubPassenger(left(const Filuar(
            message: 'You already have a pending verification request')));
        return VerifyUserCubit(verfiYUserRepo: repo);
      },
      act: (cubit) => cubit.submitPassengerImages(),
      expect: () => [
        isA<VerfiyLoading>(),
        isA<VerfiyError>().having((s) => s.message, 'message',
            'لديك طلب توثيق قيد المراجعة بالفعل'),
      ],
    );

    blocTest<VerifyUserCubit, VerfiyUserState>(
      'خطأ لا نعرفه لا يصل بنصّه الإنجليزي',
      build: () {
        stubPassenger(
            left(const Filuar(message: 'Some unexpected server failure')));
        return VerifyUserCubit(verfiYUserRepo: repo);
      },
      act: (cubit) => cubit.submitPassengerImages(),
      expect: () => [
        isA<VerfiyLoading>(),
        isA<VerfiyError>()
            .having(
                (s) => s.message, 'message', HandelErorrMessage.errServer)
            .having((s) => s.message, 'بلا إنجليزية',
                isNot(contains('unexpected server'))),
      ],
    );
  });
}
