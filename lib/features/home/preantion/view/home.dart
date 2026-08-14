import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/chat/presentation/view/chat_list_screen.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/features/home/preantion/manger/cubit/home_nav_cubit_cubit.dart';
import 'package:alatarekak/features/home/preantion/view/widget/home_botom_nav_bar.dart';
import 'package:alatarekak/features/home/preantion/view/widget/home_drawer.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/view/booking_user_in_trip.dart';
import 'package:alatarekak/features/trip_me/presantion/view/trip_me_list.dart';
import 'package:alatarekak/features/trip_search/presantion/view/trip_search.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final _pageController = PageController(initialPage: 2);

  /// يُعاد تشغيله عند كل تبديل تبويب ليُظهر المحتوى الجديد بتلاشٍ.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppAnim.entrance,
    value: 1,
  );

  // الموافقة على السياسات صارت شرطاً سابقاً لإنشاء الحساب في شاشة
  // التسجيل، فلم يعد لحوار الموافقة المؤجَّل هنا معنى: كان يظهر بعد
  // إنشاء الحساب وإرسال بياناته بثلاث ثوانٍ.

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        
         floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, // 👈 أضف هذا السطر
  floatingActionButton: FloatingActionButton(
    backgroundColor: MyColors.accent,
    onPressed: () {
     Get.toNamed(RouteName.pushRideMap, arguments: TripFrom());
    },
    child: Icon(Icons.add ,color: MyColors.primary,),
  ),
        drawer: Drawer(child: HomeDrawer(scaffoldContext: context)),
        // No global AppBar: each tab provides its own header, which avoids
        // the stacked double app bars (e.g. TripSearch ships a branded
        // SafeArea header of its own).
        body: BlocListener<HomeNavCubit, int>(
          // Keeps the PageView in sync when a tab change comes from outside
          // the bottom nav bar (e.g. the chat icon in the app bar).
          listener: (context, index) {
            if (_pageController.hasClients &&
                _pageController.page?.round() != index) {
              _pageController.jumpToPage(index);
            }
            _fade.forward(from: 0);
          },
          // تلاشٍ قصير عند تبديل التبويب: jumpToPage تنتقل فوراً بلا حركة
          // بينما شريط التنقّل نفسه متحرّك، فيبدو المحتوى وكأنه يقفز.
          //
          // التلاشي بمتحكّم يُعاد تشغيله لا بـ AnimatedSwitcher: الأخير
          // يبني شجرة جديدة عند كل تبديل فتُفقد حالة التبويبات (نتائج
          // البحث، موضع التمرير). هنا يبقى PageView نفسه ويتغيّر شفافيته.
          child: FadeTransition(
            opacity: _fade,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                BookingUserINTrip(),
                TripMeList(),
                TripSearch(),
                ChatListScreen(),
                Profile(),
              ],
            ),
          ),
        ),
        bottomNavigationBar:
            ModernBottomNavBar(pageController: _pageController),
      ),
    );
  }

  @override
  void dispose() {
    _fade.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد"),
        content: const Text("هل تريد الخروج من التطبيق؟"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              foregroundColor: MyColors.accent,
              backgroundColor: MyColors.surfaceAlt,
            ),
            child: const Text("لا"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: MyColors.primary,
              backgroundColor: MyColors.surfaceAlt,
            ),
            child: const Text("نعم"),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }
}

