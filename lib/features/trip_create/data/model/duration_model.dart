import 'package:alatarekak/core/utils/functions/json_parse.dart';

class DurationInfoModel {
  final int seconds;
  final int minutes;

  DurationInfoModel({
    required this.seconds,
    required this.minutes,
  });

  factory DurationInfoModel.fromJson(Map<String, dynamic> json) {
    final seconds = asInt(json['seconds']) ?? 0;
    return DurationInfoModel(
      seconds: seconds,
      minutes: asInt(json['minutes']) ?? (seconds / 60).round(),
    );
  }

  /// المدّة تصل كائناً `{seconds, minutes}` في الرد المحوَّل، ورقم ثوانٍ
  /// مفرداً في الصفّ الخام (`"duration": 2469`).
  factory DurationInfoModel.fromAny(dynamic value) {
    final map = asMap(value);
    if (map != null) return DurationInfoModel.fromJson(map);

    final seconds = asInt(value) ?? 0;
    return DurationInfoModel(seconds: seconds, minutes: (seconds / 60).round());
  }

  Map<String, dynamic> toJson() {
    return {
      'seconds': seconds,
      'minutes': minutes,
    };
  }
}
