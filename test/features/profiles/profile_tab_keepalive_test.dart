import 'dart:io';

import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

/// تبويب «حسابي» صفحة داخل `PageView` في الرئيسية، و`PageView` يتخلّص من
/// الصفحات غير المعروضة. فكان `initState` يُعاد في **كل** تنقّل إلى
/// التبويب، ومعه طلب جديد إلى الخادم — والملف الشخصي لا يتغيّر بين
/// ضغطتين على شريط التنقّل.

ProfileEntity _profile() => ProfileEntity(
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
      scoreValue: 72,
    );

void main() {
  late MockProfileCubit cubit;
  late Directory tempDir;

  setUp(() async {
    cubit = MockProfileCubit();
    Get.testMode = true;
    when(() => cubit.showMyProfile()).thenAnswer((_) async => _profile());
    whenListen(
      cubit,
      const Stream<ProfileState>.empty(),
      initialState: ProfileLoadedState(
        mode: ProfileMode.myView,
        profileEntity: _profile(),
      ),
    );

    tempDir = await Directory.systemTemp.createTemp('profile_tab_test');
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

  testWidgets('التنقّل بعيداً عن التبويب والعودة إليه لا يُعيد الطلب',
      (tester) async {
    tester.view.physicalSize = const Size(375, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider<ProfileCubit>.value(
              value: cubit,
              // نفس بنية الرئيسية: PageView بصفحات لا تُبقى حيّة تلقائياً
              child: PageView(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  Profile(),
                  Scaffold(body: Text('تبويب آخر')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    verify(() => cubit.showMyProfile()).called(1);

    // ابتعد إلى تبويب آخر ثم عُد
    controller.jumpToPage(1);
    await tester.pump(const Duration(milliseconds: 600));
    controller.jumpToPage(0);
    await tester.pump(const Duration(milliseconds: 600));

    verifyNever(() => cubit.showMyProfile());
  });

  testWidgets('السحب للتحديث يبقى قادراً على إعادة الطلب', (tester) async {
    tester.view.physicalSize = const Size(375, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider<ProfileCubit>.value(
              value: cubit,
              child: const Profile(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    verify(() => cubit.showMyProfile()).called(1);

    // استدعاء المُحدِّث مباشرةً بدل محاكاة السحب: المقصود أن الطريق إلى
    // إعادة التحميل ما زال موصولاً بعد إبقاء الصفحة حيّة
    final indicator =
        tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await indicator.onRefresh();
    await tester.pump();

    verify(() => cubit.showMyProfile()).called(1);
  });
}
