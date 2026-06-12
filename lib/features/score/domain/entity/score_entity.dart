/// نقاط الثقة (§5.1) — تُستخدم لتعطيل الأزرار قبل الوصول للسيرفر:
/// إنشاء رحلة يتطلب score >= 50، الحجز يتطلب score >= 40
class ScoreEntity {
  final int score;
  final String tier;
  final double cancelRate;
  final int totalRides;
  final int totalCancellations;
  final bool canCreateRides;
  final bool canBookRides;

  const ScoreEntity({
    required this.score,
    required this.tier,
    required this.cancelRate,
    required this.totalRides,
    required this.totalCancellations,
    required this.canCreateRides,
    required this.canBookRides,
  });

  static const Map<String, String> tierLabels = {
    'bronze': 'برونزي',
    'silver': 'فضي',
    'gold': 'ذهبي',
    'platinum': 'بلاتيني',
  };

  String get tierLabel => tierLabels[tier.toLowerCase()] ?? tier;
}

/// سجل تغيرات النقاط (§5.2)
class ScoreHistoryEntity {
  final int id;
  final String action;

  /// مثل "+5" أو "-10"
  final String points;
  final int previousScore;
  final int newScore;
  final String reason;
  final DateTime? createdAt;

  const ScoreHistoryEntity({
    required this.id,
    required this.action,
    required this.points,
    required this.previousScore,
    required this.newScore,
    required this.reason,
    this.createdAt,
  });

  bool get isPositive => points.startsWith('+');
}
