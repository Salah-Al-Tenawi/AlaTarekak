import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

/// تُعرض عند وصول USER_BANNED (403) من أي طلب محمي.
/// المسموح للمحظور فقط: التواصل مع الدعم (مستند المواصفات §0.4).
class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BanInfo? ban = Get.arguments is BanInfo ? Get.arguments : null;

    return Scaffold(
      backgroundColor: MyColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 96.w,
                height: 96.w,
                decoration: BoxDecoration(
                  color: MyColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.block_rounded,
                    size: 52, color: MyColors.error),
              ),
              SizedBox(height: 24.h),
              Text(
                _title(ban),
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (ban != null && ban.reason.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: MyColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: MyColors.border),
                  ),
                  child: Text(
                    "السبب: ${ban.reason}",
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              SizedBox(height: 8.h),
              Text(
                "يمكنك فقط التواصل مع فريق الدعم",
                style: AppTextStyles.bodySmall
                    .copyWith(color: MyColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                height: 52.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Get.toNamed(RouteName.profileContactUs),
                  icon: const Icon(Icons.support_agent, color: Colors.white),
                  label: const Text(
                    "التواصل مع الدعم",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () async {
                  await HiveBoxes.authBox.clear();
                  Get.offAllNamed(RouteName.login);
                },
                child: Text(
                  "تسجيل الخروج",
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: MyColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(BanInfo? ban) {
    if (ban == null) return "تم حظر حسابك";
    if (ban.isPermanent) return "تم حظر حسابك بشكل دائم";
    final until = _formatDate(ban.expiresAt);
    return until == null
        ? "تم حظر حسابك مؤقتاً"
        : "تم حظر حسابك مؤقتاً حتى $until";
  }

  String? _formatDate(String? iso) {
    if (iso == null) return null;
    final date = DateTime.tryParse(iso);
    if (date == null) return null;
    return DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(date.toLocal());
  }
}
