import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_navigation/get_navigation.dart';

import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/core/utils/functions/my_dilaog.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/utils/class/refund_notice.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/class/no_show_report.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';
import 'package:alatarekak/core/utils/widgets/app_error_view.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:alatarekak/core/utils/widgets/status_filter_bar.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_details_sheet.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_item.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_status_filter.dart';

class BookingMeList extends StatefulWidget {
  const BookingMeList({super.key});

  @override
  State<BookingMeList> createState() => _BookingMeListState();
}

class _BookingMeListState extends State<BookingMeList> {
  BookingStatusFilter _filter = BookingStatusFilter.all;

  /// آخر قائمة وصلت من الخادم.
  ///
  /// الكيوبت واحد لكل عمليات الشاشة، فكل إلغاء أو تقييم يُخرجه من
  /// `BookingMeListLoaded` — وكانت الشاشة حينها تعرض `SizedBox.shrink()`
  /// فتختفي الحجوزات كلها بعد أول إجراء ولا تعود إلا بإعادة فتح التبويب.
  /// الاحتفاظ بالقائمة هنا يُبقيها معروضة حتى يصل التحديث.
  List<BookingMe>? _bookings;

  /// الجلب الأول يُطلب مرّة واحدة لا مرّة لكل بناء.
  bool _fetchRequested = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      // الشاشة تُعرض كتبويب داخل الرئيسية التي لا تضع رأساً عاماً — كل
      // تبويب يوفّر رأسه بنفسه. وزر الرجوع مُلغى لأنها ليست شاشة مكدّسة.
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('حجوزاتي',
            style:
                AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: BlocConsumer<BookingMeCubit, BookingMeState>(
        listener: _onState,
        builder: (context, state) {
          if (state is BookingMeListLoaded) _bookings = state.bookings;
          final bookings = _bookings;

          if (bookings == null) {
            if (state is BookingMeErorr) return _errorView(state.message);
            if (state is! BookingMeListloading) _requestFirstFetch(context);
            return const Center(child: AppLoader());
          }

          return _loadedBody(
            bookings,
            // إجراء قيد التنفيذ: أُرسل من ورقة التفاصيل التي أُغلقت فور
            // الإرسال، فلولا هذا الشريط لبدت الشاشة جامدة حتى يصل الردّ.
            busy: state is BookingMeloading || state is BookingMeButtonloading,
          );
        },
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━ التفاعل مع الكيوبت ━━━━━━━━━━━━━━━━

  void _onState(BuildContext context, BookingMeState state) {
    if (state is BookingMeCanceled) {
      // كان يُعرض `refund_percentage` بلاحقة «ل.س»: «تم استرداد 70 ل.س»
      // على استردادٍ قدره أربعة عشر ألفاً — انظر [refundNotice]
      myConfirmDilaogWithPolicy(
        context,
        refundNotice(
          state.cancelModel.data.refundPolicy,
          wasConfirmed: state.wasConfirmed,
          cashRide: state.cashRide,
        ),
        title: state.isWholeBooking ? "تم إلغاء الحجز" : "تم إلغاء المقاعد",
      );
      _refreshData();
    } else if (state is BookingMeWholeCanceled) {
      showMySnackBar(context, state.message, type: SnackType.success);
      _refreshData();
    } else if (state is BookingMeFinish) {
      showMySnackBar(context, "تم تأكيد وصولك", type: SnackType.success);
      _refreshData();
    } else if (state is BookingMeRated) {
      showMySnackBar(context, "شكراً لك على تقييمك",
          type: SnackType.success);
      _refreshData();
    } else if (state is BookingMeAlreadyRated) {
      // ليس أحمر: تقييمه الأول قائم، وإنما تُردّ محاولة ثانية
      showMySnackBar(context, state.message, type: SnackType.info);
    } else if (state is BookingMeDriverNoShowReported) {
      _onNoShowReported(context, state);
      _refreshData();
    } else if (state is BookingMeOpenConversation) {
      Get.toNamed(RouteName.chatScreen, arguments: {
        'conversationId': state.conversationId,
        'title': state.title ?? 'سائق الرحلة',
        'avatar': state.avatar,
      });
    } else if (state is BookingMeErorr) {
      // الرسالة معرّبة مسبقاً في الكيوبت حسب نوع العملية
      showMySnackBar(context, state.message, type: SnackType.error);
    }
  }

  /// التعارض ليس سناك بار.
  ///
  /// حين يبلّغ الطرفان كلٌّ عن غياب الآخر لا تُطبَّق عقوبة تلقائية، بل
  /// تُفتح شكوى يبتّ فيها الدعم. وهذا خبرٌ يغيّر توقّع المستخدم — يمرّ
  /// على شريط يختفي بعد ثوانٍ، فيُعرض حواراً يُقرأ ويُغلق بقصد.
  ///
  /// ولا يُوجَّه إلى الشكوى برقمها: الخادم لا يُرجع `complaint_id` في
  /// استجابة البلاغ — مصدره الوحيد إشعار `noshow_conflict`.
  void _onNoShowReported(
      BuildContext context, BookingMeDriverNoShowReported state) {
    if (state.outcome != NoShowOutcome.conflict) {
      showMySnackBar(context, state.message, type: SnackType.success);
      return;
    }

    showAppDialog(
      context,
      icon: Icons.gavel_rounded,
      title: 'تعارض في البلاغات',
      message: state.message,
      accentColor: MyColors.warning,
    );
  }

  void _requestFirstFetch(BuildContext context) {
    if (_fetchRequested) return;
    _fetchRequested = true;

    final cubit = context.read<BookingMeCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cubit.getMyBooking();
    });
  }

  Future<void> _refreshData() async {
    await context.read<BookingMeCubit>().getMyBooking();
  }

  // ━━━━━━━━━━━━━━━━ الجسم ━━━━━━━━━━━━━━━━

  Widget _loadedBody(List<BookingMe> bookings, {required bool busy}) {
    final visible = _filter.apply(bookings);

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
        _filterBar(bookings),
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
                      final booking = visible[index];
                      return StaggeredItem(
                        index: index,
                        child: BookingItem(
                          // المفتاح يمنع إعادة استعمال حالة بطاقة لحجز
                          // آخر حين يتغيّر التصنيف وتُعاد ترتيب القائمة.
                          key: ValueKey(booking.bookingId),
                          booking: booking,
                          onTap: () =>
                              BookingDetailsSheet.show(context, booking),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filterBar(List<BookingMe> bookings) {
    final counts = countByFilter(bookings);

    return StatusFilterBar(
      options: [
        for (final filter in BookingStatusFilter.values)
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

  /// الشاشة الفارغة برسالة التصنيف المختار — «لا توجد حجوزات» العامّة
  /// تُوهم من فلتر على «ملغاة» أن حجوزاته كلها اختفت.
  Widget _emptyView() {
    final isFiltered = _filter != BookingStatusFilter.all;

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
                      setState(() => _filter = BookingStatusFilter.all),
                  icon: Icon(Icons.list_rounded, size: 18.sp),
                  label: const Text('عرض كل الحجوزات'),
                  style: TextButton.styleFrom(
                    foregroundColor: MyColors.accent,
                  ),
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
                title: 'تعذّر جلب حجوزاتك',
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
