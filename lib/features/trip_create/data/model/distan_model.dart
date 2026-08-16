import 'package:alatarekak/core/utils/functions/json_parse.dart';

class DistanceModel {
  final int meters;
  final double kilometers;

  DistanceModel({
    required this.meters,
    required this.kilometers,
  });

  factory DistanceModel.fromJson(Map<String, dynamic> json) {
    final meters = asInt(json['meters']) ?? 0;
    return DistanceModel(
      meters: meters,
      kilometers: asDouble(json['kilometers']) ?? meters / 1000,
    );
  }

  /// المسافة تصل كائناً `{meters, kilometers}` في الرد المحوَّل، ورقم
  /// أمتار مفرداً في الصفّ الخام (`"distance": 47818`).
  factory DistanceModel.fromAny(dynamic value) {
    final map = asMap(value);
    if (map != null) return DistanceModel.fromJson(map);

    final meters = asInt(value) ?? 0;
    return DistanceModel(meters: meters, kilometers: meters / 1000);
  }

  Map<String, dynamic> toJson() {
    return {
      'meters': meters,
      'kilometers': kilometers,
    };
  }
}
