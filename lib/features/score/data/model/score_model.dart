import 'package:alatarekak/features/score/domain/entity/score_entity.dart';

class ScoreModel extends ScoreEntity {
  const ScoreModel({
    required super.score,
    required super.tier,
    required super.cancelRate,
    required super.totalRides,
    required super.totalCancellations,
    required super.canCreateRides,
    required super.canBookRides,
  });

  factory ScoreModel.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] as num?)?.toInt() ?? 0;
    return ScoreModel(
      score: score,
      tier: json['tier']?.toString() ?? '',
      cancelRate: (json['cancel_rate'] as num?)?.toDouble() ?? 0,
      totalRides: (json['total_rides'] as num?)?.toInt() ?? 0,
      totalCancellations:
          (json['total_cancellations'] as num?)?.toInt() ?? 0,
      // fallback على قواعد العمل (إنشاء >= 50، حجز >= 40) إن غاب الحقل
      canCreateRides: json['can_create_rides'] as bool? ?? score >= 50,
      canBookRides: json['can_book_rides'] as bool? ?? score >= 40,
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'tier': tier,
        'cancel_rate': cancelRate,
        'total_rides': totalRides,
        'total_cancellations': totalCancellations,
        'can_create_rides': canCreateRides,
        'can_book_rides': canBookRides,
      };
}

class ScoreHistoryModel extends ScoreHistoryEntity {
  const ScoreHistoryModel({
    required super.id,
    required super.action,
    required super.points,
    required super.previousScore,
    required super.newScore,
    required super.reason,
    super.createdAt,
  });

  factory ScoreHistoryModel.fromJson(Map<String, dynamic> json) {
    return ScoreHistoryModel(
      id: json['id'] as int,
      action: json['action']?.toString() ?? '',
      points: json['points']?.toString() ?? '0',
      previousScore: (json['previous_score'] as num?)?.toInt() ?? 0,
      newScore: (json['new_score'] as num?)?.toInt() ?? 0,
      reason: json['reason']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
