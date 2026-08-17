import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/booking_chat_service.dart';
import 'package:alatarekak/core/utils/functions/json_parse.dart';
import 'package:alatarekak/features/chat/domain/entity/quick_messages.dart';

/// أين يذهب المستخدم حين يضغط إشعاراً — من **أي** مصدر.
///
/// للإشعار مدخلان: بطاقة داخل قائمة الإشعارات، وإشعار نظام من FCM يصل
/// والتطبيق في الخلفية أو مغلق. كان لكل مدخل توجيهه: القائمة تفتح
/// المحادثة والشكوى والرحلة، وFCM يفتح المحادثة **وحدها** ويتجاهل الباقي
/// — فيضغط المستخدم إشعار «قُبل حجزك» فلا يحدث شيء.
///
/// الوجهة صفة للإشعار لا للشاشة التي عُرض فيها، فهي هنا مرة واحدة.
class NotificationRouter {
  NotificationRouter._();

  /// [data] حمولة الإشعار: `ride_id` و`conversation_id` و`complaint_id`.
  /// تصل من الخادم أرقاماً في رد `/notifications` ونصوصاً في حمولة FCM،
  /// فتُقرأ بـ [asInt] لا بتحويل مباشر.
  static Future<void> open({
    String? type,
    String? category,
    String? title,
    Map<String, dynamic>? data,
  }) async {
    final payload = data ?? const <String, dynamic>{};
    final rideId = asInt(payload['ride_id']);
    final conversationId = asInt(payload['conversation_id']);
    final complaintId = asInt(payload['complaint_id']);

    // قبِل السائق الحجز ← صار بين الطرفين حجز فعلي، فنفتح المحادثة
    // للاتفاق على مكان اللقاء بدل الاكتفاء بعرض تفاصيل الرحلة.
    if (type == 'booking_accepted' && rideId != null) {
      final target = await BookingChatService.instance.withDriverOfRide(rideId);
      if (target != null) {
        Get.toNamed(RouteName.chatScreen, arguments: {
          'conversationId': target.conversationId,
          'title': target.title ?? 'السائق',
          'avatar': target.avatar,
          'draft': QuickMessages.passengerOpener,
        });
        return;
      }
      // تعذّرت المحادثة ← نكمل إلى تفاصيل الرحلة كالمعتاد
    }

    if (conversationId != null) {
      // إشعار chat_message: العنوان الخام = اسم المرسل (من الباك إند)
      Get.toNamed(RouteName.chatScreen, arguments: {
        'conversationId': conversationId,
        'title': title,
        'avatar': null,
      });
      return;
    }

    if (complaintId != null) {
      Get.toNamed(RouteName.complaintDetail, arguments: complaintId);
      return;
    }

    if (rideId != null) {
      Get.toNamed(RouteName.tripDetails, arguments: rideId);
      return;
    }

    if (category == 'chat') {
      Get.toNamed(RouteName.chatListScreen);
      return;
    }

    // لا وجهة معروفة ← يبقى المستخدم مكانه
  }

  /// حمولة FCM: كل قيمها نصوص، والنوع والعنوان يصلان داخلها لا في كيان.
  static Future<void> openFromPush(Map<String, dynamic> data) => open(
        type: asString(data['type']),
        category: asString(data['category']),
        title: asString(data['title']),
        data: data,
      );
}
