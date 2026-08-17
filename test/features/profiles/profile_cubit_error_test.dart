import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/profiles/data/repo/profile_repo_im.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepo extends Mock implements ProfileRepoIm {}

/// `ProfileErrorState.message` كانت تحمل **عربياً من مسار واحد وإنجليزياً
/// من ثلاثة**، وأربع شاشات تعرضها كما هي:
/// [profile_body] و[profile_my_cars] و[profile_edit_screen].
/// فالواجهة لا تملك ما تعرف به أتُرجمت الرسالة أم لا.

void main() {
  late MockProfileRepo repo;

  setUp(() {
    repo = MockProfileRepo();
  });

  group('ProfileCubit — عرض ملف مستخدم آخر', () {
    test('ملف غير موجود: رسالة عربية في الحالة', () async {
      when(() => repo.showProfile(any())).thenAnswer(
          (_) async => left(const Filuar(message: 'Profile not found')));
      final cubit = ProfileCubit(repo);

      // الدالة ترمي بعد بثّ الحالة (المستدعي يحتاج الاستثناء)، والمهم
      // هنا ما وصل الشاشة لا ما رُمي
      await expectLater(cubit.showOtherProfile(7), throwsException);

      final state = cubit.state as ProfileErrorState;
      expect(state.message, 'الملف الشخصي غير موجود');
      expect(state.message, isNot(contains('Profile not found')));
    });

    test('جلسة منتهية تُقال صراحةً لا «خطأ غير متوقع»', () async {
      when(() => repo.showProfile(any())).thenAnswer(
          (_) async => left(const Filuar(message: 'Unauthenticated.')));
      final cubit = ProfileCubit(repo);

      await expectLater(cubit.showOtherProfile(7), throwsException);

      expect((cubit.state as ProfileErrorState).message,
          HandelErorrMessage.errSession);
    });

    test('خطأ لا نعرفه لا يصل بنصّه الإنجليزي', () async {
      when(() => repo.showProfile(any())).thenAnswer((_) async =>
          left(const Filuar(message: 'Database connection lost')));
      final cubit = ProfileCubit(repo);

      await expectLater(cubit.showOtherProfile(7), throwsException);

      final state = cubit.state as ProfileErrorState;
      expect(state.message, HandelErorrMessage.errServer);
      expect(state.message, isNot(contains('Database')));
    });
  });
}
