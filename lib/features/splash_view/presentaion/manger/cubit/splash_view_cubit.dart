import 'package:get/get.dart';

import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';

/// أكواد الخادم التي تعني أن **الجلسة نفسها رُفضت** — وحدها تُخرج
/// المستخدم.
///
/// ما عداها (انقطاع شبكة، مهلة، خطأ خادم) ليس حكماً على الجلسة.
const _sessionRejectedCodes = {
  'REFRESH_TOKEN_INVALID',
  'TOKEN_INVALIDATED',
  'TOKEN_TYPE_INVALID',
  'TOKEN_INVALID',
  'TOKEN_MISSING',
  'USER_NOT_FOUND',
  'USER_INACTIVE',
  'USER_BANNED',
};

/// هل رفض الخادمُ الجلسةَ فعلاً؟
///
/// **قائمة سماح لا قائمة منع**: عند الشكّ تبقى الجلسة. الخطأ في اتجاه
/// «أخرجه» يكلّف المستخدم كلمة مروره ورمز تحقّق، والخطأ في الاتجاه الآخر
/// يكلّفه ضغطة على شاشة تظهر له بعد قليل — والمُعترِض يحسم الأمر عند أول
/// طلب حقيقي.
bool isSessionRejected(Filuar error) {
  final code = error.code?.trim().toUpperCase();
  if (code != null && _sessionRejectedCodes.contains(code)) return true;

  // بعض معالِجات الخادم تُرجع 401 بلا `code` — يبقى النصّ دليلاً
  final message = error.message.toLowerCase();
  return message.contains('unauthenticated') ||
      message.contains('invalid refresh') ||
      message.contains('refresh token') ||
      message.contains('token has expired') ||
      message.contains('token is invalid');
}

/// إلى أين ينتهي الإقلاع.
enum SplashDestination { home, onboarding }

class SplashCubit extends SafeCubit<void> {
  final AuthRepoIm authRepoIm;

  /// مدّة عرض الشعار — تجري **بموازاة** الشبكة لا قبلها.
  ///
  /// وسيطٌ لا ثابت: الاختبارات تقصّرها فلا تنتظر ثانيتين لكل حالة.
  final Duration brandingDelay;

  SplashCubit(
    this.authRepoIm, {
    this.brandingDelay = const Duration(seconds: 2),
  }) : super(null);

  Future<void> initApp() async {
    final destination = await resolveDestination();

    Get.offAllNamed(destination == SplashDestination.home
        ? RouteName.home
        : RouteName.onboarding);
  }

  /// **القرار وحده، بلا تنقّل.**
  ///
  /// فُصل عن [initApp] ليُختبر مباشرةً: الاختبار الذي يحتاج شجرة ويدجت
  /// ليصل إلى `Get` يُجبَر على `testWidgets`، وذاك يُجمّد الزمن فلا تُكمل
  /// عمليات Hive على القرص — فيعلّق الاختبار على شيء لا يخصّ ما يفحصه.
  Future<SplashDestination> resolveDestination() async {
    // كانت الشبكة تنتظر انقضاء الثانيتين ثم تبدأ، فيكلّف الإقلاع البارد
    // ثانيتين **زائد** رحلة الشبكة. الآن يكلّف أطولهما.
    final branding = Future<void>.delayed(brandingDelay);

    try {
      final user = HiveBoxes.authBox.get(HiveKeys.user);

      if (user == null) {
        await branding;
        return SplashDestination.onboarding;
      }

      final result = await authRepoIm.refreshToken(user.refreshToken);
      await branding;

      return await result.fold(
        (error) async {
          // **لا يُخرَج المستخدم إلا برفضٍ صريح للجلسة.**
          //
          // كان أي فشل يمسح الصندوق: من فتح التطبيق بلا إنترنت — في نفق
          // أو بشبكة ضعيفة — يُطرد إلى شاشة التسجيل ويفقد جلسته، وهي
          // سليمة تماماً. والتوكن المنتهي ليس حالة استثنائية تستحق ذلك:
          // `ApiInterceptor` يجدّده عند أول 401 على طلب حقيقي، ويُخرج
          // المستخدم إن رُفض التجديد فعلاً.
          if (!isSessionRejected(error)) return SplashDestination.home;

          await HiveBoxes.authBox.clear();
          return SplashDestination.onboarding;
        },
        (_) async => SplashDestination.home,
      );
    } catch (_) {
      // تعذّر قراءة الجلسة أصلاً — لا سبيل إلا شاشة البداية
      await branding;
      return SplashDestination.onboarding;
    }
  }
}
