import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/utils/functions/input_valid.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/e_pay/data/model/balance_model.dart';
import 'package:alatarekak/features/e_pay/domain/entity/wallet_transaction.dart';
import 'package:alatarekak/features/e_pay/presantion/manger/cubit/wallet_cubit.dart';

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text("محفظتي", style: AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.read<WalletCubit>().getBalance(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث الرصيد',
          ),
        ],
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          if (state is WalletInitial || state is WalletLoading) {
            return const Center(child: LoadingWidgetSize150());
          }
          if (state is WalletNotActivated ||
              state is WalletActivating ||
              state is WalletActivationFailed) {
            return FadeSlideIn(
              child: _ActivateWalletView(
                isSubmitting: state is WalletActivating,
                error: state is WalletActivationFailed ? state.message : null,
              ),
            );
          }
          if (state is WalletErorr) {
            return _WalletErrorView(message: state.message);
          }
          return FadeSlideIn(
              child: _WalletLoadedView(state: state as WalletLoaded));
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LOADED VIEW  (balance card + recharge)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _WalletLoadedView extends StatefulWidget {
  final WalletLoaded state;
  const _WalletLoadedView({required this.state});

  @override
  State<_WalletLoadedView> createState() => _WalletLoadedViewState();
}

class _WalletLoadedViewState extends State<_WalletLoadedView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 200) {
        context.read<WalletCubit>().loadMoreTransactions();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.state.statement;
    return RefreshIndicator(
      onRefresh: () async => context.read<WalletCubit>().getBalance(),
      child: SingleChildScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          children: [
            _BalanceCard(balance: widget.state.balance),
            if (widget.state.hasDebt) ...[
              SizedBox(height: 12.h),
              _DebtCard(debt: widget.state.debt),
            ],
            SizedBox(height: 16.h),
            const _RechargeCard(),
            if (st != null && st.items.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _StatementCard(
                statement: st,
                loadingMore: widget.state.loadingMore,
              ),
            ],
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Balance Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _BalanceCard extends StatelessWidget {
  final BalanceModel balance;
  const _BalanceCard({required this.balance});

  void _copyWalletNumber() {
    Clipboard.setData(ClipboardData(text: balance.walletNumber));
    AppSnackBar.success('تم نسخ رقم المحفظة');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [MyColors.primary, MyColors.navy],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MyColors.shadowMedium,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: MyColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: MyColors.accent,
                  size: 20,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'المحفظة الإلكترونية',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            'الرصيد الحالي',
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white60),
          ),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  balance.balance,
                  style: AppTextStyles.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 34.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  'ل.س',
                  style: AppTextStyles.accent.copyWith(fontSize: 16.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 0),
          SizedBox(height: 12.h),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رقم المحفظة',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    balance.walletNumber,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: _copyWalletNumber,
                icon: Icon(
                  Icons.copy_rounded,
                  color: MyColors.accent,
                  size: 20,
                ),
                tooltip: 'نسخ رقم المحفظة',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Recharge Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _RechargeCard extends StatelessWidget {
  const _RechargeCard();

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppSnackBar.error('تعذر فتح التطبيق، حاول مجدداً');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MyColors.accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_card_rounded,
                    color: MyColors.accent,
                    size: 17,
                  ),
                ),
                SizedBox(width: 8.w),
                Text('شحن الرصيد', style: AppTextStyles.labelLarge),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 0.5),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لشحن محفظتك تواصل معنا عبر إحدى القنوات التالية:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: MyColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12.h),
                // القناة الداخلية أولاً: لا تُخرج المستخدم من التطبيق،
                // ومحادثتها محفوظة يمكنه الرجوع إليها لمتابعة طلبه
                _ContactTile(
                  icon: Icon(Icons.headset_mic_outlined),
                  iconColor: MyColors.primary,
                  title: 'الدعم الفني',
                  subtitle: 'محادثة مباشرة داخل التطبيق',
                  onTap: () => Get.toNamed(RouteName.profileContactUs),
                ),
                SizedBox(height: 10.h),
                _ContactTile(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 22),
                  iconColor: const Color(0xFF25D366),
                  title: 'واتساب',
                  subtitle: '+963 988 626 577',
                  onTap: () => _openUrl('https://wa.me/+963988626577'),
                ),
                SizedBox(height: 10.h),
                _ContactTile(
                  icon: const FaIcon(FontAwesomeIcons.telegram, size: 22),
                  iconColor: const Color(0xFF229ED9),
                  title: 'تلغرام',
                  subtitle: '@salah577',
                  onTap: () => _openUrl('https://t.me/salah577'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  /// ويدجت لا `IconData`: أيقونات العلامات التجارية في font_awesome 11
  /// نوع مستقلّ (`FaIconData`) لا يرث `IconData` — صار الأخير
  /// `final class` في Flutter 3.47. فيمرّر المستدعي `Icon` أو `FaIcon`.
  final Widget icon;

  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: MyColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MyColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              // الأيقونة ويدجت لا IconData: أيقونات العلامات التجارية في
              // font_awesome 11 نوع مستقلّ (FaIconData) لا يرث IconData —
              // صار الأخير final class في Flutter 3.47.
              child: Center(
                child: IconTheme(
                  data: IconThemeData(color: iconColor, size: 22),
                  child: icon,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: MyColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_back_ios_rounded,
              size: 14,
              color: MyColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NOT ACTIVATED VIEW
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// تفعيل بخطوة واحدة: رقم الهاتف فقط بلا رمز تحقق. يصلها المستخدم حين
/// لا تكون محفظته أُنشئت تلقائياً عند التسجيل — فشل عابر وقتها، أو حساب
/// أُنشئ قبل هذه الميزة.
class _ActivateWalletView extends StatefulWidget {
  final bool isSubmitting;
  final String? error;

  const _ActivateWalletView({required this.isSubmitting, this.error});

  @override
  State<_ActivateWalletView> createState() => _ActivateWalletViewState();
}

class _ActivateWalletViewState extends State<_ActivateWalletView> {
  late final TextEditingController _phone;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // نُرشّح الحقل بالرقم الذي أدخله عند التسجيل إن وُجد
    _phone = TextEditingController(
        text: context.read<WalletCubit>().suggestedPhone ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _activate() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<WalletCubit>().activateWallet(_phone.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: MyColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: MyColors.accent,
                size: 44,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'فعّل محفظتك الإلكترونية',
              style: AppTextStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'أدخل رقم هاتفك لتفعيل محفظتك، فتدفع تكاليف الرحلات وتستلم أرباحك من داخل التطبيق',
              style: AppTextStyles.bodyMedium.copyWith(
                color: MyColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              enabled: !widget.isSubmitting,
              textAlign: TextAlign.center,
              validator: (val) => inputvaild(val ?? '', "nubmerphone", 10, 10),
              decoration: const InputDecoration(
                hintText: "رقم الهاتف",
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              onFieldSubmitted: (_) => widget.isSubmitting ? null : _activate(),
            ),
            if (widget.error != null) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: MyColors.error, size: 18),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      widget.error!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: MyColors.error),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: widget.isSubmitting ? null : _activate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.primary,
                  disabledBackgroundColor: MyColors.textHint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: widget.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                label: Text(
                  widget.isSubmitting ? 'جارٍ التفعيل...' : 'تفعيل المحفظة الآن',
                  style: AppTextStyles.buttonLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ERROR VIEW
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _WalletErrorView extends StatelessWidget {
  final String message;
  const _WalletErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: MyColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: MyColors.error,
                size: 40,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'تعذر تحميل المحفظة',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: MyColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: () => context.read<WalletCubit>().getBalance(),
              style: OutlinedButton.styleFrom(
                foregroundColor: MyColors.primary,
                side: BorderSide(color: MyColors.primary),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Debt Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
/// رسوم إنشاء رحلات نقدية مؤجَّلة. تمنع السائق من إنشاء رحلة نقدية
/// جديدة حتى تُسدَّد، وتُسدَّد تلقائياً عند أول شحن يكفي لتغطيتها.
class _DebtCard extends StatelessWidget {
  final double debt;
  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyColors.warningLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MyColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_balance_outlined,
              color: MyColors.warning, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('عليك رسوم مستحقّة',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: MyColors.warning)),
                SizedBox(height: 4.h),
                Text(
                  '${_money(debt)} ل.س من رحلات نقدية سابقة. اشحن محفظتك بما '
                  'يغطّيها لتتمكّن من إنشاء رحلات نقدية جديدة — تُسدَّد '
                  'تلقائياً عند الشحن.',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: MyColors.textSecondary, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// صيغة المبالغ صارت مشتركة بين كل شاشات المال — انظر [Money].
String _money(double v) => Money.format(v);

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Statement
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _StatementCard extends StatelessWidget {
  final WalletStatement statement;
  final bool loadingMore;
  const _StatementCard({required this.statement, required this.loadingMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 8.h),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 18.sp, color: MyColors.primary),
                SizedBox(width: 8.w),
                Text('كشف الحساب', style: AppTextStyles.labelLarge),
                const Spacer(),
                Text('${statement.total} حركة',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: MyColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 0.5),
          ...statement.items.map((t) => _TransactionTile(tx: t)),
          if (loadingMore)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: MyColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    // حركات الصفر سجلّات تدقيق لا حركات مالية: بلا مبلغ وبلون خافت،
    // حتى لا يقرأ المستخدم «تأجيل الرسم» على أنه خصم من رصيده.
    final audit = tx.isAuditOnly;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: tx.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(tx.icon, size: 17.sp, color: tx.color),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.label,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: MyColors.textPrimary,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (tx.createdAt != null) ...[
                  SizedBox(height: 2.h),
                  Text(_when(tx.createdAt!),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: MyColors.textHint)),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (audit)
            Text('سجلّ',
                style: AppTextStyles.labelSmall
                    .copyWith(color: MyColors.textHint))
          else
            Text(
              '${tx.isCredit ? '+' : '−'}${_money(tx.amount)}',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: tx.color, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  String _when(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')} · '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
