import 'package:alatarekak/core/api/api_end_points.dart';
class RatingModle {
  final String message;
  final int totalRating;
  final double averageRating;

  RatingModle({
    required this.message,
    required this.totalRating,
    required this.averageRating,
  });

  factory RatingModle.fromJson(Map<String, dynamic> json) {
    final data = json[ApiKey.data] ?? {};

    return RatingModle(
      message: json[ApiKey.message] ?? "",
      totalRating: data[ApiKey.totalRatings] ?? 0,
      averageRating: (data[ApiKey.averageRating] is num)
          ? (data[ApiKey.averageRating] as num).toDouble()
          : 0.0,
    );
  }
}

