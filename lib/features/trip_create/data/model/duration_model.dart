class DurationInfoModel {
  final int seconds;
  final int minutes;

  DurationInfoModel({
    required this.seconds,
    required this.minutes,
  });

  factory DurationInfoModel.fromJson(Map<String, dynamic> json) {
    return DurationInfoModel(
      seconds: json['seconds'],
      minutes: json['minutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seconds': seconds,
      'minutes': minutes,
    };
  }
}
