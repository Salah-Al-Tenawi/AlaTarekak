import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/chat/presentation/view/chat_list_screen.dart';
import 'package:alatarekak/features/profiles/presantaion/view/profile.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/home/preantion/manger/cubit/home_nav_cubit_cubit.dart';
import 'package:alatarekak/features/home/preantion/view/widget/home_botom_nav_bar.dart';
import 'package:alatarekak/features/home/preantion/view/widget/home_drawer.dart';
import 'package:alatarekak/features/policy/policy_dilaog.dart';
import 'package:alatarekak/features/policy/text/pollicy_text.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/view/booking_user_in_trip.dart';
import 'package:alatarekak/features/trip_me/presantion/view/trip_me_list.dart';
import 'package:alatarekak/features/trip_search/presantion/view/trip_search.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isNew = false;
  final _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();

  isNew = Get.arguments as bool? ?? false;

  if (isNew) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        _showPrivacy();
      });
    });
  }
}
  Future<void> _showPrivacy() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrivacyPolicyDialog(
        policyText: PolicyText.text,
      ),
    );

    if (accepted != true) {
      await context.read<HomeNavCubit>().logout(context);
      // Get.offAllNamed(RouteName.singin);
    }
  }

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
        appBar: AppBar(
          backgroundColor: MyColors.primary,
  leading: IconButton(
    icon: Icon(Icons.settings,color:Colors.white),
    onPressed: () {
      // define action for settings
    },
  ),
  title: Center(child: Text('عطريقك',style: TextStyle(color:Colors.white),)),
  actions: [
    IconButton(
      icon: Icon(Icons.notifications,color: Colors.white,),
      onPressed: () {
        // define action for notifications
      },
    ),
  ],
),body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            TripSearch(),
            TripMeList(),
            BookingUserINTrip(),
            ChatListScreen(),
            Profile(),
          ],
        ),
        bottomNavigationBar:
            ModernBottomNavBar(pageController: _pageController),
      ),
    );
  }

  @override
  void dispose() {
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
              backgroundColor: Colors.grey[200],
            ),
            child: const Text("لا"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: MyColors.primary,
              backgroundColor: Colors.grey[200],
            ),
            child: const Text("نعم"),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }
}

