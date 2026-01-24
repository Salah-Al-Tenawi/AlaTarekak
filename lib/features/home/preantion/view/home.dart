import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/e_pay/data/data_source/e_pay_remote_data_source.dart';
import 'package:alatarekak/features/e_pay/data/repo/e_pay_repo_im.dart';
import 'package:alatarekak/features/home/preantion/manger/cubit/home_nav_cubit_cubit.dart';
import 'package:alatarekak/features/home/preantion/view/widget/home_appbar.dart';
import 'package:alatarekak/features/home/preantion/view/widget/home_botom_nav_bar.dart';
import 'package:alatarekak/features/home/preantion/view/widget/home_drawer.dart';
import 'package:alatarekak/features/policy/policy_dilaog.dart';
import 'package:alatarekak/features/policy/text/pollicy_text.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/booking_me_list.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_select_source_and_dist_on_map.dart';
import 'package:alatarekak/features/trip_me/presantion/view/trip_me_list.dart';
import 'package:alatarekak/features/trip_search/presantion/view/trip_search.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isNew = false;
  final _pageController = PageController(initialPage: 1);
  final EPayRepoIm _epy =
      EPayRepoIm(remoteDataSource: EPayRemoteDataSource(api: DioConSumer()));
  String balance = "";

  final GlobalKey _refreshKey = GlobalKey();

  Future<void> _refreshBalance() async {
    setState(() {
      _refreshKey.currentState?.setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    try {
      isNew = Get.arguments as bool;
    } catch (e) {}
    super.initState();
    try {
      if (isNew) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(seconds: 3), () {
            _showPrivacy();
          });
        });
      }
    } catch (e) {}
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
        drawer: Drawer(child: HomeDrawer(scaffoldContext: context)),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: FutureBuilder(
            key: _refreshKey, // إضافة المفتاح للتحديث
            future: _epy.getBalance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return HomeAppBar(
                  balance: "Loading...",
                  onRefresh: _refreshBalance, // تمرير دالة التحديث
                );
              } else if (snapshot.hasData) {
                return snapshot.data!.fold(
                  (error) {
                    return HomeAppBar(
                      balance: error.message,
                      onRefresh: _refreshBalance, // تمرير دالة التحديث
                    );
                  },
                  (balanceModel) {
                    return HomeAppBar(
                      balance: balanceModel.balance,
                      onRefresh: _refreshBalance, // تمرير دالة التحديث
                    );
                  },
                );
              } else {
                return HomeAppBar(
                  balance: "خطأ",
                  onRefresh: _refreshBalance, // تمرير دالة التحديث
                );
              }
            },
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            TripSelectSourceAndDistOnMap(),
            TripSearch(),
            TripMeList(),
            BookingMeList()
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
