import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/features/profiles/data/date_source/profile_local_data_source.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

class TripCreateRemoteDataSource {
  final DioConSumer api;

  TripCreateRemoteDataSource({required this.api});

  Future<TripModel> createTrip(
  String startLat,
  String startLng,
  String endLat,
  String endLng,
  String date,
  int seats,
  int price,
  String? notes,
  int routeIndex,
  String paymentMethod,
  String bookingType,
  String communicationNumber,
) async {
  final response = await api.post(
    ApiEndPoint.createRide,
    header: {ApiKey.authorization: "Bearer ${mytoken()}"},
    data: {
      ApiKey.pickuplat: startLat,
      ApiKey.pickuplng: startLng,
      ApiKey.destinationlat: endLat,
      ApiKey.destinationlng: endLng,
      ApiKey.departureTime: date,
      ApiKey.availableSeats: seats,
      ApiKey.pricePerSeat: price,
      ApiKey.notes: notes,
      ApiKey.routeIndex: routeIndex,
      ApiKey.paymentmethod: paymentMethod,
      ApiKey.bookingType: bookingType.toLowerCase(),
      ApiKey.communicationNumber: communicationNumber,
      // حقل إلزامي في الخادم. ليس اختياراً يخصّ الرحلة بل صفة لسيارة
      // السائق المسجّلة، فنقرؤه من ملفه المخزّن محلياً بدل سؤاله عنه
      // في كل رحلة. إن غاب يرفض الخادم بـ 422 برسالة مترجَمة توجّهه
      // إلى إضافة سيارته.
      if (_myVehicleType() != null) 'vehicle_type': _myVehicleType(),
    },
  );

  // من respone.json.data إلى TripModel
  final trip = TripModel.fromJson(response).first;
  return trip;
}

  /// نوع سيارة السائق من ملفه المخزّن محلياً — null إن لم يُخزَّن الملف
  /// بعد أو لم يسجّل السائق سيارة.
  String? _myVehicleType() {
    try {
      final id = myid();
      if (id == null) return null;
      final type = ProfileLocalDataSourceIm().getProfile(id)?.car?.type;
      return (type == null || type.isEmpty) ? null : type;
    } catch (_) {
      return null;
    }
  }
}
