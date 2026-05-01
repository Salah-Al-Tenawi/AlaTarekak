import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/custom_badge.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String balance;
  final VoidCallback onRefresh;

  const HomeAppBar({
    super.key,
    required this.balance,
    required this.onRefresh,
  });

  Widget buildBalanceBadge(String balance) {
    if (balance == "Wallet not found for this user") {
      return InkWell(
        onTap: () {
          Get.toNamed(RouteName.verfiyOtpEpy);
        },
        child: Container(
          margin: EdgeInsets.only(right: 12.w, top: 8.h, bottom: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: MyColors.background,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(
                Icons.add,
                color: MyColors.accent,
              ),
              Text(
                "اضف محفظة",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: MyColors.accent,
                ),
              )
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(right: 12.w, top: 8.h, bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: MyColors.background,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: MyColors.accent,
            size: 20,
          ),
          SizedBox(width: 6.w),
          Text(
            "$balance ل.س",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: MyColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  void showBalanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(20),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet,
                  color: MyColors.primary, size: 28),
              SizedBox(width: 8),
              Text(
                "رصيدك الحالي",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$balance ل.س",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MyColors.accent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "لشحن حسابك يمكنك التواصل عبر:",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // زر واتساب
              InkWell(
                onTap: () async {
                  final Uri whatsappUrl =
                      Uri.parse("https://wa.me/+963988626577");
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(whatsappUrl,
                        mode: LaunchMode.externalApplication);
                  } else {
                    print("لا يمكن فتح الرابط");
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: MyColors.textHint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MyColors.textHint),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.whatsapp,
                          color: Colors.green, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "واتساب: +963988626577",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // زر تلغرام
              InkWell(
                onTap: () async {
                  final Uri telegramUrl = Uri.parse("https://t.me/salah577");
                  if (await canLaunchUrl(telegramUrl)) {
                    await launchUrl(telegramUrl,
                        mode: LaunchMode.externalApplication);
                  } else {
                    print("لا يمكن فتح تلغرام");
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: MyColors.textHint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MyColors.textHint),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.telegram,
                          color: MyColors.primary, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "تلغرام: @salah577",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("إغلاق", style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: MyColors.primary,
      actions: [
        InkWell(
          onTap: () => showBalanceDialog(context),
          child: buildBalanceBadge(balance),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(
            Icons.refresh,
            color: MyColors.accent,
          ),
          tooltip: 'تحديث الرصيد',
        ),
        CustomBadge(
          badgeColor: MyColors.accent,
          icon: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Text(
              "10",
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber),
            ),
          ),
          border: true,
          child: InkWell(
            onTap: () {
              Get.toNamed(RouteName.chatListScreen);
            },
            child: Container(
              margin: EdgeInsets.only(left: 8.w, bottom: 5.h, right: 8.w),
              width: 35.w,
              height: 45.h,
              decoration: const BoxDecoration(boxShadow: [
                BoxShadow(
                    blurRadius: 5,
                    offset: Offset(5, 5),
                    color: MyColors.navy)
              ], shape: BoxShape.circle, color: MyColors.background),
              child: const Icon(Icons.chat),
            ),
          ),
        ),
        CustomBadge(
          badgeColor: MyColors.accent,
          icon: Container(
            decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(50.sp)),
            child: Text(
              "10",
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber),
            ),
          ),
          border: true,
          child: InkWell(
            onTap: () {},
            child: Container(
              margin: EdgeInsets.only(left: 8.w, bottom: 5.h, right: 1.w),
              width: 35.w,
              height: 45.h,
              decoration: BoxDecoration(
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 5,
                      offset: Offset(5, 5),
                      color: MyColors.textPrimary)
                ],
                borderRadius: BorderRadius.circular(30.sp),
                color: MyColors.background,
              ),
              child: const Icon(Icons.notifications),
            ),
          ),
        ),
        SizedBox(width: 10.w),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
