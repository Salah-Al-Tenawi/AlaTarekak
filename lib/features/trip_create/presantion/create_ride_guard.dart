import 'package:flutter/material.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
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
  ///
  /// **الملف يُجلب في كل مرة، ولا يُكتفى بما في اليد.**
  ///
  /// كان يُجلب حين يكون `null` وحده. ولكلّ شاشة في التطبيق نسخةٌ خاصّة من
  /// [ProfileCubit]، فمن أضاف مركبته من «مركباتي» حدّث نسخةَ تلك الشاشة
  /// وحدها — ثم أُتلفت بخروجه منها. أما نسخة الرئيسية فبقيت تحمل ملفاً
  /// بلا مركبة، وما دام غير `null` لم يُسأل الخادم أبداً: فيُقال لمن
  /// أضاف سيارته للتوّ «لا توجد مركبة»، ولا ينفعه تحديث ولا خروج من
  /// الشاشة — حتى يُغلق التطبيق ويُفتح فتُولد النسخة فارغة.
  ///
  /// نداءٌ واحد قبل فتح المعالج أرخص من رحلةٍ يُدخلها المستخدم كاملةً ثم
  /// تُرفض، وأرخص من بابٍ مقفل في وجه من استوفى شرطه.
  static Future<void> run(
    BuildContext context, {
    required VoidCallback onAllowed,
  }) async {
    final cubit = context.read<ProfileCubit>();
    final navigator = Navigator.of(context);

    _showProgress(context);

    ProfileEntity? profile;
    try {
      profile = await cubit.showMyProfile();
    } catch (_) {
      // تعذّر الجلب — **ولا نمنع بناءً على نسخةٍ قديمة**: المنع بمعلومةٍ
      // لم نتحقّق منها يحبس مستخدماً مستوفياً لشرطه، والخادم يردّ
      // برسالةٍ مفهومة إن لم يكن مستوفياً.
      profile = null;
    }

    if (navigator.mounted) navigator.pop();
    if (!context.mounted) return;

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
          child: const AppLoader(size: 72),
        ),
      ),
    );
  }

  static Future<void> _showBlockDialog(
      BuildContext context, CreateRideBlock block) async {
    final action = CreateRideGate.actionLabel(block);

    final proceed = await showAppDialog(
      context,
      icon: _iconFor(block),
      // المراجعة انتظار لا عطل، والرفض حالة تستدعي انتباهاً
      accentColor: _colorFor(block),
      title: CreateRideGate.title(block),
      message: CreateRideGate.message(block),
      confirmLabel: action,
      // لا زرّ إجراء أثناء المراجعة، فلا معنى لـ «لاحقاً»
      cancelLabel: 'لاحقاً',
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

  /// أيقونة تصف الحالة لا أيقونة واحدة للجميع.
  static IconData _iconFor(CreateRideBlock block) => switch (block) {
        CreateRideBlock.noCar => Icons.directions_car_outlined,
        CreateRideBlock.verificationPending => Icons.hourglass_top_rounded,
        CreateRideBlock.verificationRejected => Icons.gpp_bad_outlined,
        CreateRideBlock.notVerified => Icons.verified_user_outlined,
        CreateRideBlock.none => Icons.check_circle_outline_rounded,
      };

  /// المراجعة انتظارٌ لا خطأ، والرفض وحده يستحقّ الأحمر.
  static Color _colorFor(CreateRideBlock block) => switch (block) {
        CreateRideBlock.verificationPending => MyColors.warning,
        CreateRideBlock.verificationRejected => MyColors.error,
        _ => MyColors.primary,
      };
}
