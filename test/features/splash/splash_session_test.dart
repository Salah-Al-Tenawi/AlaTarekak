import 'dart:io';

import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'package:alatarekak/features/splash_view/presentaion/manger/cubit/splash_view_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepo extends Mock implements AuthRepoIm {}

/// إلى أين يذهب الإقلاع البارد، ومتى تُمسح الجلسة.
///
/// كان **أي** فشل في تجديد التوكن يمسح صندوق الجلسة ويطرد المستخدم إلى
/// شاشة البداية — بما فيه انقطاع الشبكة. فمن فتح التطبيق في نفق أو بشبكة
/// ضعيفة يفقد جلسة سليمة تماماً، ويُطالَب بكلمة مروره ورمز تحقّق.
///
/// والتوكن المنتهي لا يستحق ذلك أصلاً: `ApiInterceptor` يجدّده عند أول
/// 401 على طلب حقيقي، ويُخرج المستخدم إن رُفض التجديد فعلاً.
void main() {
  late MockAuthRepo repo;
  late Directory tempDir;

  const user = UserModel(
    id: 7,
    firstName: 'يزن',
    lastName: 'صلاح',
    email: 'me@example.com',
    accessToken: 'access',
    refreshToken: 'refresh',
  );

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('splash_session');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // قفل ملفات مؤقت على ويندوز — غير مؤثر
    }
  });

  setUp(() async {
    repo = MockAuthRepo();
    await HiveBoxes.authBox.clear();
  });

  /// يشغّل قرار الإقلاع ويُعيد وجهته.
  ///
  /// **القرار لا التنقّل**: الوصول إلى `Get` يستلزم شجرة ويدجت، وتلك
  /// تستلزم `testWidgets` الذي يُجمّد الزمن — فلا تُكمل عمليات Hive على
  /// القرص ويعلّق الاختبار على شيء لا يخصّ ما يفحصه.
  Future<SplashDestination> runSplash() async {
    final cubit = SplashCubit(repo, brandingDelay: Duration.zero);
    addTearDown(cubit.close);

    return cubit.resolveDestination();
  }

  group('تمييز رفض الجلسة عن فشل الاتصال', () {
    test('أكواد الخادم التي تعني رفضاً', () {
      for (final code in const [
        'REFRESH_TOKEN_INVALID',
        'TOKEN_INVALIDATED',
        'TOKEN_TYPE_INVALID',
        'TOKEN_INVALID',
        'TOKEN_MISSING',
        'USER_NOT_FOUND',
        'USER_INACTIVE',
        'USER_BANNED',
      ]) {
        expect(isSessionRejected(Filuar(message: 'x', code: code)), isTrue,
            reason: '«$code» رفضٌ صريح للجلسة');
      }
    });

    test('ونصوصها حين لا يرسل الخادم كوداً', () {
      for (final message in const [
        'Unauthenticated.',
        'Invalid refresh token',
        'Token has expired',
      ]) {
        expect(isSessionRejected(Filuar(message: message)), isTrue);
      }
    });

    test('**وأخطاء الاتصال ليست رفضاً** — وهي أصل العطل', () {
      // هذه نصوص `excptions.dart` نفسها لأنواع DioException
      for (final message in const [
        'تحقق من اتصال الإنترنت',
        'لا يوجد اتصال بالشبكة',
        'استغرق وقت طويل حاول مجدداً',
        'انتهت مهلة الاستلام، حاول مجدداً',
        'خطأ في الاتصال',
        'حدث خطأ غير معروف',
      ]) {
        expect(isSessionRejected(Filuar(message: message)), isFalse,
            reason: '«$message» عطل شبكة لا حكم على الجلسة');
      }
    });

    test('وخطأ خادم 500 ليس رفضاً', () {
      expect(
        isSessionRejected(const Filuar(message: 'Server Error', code: 'X')),
        isFalse,
      );
    });
  });

  group('الجلسة تنجو من عطل الشبكة', () {
    test('بلا إنترنت: يدخل التطبيق ولا يُمسح الصندوق', () async {
      await HiveBoxes.authBox.put(HiveKeys.user, user);
      when(() => repo.refreshToken(any())).thenAnswer(
          (_) async => left(const Filuar(message: 'تحقق من اتصال الإنترنت')));

      final visited = await runSplash();

      expect(visited, SplashDestination.home);
      expect(HiveBoxes.authBox.get(HiveKeys.user), isNotNull,
          reason: 'كانت الجلسة تُمسح فيفقد المستخدم دخوله بلا سبب');
    });

    test('مهلة منتهية: كذلك', () async {
      await HiveBoxes.authBox.put(HiveKeys.user, user);
      when(() => repo.refreshToken(any())).thenAnswer((_) async =>
          left(const Filuar(message: 'استغرق وقت طويل حاول مجدداً')));

      final visited = await runSplash();

      expect(visited, SplashDestination.home);
      expect(HiveBoxes.authBox.get(HiveKeys.user), isNotNull);
    });
  });

  group('ورفضُ الجلسة يُخرج فعلاً', () {
    test('توكن تجديد مرفوض: يُمسح الصندوق ويُذهب للبداية',
        () async {
      await HiveBoxes.authBox.put(HiveKeys.user, user);
      when(() => repo.refreshToken(any())).thenAnswer((_) async => left(
          const Filuar(
              message: 'Invalid refresh token',
              code: 'REFRESH_TOKEN_INVALID')));

      final visited = await runSplash();

      expect(visited, SplashDestination.onboarding);
      expect(HiveBoxes.authBox.get(HiveKeys.user), isNull);
    });

    test('جلسة أُبطلت من جهاز آخر', () async {
      await HiveBoxes.authBox.put(HiveKeys.user, user);
      when(() => repo.refreshToken(any())).thenAnswer((_) async =>
          left(const Filuar(message: 'x', code: 'TOKEN_INVALIDATED')));

      final visited = await runSplash();

      expect(visited, SplashDestination.onboarding);
      expect(HiveBoxes.authBox.get(HiveKeys.user), isNull);
    });
  });

  group('بقية المسارات', () {
    test('لا جلسة محفوظة: شاشة البداية بلا طلب شبكة', () async {
      final visited = await runSplash();

      expect(visited, SplashDestination.onboarding);
      verifyNever(() => repo.refreshToken(any()));
    });

    test('تجديد ناجح: الرئيسية', () async {
      await HiveBoxes.authBox.put(HiveKeys.user, user);
      when(() => repo.refreshToken(any()))
          .thenAnswer((_) async => right(unit));

      final visited = await runSplash();

      expect(visited, SplashDestination.home);
      expect(HiveBoxes.authBox.get(HiveKeys.user), isNotNull);
    });
  });

  test('الشبكة والشعار يجريان معاً لا بالتتابع', () async {
    await HiveBoxes.authBox.put(HiveKeys.user, user);
    when(() => repo.refreshToken(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return right(unit);
    });

    final cubit = SplashCubit(repo,
        brandingDelay: const Duration(milliseconds: 300));
    addTearDown(cubit.close);

    final started = DateTime.now();
    await cubit.resolveDestination();
    final elapsed = DateTime.now().difference(started).inMilliseconds;

    // شعار 300 وشبكة 200: بالتوازي ~300، وبالتتابع 500 فأكثر
    expect(elapsed, lessThan(450),
        reason: 'كان الطلب ينتظر انقضاء مهلة الشعار قبل أن يبدأ');
  });
}
