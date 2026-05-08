import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:alatarekak/core/route/route_app.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/cubit_observer.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/service/locator_ser.dart';
import 'package:alatarekak/core/them/them_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = MyBlocObserver();
  locatorService();
  await HiveService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      child: GetMaterialApp(
        title: "state mangment with cubit and navigation by getx",
      initialRoute: RouteName.splashView,
      
        getPages: appRoute,
        theme: ThemApp.lightThem,
        debugShowCheckedModeBanner: false,
        textDirection: TextDirection.rtl,
        locale: const Locale('ar'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
      ),
    );  
  }
}
