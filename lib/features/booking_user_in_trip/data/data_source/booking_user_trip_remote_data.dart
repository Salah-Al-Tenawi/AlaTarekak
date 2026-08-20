import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/model/booking_user_modle.dart';
import 'package:alatarekak/features/profiles/data/model/comment_model.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

class BookingUserTripRemoteData {
  final ApiConSumer api;

  BookingUserTripRemoteData({required this.api});
  /// `GET /rides/{id}/passengers` — الرحلة وحجوزاتها.
  ///
  /// الشاشة كانت تعرض ما مرّرته إليها شاشة التفاصيل من `GET /rides/{id}`
  /// وحده، فتظهر فارغة إن لم يُرسل ذلك المسار الحجوزات. وهذا المسار
  /// موضوع لهذا الغرض بعينه، ويردّ بيانات طازجة بعد كل قبول أو رفض.
  ///
  /// **الاسم `passengers` لا `passengers`.** بقي هنا بالإملاء الخاطئ بعد
  /// تصحيحه في شاشة التفاصيل، فصار الطلب يفشل بينما تُعرض القائمة التي
  /// مرّرتها التفاصيل — حجوزات ظاهرة ورسالة خطأ فوقها في آن.
  Future<TripModel> tripPassengers(int rideId) async {
    final response = await api.get(
      "${ApiEndPoint.rides}/$rideId/passengers",
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
    );

    return TripModel.fromMap(response);
  }

  Future<BookingUserModle> acceptPassanger(int bookingId) async {
    final response = await api.post(
        "${ApiEndPoint.bookings}/$bookingId/accept",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});
    return BookingUserModle.fromJson(response);
  }

  Future<dynamic> rejectPassanger(int bookingId) async {
    final response = await api.post(
        "${ApiEndPoint.bookings}/$bookingId/reject",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});

    return response;
  }

  /// تقييم السائق لراكبه — `POST /profile/{userId}/rate`.
  ///
  /// المسار نفسه الذي يقيّم به الراكبُ سائقَه: التقييم صفة مستخدم لا
  /// صفة دور.
  Future<RatingModle> rateUser(double rating, int userId) async {
    final response = await api.post(
      "${ApiEndPoint.profile}/$userId/rate",
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
      data: {ApiKey.rating: rating},
    );
    return RatingModle.fromJson(response);
  }

  /// تعليق على راكب — `POST /profile/{userId}/comments`.
  Future<CommentModel> addcommit(String comment, int userId) async {
    final response = await api.post(
      "${ApiEndPoint.profile}/$userId/comments",
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
      data: {ApiKey.comment: comment},
    );
    return CommentModel.fromJson(response);
  }

  /// بلاغ السائق أن الراكب لم يحضر — POST /bookings/{id}/passenger-no-show
  Future<dynamic> passengerNoShow(int bookingId) async {
    final response = await api.post(
        "${ApiEndPoint.bookings}/$bookingId/passenger-no-show",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});
    return response;
  }
}
