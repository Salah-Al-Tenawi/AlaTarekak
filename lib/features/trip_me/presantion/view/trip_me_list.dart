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
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_me/presantion/manger/cubit/trip_me_cubit.dart';
import 'package:alatarekak/features/trip_me/presantion/view/widget/trip_item.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';

class TripMeList extends StatefulWidget {
  const TripMeList({super.key});

  @override
  State<TripMeList> createState() => _TripMeListState();
}

class _TripMeListState extends State<TripMeList> {
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
        title: Text('رحلاتي', style: AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
        centerTitle: true,
      ),
      body: BlocConsumer<TripMeCubit, TripMeState>(
        listener: (context, state) {
          if (state is TripMeErorr) {
            showMySnackBar(context, state.message);
          } else if (state is TripMeCancel) {
            showMySnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is TripMeLoading) {
            return const Center(child: LoadingWidgetSize150());
          } else if (state is TripMeListLoaded) {
            final List<TripModel> trips = state.trips;

            Future<void> refreshData() async {
              await context.read<TripMeCubit>().getMeTrips();
            }

            return RefreshIndicator(
              onRefresh: refreshData,
              child: trips.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height,
                        child: Column(
                          children: [
                            SizedBox(height: 80.h),
                            Image.asset(
                              'assets/images/Empty.png',
                              width: 300.w,
                              height: 300.h,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: 16.h),
                            const Text(
                              'لا توجد رحلات',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final trip = trips[index];

                        return StaggeredItem(
                          index: index,
                          child: ItemTrip(
                            trip: trip,
                            onTap: () {
                              // كل رحلة هنا للمستخدم بالتعريف، فتُجلب
                              // بحجوزاتها من مسار السائق
                              Get.toNamed(
                                RouteName.tripDetails,
                                arguments: {
                                  'tripId': trip.id,
                                  'asDriver': true,
                                },
                              );
                            },
                            onCancel: () async {
                              final cubit = context.read<TripMeCubit>();
                              final confirm = await showAppDialog(
                                context,
                                icon: Icons.cancel_schedule_send_rounded,
                                title: 'إلغاء الرحلة',
                                message: 'سيصل إشعار بالإلغاء إلى من حجز '
                                    'فيها، وتُعاد إليهم مبالغهم. ولا يمكن '
                                    'التراجع بعده.',
                                confirmLabel: 'إلغاء الرحلة',
                                cancelLabel: 'تراجع',
                                destructive: true,
                              );

                              if (confirm == true) cubit.cancelTrip(trip.id);
                            },
                          ),
                        );
                      },
                    ),
            );
          } else if (state is TripMeErorr) {
            return RefreshIndicator(
              onRefresh: () async {
                await context.read<TripMeCubit>().getMeTrips();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        SizedBox(height: 16.h),
                        IconButton(
                          onPressed: () {
                            context.read<TripMeCubit>().getMeTrips();
                          },
                          icon: Icon(
                            Icons.refresh,
                            color: MyColors.accent,
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // `TripMeCancel` و`TripMeOneLoaded` و`TripMeFinishTrip` تمرّ
          // هنا: الكيوبت نفسه يُعيد تحميل القائمة بعد الإلغاء، فلا نطلب
          // شيئاً — نُبقي مؤشّراً حتى تصل القائمة الجديدة.
          return const Center(child: LoadingWidgetSize150());
        },
      ),
    );
  }
}
