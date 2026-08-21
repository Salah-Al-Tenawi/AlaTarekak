import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/core/utils/class/syrian_phone.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_details/data/model/booking_model.dart';

class TripDetailsRemoteDataSource {
  final DioConSumer api;

  TripDetailsRemoteDataSource({required this.api});

  /// `GET /rides/{id}/passengers` — الرحلة **وحجوزاتها**، لسائقها وحده.
  ///
  /// المسار العام `GET /rides/{id}` لا يرسل الحجوزات عمداً: لا يصحّ أن
  /// يطّلع أي مستخدم على حجوزات رحلة ليست له. فمن يفتح رحلته من «رحلاتي»
  /// يُجلب له هذا، ومن يفتح رحلة غيره من البحث يُجلب له الأول.
  Future<TripModel> featchTripWithBookings(int tripId) async {
    final response = await api.get("${ApiEndPoint.rides}/$tripId/passengers",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});

    return TripModel.fromMap(response);
  }

  Future<TripModel> featchTrip(int tripId) async {
    final response = await api.get("${ApiEndPoint.rides}/$tripId",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});

    return TripModel.fromMap(response);
  }

  /// [idempotencyKey] يجب أن يبقى ثابتاً طوال محاولة الحجز الواحدة —
  /// إعادة إرساله بعد انقطاع تُرجع نفس الحجز بدل إنشاء حجز ثانٍ.
  /// من يستدعي هذه الدالة هو المسؤول عن تثبيته (انظر TripDetailsCubit).
  Future<BookingResponse> booking(int seats, int tripId,
      String communicationNumber, String idempotencyKey) async {
    final response = await api.post("${ApiEndPoint.rides}/$tripId/book",
        header: {
          ApiKey.authorization: "Bearer ${mytoken()}"
        },
        data: {
          ApiKey.seats: seats,
          // الخادم يقبل 09XXXXXXXX وحدها — يُطبَّع هنا مهما كتبه المستخدم
          ApiKey.communicationNumber:
              SyrianPhone.normalize(communicationNumber) ?? communicationNumber,
          'idempotency_key': idempotencyKey,
        });
    return BookingResponse.fromJson(response);
  }
  // todo model
  /// إلغاء السائق رحلته — `PATCH /rides/{id}/cancel`.
  ///
  /// المسار نفسه الذي تستعمله شاشة «رحلاتي». وكان الإلغاء متاحاً من
  /// القائمة وحدها: من فتح تفاصيل رحلته لم يجد سبيلاً إليه فيها.
  Future<dynamic> cancelTrip(int tripId) async {
    final response = await api.patch(
      "${ApiEndPoint.rides}/$tripId/cancel",
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
    );
    return response;
  }

  Future<dynamic> finishTrip(int tripId) async {
    final response = await api.post("${ApiEndPoint.rides}/$tripId/finish" , 
    header: {ApiKey.authorization: "Bearer ${mytoken()}"} ) ;
    return response;
    
  }

  // todo model
  Future<dynamic> confirmTrip(int tripId) async {
    final response = await api.post("${ApiEndPoint.rides}/$tripId/driver-confirm" , 
    header: {ApiKey.authorization: "Bearer ${mytoken()}"} ) ;
    return response;
    
  }

}
