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

class TripDetails extends StatefulWidget {
  const TripDetails({super.key});

  @override
  State<TripDetails> createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails> {
  late final int tripId;

  @override
  void initState() {
    tripId = Get.arguments as int;
    context.read<TripDetailsCubit>().fetchTrip(tripId);
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
                context.read<TripDetailsCubit>().fetchTrip(tripId),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<TripDetailsCubit>().fetchTrip(tripId);
        },
        child: BlocConsumer<TripDetailsCubit, TripDetailsState>(
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
              context.read<TripDetailsCubit>().fetchTrip(tripId);
              Get.toNamed(RouteName.chatScreen, arguments: {
                'conversationId': state.conversationId,
                'title': state.title ?? 'السائق',
                'avatar': state.avatar,
              });
            } else if (state is TripDetailsCancel) {
              Get.snackbar('تم إلغاء الرحلة', state.message,
                  snackPosition: SnackPosition.BOTTOM);
            } else if (state is TripDetailsRequestBooking) {
              context.read<TripDetailsCubit>().fetchTrip(tripId);
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
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 200),
                    Center(child: Text("خطأ: ${state.message}")),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<TripDetailsCubit>().fetchTrip(tripId);
                        },
                        child: const Text("🔄 أعد المحاولة"),
                      ),
                    ),
                  ],
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

            return Center(
              child: ElevatedButton(
                onPressed: () {
                  context.read<TripDetailsCubit>().fetchTrip(tripId);
                },
                child: const Text("🔄 أعد المحاولة"),
              ),
            );
          },
        ),
      ),
    );
  }
}
