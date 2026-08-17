import 'dart:io';

import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:hive/hive.dart';
import 'package:alatarekak/features/profiles/data/repo/profile_repo_im.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepo extends Mock implements ProfileRepoIm {}

/// كاش الملف الشخصي.
///
/// كان يُقرأ **عند فشل الشبكة فقط**: كل فتح لتبويب «حسابي» يبدأ بمؤشّر
/// تحميل وينتظر ردّ الخادم، رغم أن النسخة المخزَّنة جاهزة على القرص.

ProfileEntity _profile({String name = 'يزن صلاح', int score = 72}) =>
    ProfileEntity(
      fullname: name,
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
  late MockProfileRepo repo;
  late Directory tempDir;

  // `showMyProfile` تقرأ معرّف المستخدم من صندوق الجلسة — يُهيّأ صندوق
  // حقيقي على مجلد مؤقّت بدل محاكاة دالة عليا.
  setUp(() async {
    repo = MockProfileRepo();
    tempDir = await Directory.systemTemp.createTemp('profile_cache_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    final box = await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
    await box.put(
      HiveKeys.user,
      const UserModel(
        id: 7,
        firstName: 'يزن',
        lastName: 'صلاح',
        email: 'me@example.com',
        accessToken: 'a',
        refreshToken: 'r',
      ),
    );
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('عرض الملف من الكاش قبل الشبكة', () {
    test('نسخة مخزَّنة تظهر فوراً — بلا مؤشّر تحميل', () async {
      when(() => repo.getCachedProfile(any())).thenReturn(_profile());
      when(() => repo.showProfile(any()))
          .thenAnswer((_) async => right(_profile(name: 'من الشبكة')));

      final cubit = ProfileCubit(repo);
      final states = <ProfileState>[];
      cubit.stream.listen(states.add);

      await cubit.showMyProfile();
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<ProfileLoadedState>(),
          reason: 'أول حالة بيانات لا انتظار');
      expect((states.first as ProfileLoadedState).profileEntity!.fullname,
          'يزن صلاح');
      expect(states.any((s) => s is ProfileLoadingState), isFalse,
          reason: 'المؤشّر كان يظهر رغم وجود نسخة جاهزة');
    });

    test('ثم يُستبدل بما يردّه الخادم', () async {
      when(() => repo.getCachedProfile(any())).thenReturn(_profile());
      when(() => repo.showProfile(any()))
          .thenAnswer((_) async => right(_profile(name: 'الاسم الجديد')));

      final cubit = ProfileCubit(repo);
      await cubit.showMyProfile();

      final state = cubit.state as ProfileLoadedState;
      expect(state.profileEntity!.fullname, 'الاسم الجديد');
      expect(state.mode, ProfileMode.myView);
    });

    test('بلا كاش يبقى السلوك كما كان — مؤشّر ثم بيانات', () async {
      when(() => repo.getCachedProfile(any())).thenReturn(null);
      when(() => repo.showProfile(any()))
          .thenAnswer((_) async => right(_profile()));

      final cubit = ProfileCubit(repo);
      final states = <ProfileState>[];
      cubit.stream.listen(states.add);

      await cubit.showMyProfile();
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<ProfileLoadingState>());
      expect(states.last, isA<ProfileLoadedState>());
    });

    test('لا يُطلب الملف من الشبكة أكثر من مرة في التحميل الواحد',
        () async {
      when(() => repo.getCachedProfile(any())).thenReturn(_profile());
      when(() => repo.showProfile(any()))
          .thenAnswer((_) async => right(_profile()));

      final cubit = ProfileCubit(repo);
      await cubit.showMyProfile();

      verify(() => repo.showProfile(any())).called(1);
    });
  });

  group('فشل الشبكة', () {
    test('المستودع يسقط للكاش فلا تُمسح الشاشة', () async {
      // showProfile نفسه يعيد الكاش عند ServerExpcptions — فالنتيجة right
      when(() => repo.getCachedProfile(any())).thenReturn(_profile());
      when(() => repo.showProfile(any()))
          .thenAnswer((_) async => right(_profile()));

      final cubit = ProfileCubit(repo);
      await cubit.showMyProfile();

      expect(cubit.state, isA<ProfileLoadedState>());
    });

    test('فشل بلا كاش إطلاقاً: حالة خطأ معرَّبة ويُرمى للمستدعي', () async {
      when(() => repo.getCachedProfile(any())).thenReturn(null);
      when(() => repo.showProfile(any())).thenAnswer(
          (_) async => left(const Filuar(message: 'Profile not found')));

      final cubit = ProfileCubit(repo);

      await expectLater(cubit.showMyProfile(), throwsException);
      expect((cubit.state as ProfileErrorState).message,
          'الملف الشخصي غير موجود');
    });
  });
}
