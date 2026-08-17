import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:alatarekak/features/trip_create/domain/create_ride_gate.dart';

/// يفحص شرط إنشاء الرحلة **قبل** فتح المعالج، ويوجّه المستخدم إلى ما ينقصه.
///
/// كان المستخدم يُدخل الرحلة كاملة — المسار والموعد والمقاعد والسعر ورقم
/// التواصل — ثم يرفضها الخادم لأنه غير موثّق أو بلا مركبة، فيُهدر عمله كلّه
/// لأجل شرط كان معلوماً قبل أن يبدأ.
///
/// مستقلّ عن شاشة الرئيسية ليُختبَر بلا بناء تبويباتها وخرائطها.
class CreateRideGuard {
  CreateRideGuard._();

  /// [onAllowed] يُنفَّذ فقط عند استيفاء الشرط — أو عند تعذّر قراءة الملف،
  /// فمنع مستخدم مستوفٍ للشرط أسوأ من تركه يصل إلى الخادم فيحسم هو.
  static Future<void> run(
    BuildContext context, {
    required VoidCallback onAllowed,
  }) async {
    final cubit = context.read<ProfileCubit>();
    var profile = cubit.state.profileEntity;

    // الملف لم يُحمَّل بعد (المستخدم لم يزر تبويب «حسابي») — نجلبه
    if (profile == null) {
      _showProgress(context);
      try {
        profile = await cubit.showMyProfile();
      } catch (_) {
        profile = null;
      }
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }

    final block = CreateRideGate.check(profile);
    if (block == CreateRideBlock.none) {
      onAllowed();
      return;
    }

    if (!context.mounted) return;
    await _showBlockDialog(context, block);
  }

  static void _showProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: MyColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  static Future<void> _showBlockDialog(
      BuildContext context, CreateRideBlock block) async {
    final action = CreateRideGate.actionLabel(block);

    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(
              block == CreateRideBlock.noCar
                  ? Icons.directions_car_outlined
                  : Icons.verified_outlined,
              color: MyColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(CreateRideGate.title(block),
                  style: AppTextStyles.titleMedium),
            ),
          ],
        ),
        content: Text(
          CreateRideGate.message(block),
          style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              // لا زرّ إجراء أثناء المراجعة، فلا معنى لـ «لاحقاً»
              action == null ? 'حسناً' : 'لاحقاً',
              style: AppTextStyles.labelLarge
                  .copyWith(color: MyColors.textSecondary),
            ),
          ),
          if (action != null)
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(action),
            ),
        ],
      ),
    );

    if (proceed != true || !context.mounted) return;
    final profile = context.read<ProfileCubit>().state.profileEntity;

    // نوجّهه إلى ما ينقصه بالضبط بدل تركه يبحث عنه بين الإعدادات
    switch (block) {
      case CreateRideBlock.noCar:
        Get.toNamed(RouteName.profileMyCars, arguments: profile);
      case CreateRideBlock.notVerified:
      case CreateRideBlock.verificationRejected:
        Get.toNamed(RouteName.verfiyUser, arguments: 'driver');
      case CreateRideBlock.verificationPending:
      case CreateRideBlock.none:
        break;
    }
  }
}
