import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';
import 'package:alatarekak/features/score/presantion/manger/cubit/score_cubit.dart';


class ProfileScoreScreen extends StatefulWidget {
  const ProfileScoreScreen({super.key});

  @override
  State<ProfileScoreScreen> createState() => _ProfileScoreScreenState();
}

class _ProfileScoreScreenState extends State<ProfileScoreScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // السجلّ مُرقَّم (20 حركة في الصفحة) — الصفحة التالية تُطلب قبل بلوغ
    // القاع بمسافة فلا يرى المستخدم توقفاً.
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
        context.read<ScoreCubit>().loadMoreHistory();
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
    return Scaffold(
      backgroundColor: MyColors.background,
      body: BlocBuilder<ScoreCubit, ScoreState>(
        builder: (context, state) {
          if (state is ScoreLoading || state is ScoreInitial) {
            return const Center(child: AppLoader());
          }

          final score = switch (state) {
            ScoreLoaded s => s.score,
            ScoreHistoryLoaded s => s.score,
            _ => null,
          };

          // خطأ قبل وصول أي بيانات — لا رأس نرسمه
          if (score == null) {
            return _ErrorView(
              message: state is ScoreError
                  ? state.message
                  : 'تعذّر جلب نقاط الثقة',
              onRetry: () => context.read<ScoreCubit>().loadHistory(),
            );
          }

          final history = state is ScoreHistoryLoaded
              ? state.history
              : const <ScoreHistoryEntity>[];
          final loadingMore =
              state is ScoreHistoryLoaded && state.loadingMore;
          final hasMore = state is ScoreHistoryLoaded && state.hasMore;
          // `meta.total` يشمل ما لم يُحمَّل بعد — نعرضه فيعرف المستخدم
          // أن ما أمامه جزء من سجلّ أطول.
          final total = state is ScoreHistoryLoaded ? state.total : 0;

          return RefreshIndicator(
            color: MyColors.accent,
            onRefresh: () => context.read<ScoreCubit>().loadHistory(),
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _ScoreHeader(score: score),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PermissionsCard(score: score),
                      SizedBox(height: 24.h),
                      _SectionTitle(
                        title: 'سجلّ النقاط',
                        count: total > history.length ? total : null,
                      ),
                      SizedBox(height: 12.h),
                      if (history.isEmpty)
                        const _EmptyHistory()
                      else
                        for (int i = 0; i < history.length; i++)
                          StaggeredItem(
                            // التدرّج للصفحة الأولى وحدها: إعادة تشغيله
                            // على الصفحات التالية تُظهر الجديد متأخراً
                            // ثانيةً كاملة بعد أن وصل فعلاً.
                            index: i < _perPage ? i : 0,
                            child: _HistoryTile(entry: history[i]),
                          ),
                      if (loadingMore || hasMore) ...[
                        SizedBox(height: 8.h),
                        _HistoryFooter(loading: loadingMore),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// حجم الصفحة كما في الكيوبت — للتدرّج وحده.
  static const int _perPage = 20;
}

// ─── رأس النقاط ───────────────────────────────────────────────────────────────

class _ScoreHeader extends StatelessWidget {
  final ScoreEntity score;
  const _ScoreHeader({required this.score});

  @override
  Widget build(BuildContext context) {
    final tint = _tierColor(score.tier);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MyColors.navy, MyColors.primary, tint],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 20.sp),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Text(
                'نقاط الثقة',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              // الرقم هو بطل الشاشة — يُقرأ من مسافة
              Text(
                '${score.score}',
                style: TextStyle(
                  fontSize: 52.sp,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20.r),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        size: 14.sp, color: Colors.white),
                    SizedBox(width: 5.w),
                    Text(
                      'المستوى: ${score.tierLabel}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              _HeaderStats(score: score),
            ],
          ),
        ),
      ),
    );
  }

  Color _tierColor(String tier) => switch (tier.trim().toLowerCase()) {
        'gold' => MyColors.warning,
        'silver' => MyColors.blue,
        'bronze' => MyColors.accent,
        _ => MyColors.error,
      };
}

/// الرحلات والإلغاءات ونسبته — أرقام تشرح من أين جاءت النقاط.
class _HeaderStats extends StatelessWidget {
  final ScoreEntity score;
  const _HeaderStats({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _stat('${score.totalRides}', 'رحلة'),
          _divider(),
          _stat('${score.totalCancellations}', 'إلغاء'),
          _divider(),
          _stat('${score.cancelRate.toStringAsFixed(1)}%', 'نسبة الإلغاء'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(height: 2.h),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white.withValues(alpha: 0.8))),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 1,
        height: 28.h,
        color: Colors.white.withValues(alpha: 0.22),
      );
}

// ─── ما تسمح به النقاط ────────────────────────────────────────────────────────

/// الحارس الذي كان جاهزاً في الكيوبت ولا يستخدمه أي زرّ — يُشرح للمستخدم
/// هنا صراحةً: ما يستطيعه اليوم وما ينقصه.
class _PermissionsCard extends StatelessWidget {
  final ScoreEntity score;
  const _PermissionsCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MyColors.border, width: 1),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          _row(
            allowed: score.canCreateRides,
            label: 'إنشاء الرحلات',
            need: ScoreEntity.minScoreToCreate,
            current: score.score,
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, thickness: 1, color: MyColors.divider),
          SizedBox(height: 12.h),
          _row(
            allowed: score.canBookRides,
            label: 'حجز الرحلات',
            need: ScoreEntity.minScoreToBook,
            current: score.score,
          ),
        ],
      ),
    );
  }

  Widget _row({
    required bool allowed,
    required String label,
    required int need,
    required int current,
  }) {
    final missing = need - current;

    return Row(
      children: [
        Icon(
          allowed ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
          size: 20.sp,
          color: allowed ? MyColors.success : MyColors.textHint,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.labelLarge.copyWith(
                      fontSize: 14.sp, color: MyColors.textPrimary)),
              SizedBox(height: 2.h),
              Text(
                allowed
                    ? 'متاح لك'
                    : 'يحتاج $need نقطة — '
                        'ينقصك ${ScoreHistoryEntity.pointsPhrase(missing)}',
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 11.sp,
                  color: allowed ? MyColors.success : MyColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── سطر السجل ────────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final ScoreHistoryEntity entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.isPositive
        ? MyColors.success
        : entry.isNegative
            ? MyColors.error
            : MyColors.textSecondary;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: MyColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Icon(
              entry.isPositive
                  ? Icons.trending_up_rounded
                  : entry.isNegative
                      ? Icons.trending_down_rounded
                      : Icons.remove_rounded,
              size: 20.sp,
              color: color,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // مشتقّ من points لا من reason الإنجليزي الذي يرسله الخادم
                Text(
                  entry.deltaLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (entry.actionLabel != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    entry.actionLabel!,
                    style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 11.sp, color: MyColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (entry.highCancelRateApplied) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 12.sp, color: MyColors.warning),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          'طُبِّق جزاء معدّل الإلغاء المرتفع',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10.sp, color: MyColors.warning),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // الرصيد بعد الحركة — يجعل السجل قابلاً للتتبّع
              Text('${entry.newScore}',
                  style: AppTextStyles.labelLarge.copyWith(
                      fontSize: 14.sp, color: MyColors.textPrimary)),
              if (entry.createdAt != null) ...[
                SizedBox(height: 3.h),
                Text(
                  DateTimeUtils.arabicDate(entry.createdAt!),
                  style: AppTextStyles.labelSmall
                      .copyWith(fontSize: 10.sp, color: MyColors.textHint),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── حالات فرعية ──────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MyColors.border, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 44.sp, color: MyColors.textHint),
          SizedBox(height: 12.h),
          Text('لا حركات على نقاطك بعد',
              style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14.sp, color: MyColors.textSecondary)),
          SizedBox(height: 6.h),
          Text(
            'كل رحلة تُكملها أو تُلغيها ستظهر هنا.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall
                .copyWith(fontSize: 12.sp, color: MyColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  /// إجمالي الحركات عند الخادم — يُخفى حين لا يزيد عمّا هو معروض.
  final int? count;

  const _SectionTitle({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 18.h,
          decoration: BoxDecoration(
              color: MyColors.accent,
              borderRadius: BorderRadius.circular(2.r)),
        ),
        SizedBox(width: 8.w),
        Text(title,
            style: AppTextStyles.titleMedium.copyWith(fontSize: 16.sp)),
        if (count != null) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: MyColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.labelSmall
                  .copyWith(fontSize: 11.sp, color: MyColors.accent),
            ),
          ),
        ],
      ],
    );
  }
}

/// ذيل القائمة: مؤشّر أثناء جلب الصفحة التالية، ودعوة للمتابعة قبلها.
class _HistoryFooter extends StatelessWidget {
  final bool loading;
  const _HistoryFooter({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Center(
        child: loading
            ? AppLoader(size: 26, color: MyColors.accent)
            : Text(
                'اسحب للأسفل لعرض المزيد',
                style: AppTextStyles.labelSmall
                    .copyWith(fontSize: 11.sp, color: MyColors.textHint),
              ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 46.sp, color: MyColors.error),
            SizedBox(height: 12.h),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13.sp,
                    color: MyColors.textSecondary,
                    height: 1.6)),
            SizedBox(height: 16.h),
            SizedBox(
              height: 46.h,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('إعادة المحاولة',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
