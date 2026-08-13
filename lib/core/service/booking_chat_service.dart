import 'package:flutter/foundation.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/service/locator_ser.dart';
import 'package:alatarekak/features/chat/data/data_source/chat_remote_data_source.dart';
import 'package:alatarekak/features/chat/data/repo/chat_repo_impl.dart';
import 'package:alatarekak/features/trip_details/data/data_source/trip_details_remote_data_source.dart';
import 'package:alatarekak/features/trip_details/data/repo/trip_details_repo.dart';

/// وجهة محادثة جاهزة للفتح.
class ChatTarget {
  final int conversationId;
  final String? title;
  final String? avatar;

  const ChatTarget({required this.conversationId, this.title, this.avatar});
}

/// فتح محادثة بين طرفَي حجز.
///
/// إشعار `booking_accepted` يحمل `ride_id` و`booking_id` فقط ولا يحمل
/// معرّف السائق، لذا نجلب الرحلة أولاً لنعرف مع مَن نفتح المحادثة.
///
/// المحادثة مسموحة هنا لأن الحجز أصبح مؤكَّداً فعلاً بقبول السائق.
class BookingChatService {
  BookingChatService._();
  static final BookingChatService instance = BookingChatService._();

  TripDetailsRepoIM get _rides => TripDetailsRepoIM(
        remoteDataSource:
            TripDetailsRemoteDataSource(api: getit.get<DioConSumer>()),
      );

  ChatRepoImpl get _chat => ChatRepoImpl(
        remoteDataSource:
            ChatRemoteDataSourceImpl(api: getit.get<DioConSumer>()),
      );

  /// يفتح (أو يستعيد) المحادثة مع سائق الرحلة [rideId].
  /// يرجع null عند أي فشل — والمستدعي يتراجع إلى وجهة أخرى.
  Future<ChatTarget?> withDriverOfRide(int rideId) async {
    final ride = await _rides.featchTrip(rideId);

    final driver = ride.fold((_) => null, (trip) => trip.driver);
    if (driver == null || driver.id <= 0) {
      debugPrint('[BookingChat] تعذّر جلب سائق الرحلة $rideId');
      return null;
    }

    final conversation = await _chat.startConversation(userId: driver.id);
    return conversation.fold(
      (failure) {
        debugPrint('[BookingChat] تعذّر فتح المحادثة: ${failure.message}');
        return null;
      },
      (id) => id > 0
          ? ChatTarget(
              conversationId: id, title: driver.name, avatar: driver.avatar)
          : null,
    );
  }
}
