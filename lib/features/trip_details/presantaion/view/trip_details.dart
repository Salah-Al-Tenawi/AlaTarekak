import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/chat/domain/entity/quick_messages.dart';
import 'package:alatarekak/features/trip_details/presantaion/manger/cubit/tripdetails_cubit.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/widget/body_trip_details.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/widget/trip_details_error_view.dart';

class TripDetails extends StatefulWidget {
  const TripDetails({super.key});

  @override
  State<TripDetails> createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails> {
  late final int tripId;

  /// صفة من فتح الشاشة، **ثلاثية**: `true` من «رحلاتي»، و`null` حين
  /// يصل المعرّف وحده — من إشعار مثلاً — فلا يعرف المستدعي من يقرؤه.
  /// الكيوبت يحسم المجهولة من الردّ.
  late final bool? asDriver;

  @override
  void initState() {
    // المعرّف وحده هو الشكل الشائع؛ والخريطة تحمل معه صفة المستدعي.
    final args = Get.arguments;
    if (args is Map) {
      tripId = args['tripId'] as int;
      asDriver = args['asDriver'] as bool?;
    } else {
      tripId = args as int;
      asDriver = null;
    }

    context.read<TripDetailsCubit>().fetchTrip(tripId, asDriver: asDriver);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      // كانت الشاشة بلا شريط علوي إطلاقاً: لا عنوان ولا زرّ رجوع، فلا
      // مخرج منها إلا زرّ النظام — والقادم إليها من إشعار لا يعرف أين هو.
      appBar: AppBar(
        title: const Text('تفاصيل الرحلة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
          onPressed: () => Get.back(),
          tooltip: 'رجوع',
        ),
        actions: [
          IconButton(
            onPressed: () =>
                context.read<TripDetailsCubit>().fetchTrip(tripId, asDriver: asDriver),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<TripDetailsCubit>().fetchTrip(tripId, asDriver: asDriver);
        },
        child: BlocConsumer<TripDetailsCubit, TripDetailsState>(
          // **لا يُبنى إلا لحالات العرض الثلاث.**
          //
          // الكيوبت يُصدر حالات ليست شاشات: `GoToProfile` و`GoToChat`
          // و`OpenConversation` و`FinishTrip` و`RequestBooking` — إشارات
          // للمستمع لا محتوى. وكان البنّاء يُستدعى لها فتسقط في الفرع
          // الأخير، فتُمحى الرحلة من الشاشة ويبقى زرّ «أعد المحاولة»
          // وحده بلا خطأ ولا سبب: يكفي أن يفتح المستخدم ملف السائق ثم
          // يعود، أو أن ينهي السائق رحلته.
          //
          // بهذا الحارس تبقى آخر رحلة معروضة كما هي حتى يصل جديد.
          buildWhen: (previous, current) =>
              current is TripDetailsLoading ||
              current is TripDetailsError ||
              current is TripDetailsLoaded,
          listener: (context, state) {
            if (state is TripDetailsGoToProfile) {
              Get.toNamed(RouteName.profile, arguments: state.userId);
            } else if (state is TripDetailsGoToChat) {
              context.read<TripDetailsCubit>().openChatWith(
                    userId: state.driverId,
                    name: state.driverName,
                    avatar: state.driverAvatar,
                  );
            } else if (state is TripDetailsOpenConversation) {
              // نعيد جلب الرحلة أولاً حتى لا تعود الشاشة فارغة بعد الرجوع
              context.read<TripDetailsCubit>().fetchTrip(tripId, asDriver: asDriver);
              Get.toNamed(RouteName.chatScreen, arguments: {
                'conversationId': state.conversationId,
                'title': state.title ?? 'السائق',
                'avatar': state.avatar,
              });
            } else if (state is TripDetailsFinishTrip) {
              // بلا إعادة جلب تبقى الشاشة تعرض الرحلة «نشطة» بعد إنهائها
              context.read<TripDetailsCubit>().fetchTrip(tripId, asDriver: asDriver);
              Get.snackbar('تم إنهاء الرحلة',
                  'شكراً لك، يمكنك متابعة تقييم الركّاب من صفحة الرحلة',
                  snackPosition: SnackPosition.BOTTOM);
            } else if (state is TripDetailsCancel) {
              Get.snackbar('تم إلغاء الرحلة', state.message,
                  snackPosition: SnackPosition.BOTTOM);
            } else if (state is TripDetailsRequestBooking) {
              context.read<TripDetailsCubit>().fetchTrip(tripId, asDriver: asDriver);
              // رحلات direct تُخصم مقاعدها فوراً (confirmed)، أما رحلات
              // request فتنتظر موافقة السائق (pending) — حالتان مختلفتان
              // تماماً ولا يصحّ إظهارهما برسالة واحدة.
              final booking = state.booking.data;
              final isPending = booking?.status == 'pending';
              final conversationId = state.conversationId;

              Get.snackbar(
                isPending ? 'تم إرسال الطلب' : 'تم تأكيد الحجز',
                isPending
                    ? 'طلبك بانتظار موافقة السائق (رقم ${booking?.id})'
                    : conversationId != null
                        ? 'فُتحت محادثة مع السائق للاتفاق على مكان اللقاء'
                        : 'تم تأكيد حجزك، رقم الطلب: ${booking?.id}',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 6),
                mainButton: conversationId == null
                    ? null
                    : TextButton(
                        onPressed: () {
                          Get.closeCurrentSnackbar();
                          Get.toNamed(RouteName.chatScreen, arguments: {
                            'conversationId': conversationId,
                            'title': state.driverName ?? 'السائق',
                            'avatar': state.driverAvatar,
                            'draft': QuickMessages.passengerOpener,
                          });
                        },
                        child: const Text('فتح المحادثة'),
                      ),
              );
            }
          },
          builder: (context, state) {
            if (state is TripDetailsLoading) {
              return const Center(child: LoadingWidgetSize150());
            } else if (state is TripDetailsError) {
              // الرسالة أصبحت معرّبة في الكيوبت — نطابق الترجمة العربية
              if (state.message.contains("توثيق حسابك كراكب")) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Get.toNamed(RouteName.verfiyUser, arguments: "passanger");
                  showMySnackBar(context, "يجب عليك توثيق حسابك");
                });
              } else {
                return TripDetailsErrorView(
                  message: state.message,
                  onRetry: () =>
                      context.read<TripDetailsCubit>().fetchTrip(tripId, asDriver: asDriver),
                );
              }
            } else if (state is TripDetailsLoaded) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  BodyTripDetails(
                    trip: state.trip,
                    mode: state.mode,
                  ),
                ],
              );
            }

            // حالة بلا فرع خاص (طلب حجز قيد الإرسال مثلاً) — مؤشّر
            // انتظار أصدق من زرّ إعادة محاولة لشيء لم يفشل.
            return const Center(child: LoadingWidgetSize150());
          },
        ),
      ),
    );
  }
}
