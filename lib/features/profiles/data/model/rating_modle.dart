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

  /// **المتوسط يصل باسم `average` في هذا المسار**، لا `average_rating`.
  ///
  /// كان يُقرأ بالاسم الثاني وحده فيعود صفراً دائماً — والشاشة تشكر
  /// المستخدم على تقييمه ثم تعرض متوسطاً صفرياً لمن قيّمه للتوّ.
  /// والاسمان يُقرآن معاً لأن ردّ الملف الشخصي يستعمل الثاني.
  factory RatingModle.fromJson(Map<String, dynamic> json) {
    final data = json[ApiKey.data] is Map ? json[ApiKey.data] : const {};

    final average = data['average'] ?? data[ApiKey.averageRating];

    return RatingModle(
      message: json[ApiKey.message] ?? "",
      totalRating: (data[ApiKey.totalRatings] is num)
          ? (data[ApiKey.totalRatings] as num).toInt()
          : 0,
      averageRating: (average is num) ? average.toDouble() : 0.0,
    );
  }
}

