import 'package:alatarekak/core/utils/functions/json_parse.dart';

class CoordinatesModel {
  final double lat;
  final double lng;

  CoordinatesModel({
    required this.lat,
    required this.lng,
  });

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) {
    return CoordinatesModel(
      lat: asDouble(json['lat']) ?? 0,
      lng: asDouble(json['lng']) ?? 0,
    );
  }

  /// الإحداثيات تصل بثلاث صور: كائن `{lat, lng}`، أو حقلين مسطّحين
  /// `*_lat` و`*_lng`، أو لا تصل إطلاقاً. الصفر هنا ليس موقعاً صحيحاً
  /// لكنه يمنع انهيار الشاشة بأكملها لأجل دبّوس خريطة.
  factory CoordinatesModel.fromAny(dynamic value, {dynamic lat, dynamic lng}) {
    final map = asMap(value);
    if (map != null) return CoordinatesModel.fromJson(map);
    return CoordinatesModel(
      lat: asDouble(lat) ?? 0,
      lng: asDouble(lng) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}
