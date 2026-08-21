// lib/features/trip_me/presentation/view/trip_me_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_navigation/get_navigation.dart';

import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/class/cancel_policy.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';
import 'package:alatarekak/core/utils/widgets/consequence_card.dart';
import 'package:alatarekak/core/utils/widgets/app_error_view.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:alatarekak/core/utils/widgets/status_filter_bar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_me/presantion/manger/cubit/trip_me_cubit.dart';
import 'package:alatarekak/features/trip_me/presantion/view/widget/trip_item.dart';
import 'package:alatarekak/features/trip_me/presantion/view/widget/trip_status_filter.dart';

class TripMeList extends StatefulWidget {
  const TripMeList({super.key});

  @override
  State<TripMeList> createState() => _TripMeListState();
}

class _TripMeListState extends State<TripMeList> {
  TripStatusFilter _filter = TripStatusFilter.all;

  /// آخر قائمة وصلت من الخادم.
  ///
  /// الكيوبت واحد لكل عمليات الشاشة، فالإلغاء يُخرجه من
  /// `TripMeListLoaded` إلى `TripMeLoading` — وكانت الشاشة تستبدل
  /// الرحلات كلها بمؤشّر دوّار حتى يعود الجلب. الاحتفاظ بالقائمة هنا
  /// يُبقيها معروضة، ويكفي شريط تقدّم رفيع ليُعلم أن شيئاً يجري.
  List<TripModel>? _trips;

  @override
  void initState() {
    super.initState();
    // الجلب من `initState` لا من داخل `builder`.
    //
    // كان الفرع الأخير في البناء يجدول `getMeTrips()` ويعيد `SizedBox`،
    // وهو فرع يلتقط **كل** حالة لا فرع لها — `TripMeCancel` و
    // `TripMeOneLoaded` و`TripMeFinishTrip` — فأي حالة جديدة تُضاف
    // للكيوبت تُطلق طلب شبكة صامتاً لا يقصده أحد. والطلب من داخل البناء
    // يخلط الرسم بالأثر الجانبي، وهو ما لا يصحّ أياً كان.
    final cubit = context.read<TripMeCubit>();

    // الكيوبت يعيش **فوق** الـ PageView في الرئيسية فينجو من تبديل
    // التبويبات، بينما الشاشة نفسها تُبنى من جديد في كل عودة إليها
    // (PageView يتخلّص من الصفحات غير المعروضة). فلو جلبنا بلا شرط
    // لوقع طلب شبكة عند كل ضغطة على «رحلاتي» — وثمانُ رحلات في كل مرة.
    //
    // القائمة المحمّلة تُعرض فوراً، ومن أراد أحدث منها يسحب للتحديث.
    if (cubit.state is! TripMeListLoaded) cubit.getMeTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('رحلاتي',
            style:
                AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
        centerTitle: true,
      ),
      body: BlocConsumer<TripMeCubit, TripMeState>(
        listener: (context, state) {
          if (state is TripMeErorr) {
            showMySnackBar(context, state.message, type: SnackType.error);
          } else if (state is TripMeCancel) {
            showMySnackBar(context, state.message, type: SnackType.success);
          }
        },
        builder: (context, state) {
          if (state is TripMeListLoaded) _trips = state.trips;
          final trips = _trips;

          if (trips == null) {
            if (state is TripMeErorr) return _errorView(state.message);
            return const Center(child: AppLoader());
          }

          // إلغاء قيد التنفيذ: الكيوبت يمرّ بـ`TripMeLoading` ثم يعيد
          // الجلب بنفسه. القائمة تبقى، والشريط الرفيع وحده يشي بالعمل.
          return _loadedBody(trips, busy: state is TripMeLoading);
        },
      ),
    );
  }

  Future<void> _refreshData() async {
    await context.read<TripMeCubit>().getMeTrips();
  }

  // ━━━━━━━━━━━━━━━━ الجسم ━━━━━━━━━━━━━━━━

  Widget _loadedBody(List<TripModel> trips, {required bool busy}) {
    final visible = _filter.apply(trips);

    return Column(
      children: [
        SizedBox(
          height: 2.h,
          child: busy
              ? LinearProgressIndicator(
                  minHeight: 2.h,
                  backgroundColor: Colors.transparent,
                  color: MyColors.accent,
                )
              : null,
        ),
        _filterBar(trips),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: MyColors.accent,
            child: visible.isEmpty
                ? _emptyView()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final trip = visible[index];

                      return StaggeredItem(
                        index: index,
                        child: ItemTrip(
                          // المفتاح يمنع إعادة استعمال حالة بطاقة لرحلة
                          // أخرى حين يتغيّر التصنيف وتُعاد ترتيب القائمة.
                          key: ValueKey(trip.id),
                          trip: trip,
                          onTap: () {
                            // كل رحلة هنا للمستخدم بالتعريف، فتُجلب
                            // بحجوزاتها من مسار السائق
                            Get.toNamed(
                              RouteName.tripDetails,
                              arguments: {'tripId': trip.id, 'asDriver': true},
                            );
                          },
                          onCancel: () => _askCancel(trip),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filterBar(List<TripModel> trips) {
    final counts = countTripsByFilter(trips);

    return StatusFilterBar(
      options: [
        for (final filter in TripStatusFilter.values)
          StatusFilterOption(
            label: filter.label,
            color: filter.color,
            icon: filter.icon,
            count: counts[filter] ?? 0,
            isSelected: filter == _filter,
            onTap: () => setState(() => _filter = filter),
          ),
      ],
    );
  }

  Future<void> _askCancel(TripModel trip) async {
    final cubit = context.read<TripMeCubit>();
    final confirm = await showAppDialog(
      context,
      icon: Icons.cancel_schedule_send_rounded,
      title: 'إلغاء الرحلة',
      message: 'لا يمكن التراجع بعده.',
      // الكلفة تُحسب من عمر الرحلة لا من قربها للانطلاق، وتختلف اختلافاً
      // بيّناً بين إلغاءٍ مبكّر لا يكلّف شيئاً وآخر يخصم اثنتي عشرة نقطة
      // ويحتجز رسوم الإنشاء — انظر [CancelPolicy].
      content: ConsequenceCard(
        title: 'ماذا يقع إن ألغيتَ الآن',
        lines: CancelPolicy.driverCancelRide(
          elapsed: CancelPolicy.elapsedPercent(
            createdAt: trip.createdAt,
            departure: trip.departure,
          ),
          passengers: trip.seatsBooked,
        ),
      ),
      confirmLabel: 'إلغاء الرحلة',
      cancelLabel: 'تراجع',
      destructive: true,
    );

    if (confirm == true) cubit.cancelTrip(trip.id);
  }

  /// الشاشة الفارغة برسالة التصنيف المختار — «لا توجد رحلات» العامّة
  /// تُوهم من فلتر على «ملغاة» أن رحلاته كلها اختفت.
  Widget _emptyView() {
    final isFiltered = _filter != TripStatusFilter.all;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 24.h),
              Image.asset(
                'assets/images/Empty.png',
                width: 240.w,
                height: 240.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 12.h),
              Text(
                _filter.emptyMessage,
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16.sp),
              ),
              if (isFiltered) ...[
                SizedBox(height: 12.h),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _filter = TripStatusFilter.all),
                  icon: Icon(Icons.list_rounded, size: 18.sp),
                  label: const Text('عرض كل الرحلات'),
                  style: TextButton.styleFrom(foregroundColor: MyColors.accent),
                ),
              ],
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorView(String message) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: MyColors.accent,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: AppErrorView(
                title: 'تعذّر جلب رحلاتك',
                message: message,
                actionLabel: 'إعادة المحاولة',
                onAction: _refreshData,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
