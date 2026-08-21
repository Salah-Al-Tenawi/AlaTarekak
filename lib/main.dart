import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/utils/class/adaptive_design.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:alatarekak/core/route/route_app.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/connectivity_service.dart';
import 'package:alatarekak/core/service/cubit_observer.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/service/locator_ser.dart';
import 'package:alatarekak/core/service/push_token_service.dart';
import 'package:alatarekak/core/them/theme_controller.dart';
import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/core/utils/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = MyBlocObserver();
  locatorService();
  await HiveService.init();
  ThemeController.instance.load();
  // NFR-17: مراقبة الاتصال — تغذي شريط "لا يوجد اتصال" العام
  ConnectivityService.instance.init();
  // FCM: يسجل التوكن إن كان المستخدم مسجلاً دخوله، ويعطل نفسه إن لم يُهيأ Firebase
  PushTokenService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // مقاس التصميم يُشتقّ من الشاشة لا يُثبَّت: تابلتٌ عرضه 800 كان
    // يضاعف كل خطّ وحشوة مرّتين — انظر [adaptiveDesignSize].
    return LayoutBuilder(
      builder: (context, constraints) => ScreenUtilInit(
        designSize: adaptiveDesignSize(constraints.biggest),
        minTextAdapt: true,
        child: ValueListenableBuilder<bool>(
        valueListenable: ThemeController.instance.isDark,
        builder: (context, isDark, _) {
          return GetMaterialApp(
            title: "عطريقك",
            initialRoute: RouteName.splashView,
            getPages: appRoute,
            theme: isDark ? ThemApp.darkThem : ThemApp.lightThem,
            debugShowCheckedModeBanner: false,
            // انتقال ناعم موحد بين كل الشاشات (خفيف ومحايد للاتجاه RTL)
            defaultTransition: Transition.fadeIn,
            transitionDuration: const Duration(milliseconds: 260),
            // NFR-17: شريط انقطاع الاتصال فوق كل الشاشات
            builder: (context, child) => OfflineBanner(
              isOffline: ConnectivityService.instance.isOffline,
              child: child ?? const SizedBox.shrink(),
            ),
            textDirection: TextDirection.rtl,
            locale: const Locale('ar'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar'), Locale('en')],
          );
          },
        ),
      ),
    );
  }
}
