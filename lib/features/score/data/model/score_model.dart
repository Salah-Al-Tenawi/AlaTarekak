import 'package:alatarekak/core/utils/functions/json_parse.dart';
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

class ScoreReferenceModel extends ScoreReferenceEntity {
  const ScoreReferenceModel({
    super.type,
    super.id,
    super.origin,
    super.destination,
    super.departureTime,
    super.status,
  });

  factory ScoreReferenceModel.fromJson(Map<String, dynamic> json) {
    return ScoreReferenceModel(
      type: asString(json['type']) ?? '',
      id: asInt(json['id']),
      origin: asString(json['origin']),
      destination: asString(json['destination']),
      departureTime: asDate(json['departure_time']),
      status: asString(json['status']),
    );
  }
}

/// حركة واحدة في سجلّ النقاط — **بشكليها**.
///
/// المواصفة (§5.2) تصف صفّاً مسطّحاً: `action` و`points` نصاً و
/// `previous_score` و`created_at`. أما ما شحنه الباك إند على
/// `/score/transactions` فكائنات متداخلة: `event.code` و`points.display`
/// و`score.before/after/delta` و`occurred_at`، ومعها كائن `reference`.
///
/// يُقرأ الشكلان معاً — فالفرق بينهما قرار في الخادم لا في الواجهة، وقد
/// تغيّر مرة فعلاً.
class ScoreHistoryModel extends ScoreHistoryEntity {
  const ScoreHistoryModel({
    required super.id,
    required super.action,
    required super.points,
    required super.previousScore,
    required super.newScore,
    required super.reason,
    super.highCancelRateApplied,
    super.createdAt,
    super.reference,
    super.delta,
  });

  factory ScoreHistoryModel.fromJson(Map<String, dynamic> json) {
    final event = asMap(json['event']) ?? const <String, dynamic>{};
    final points = asMap(json['points']) ?? const <String, dynamic>{};
    final score = asMap(json['score']) ?? const <String, dynamic>{};
    final reference = asMap(json['reference']);

    // الفرق الصريح: points.value أولاً ثم score.delta
    final delta = asInt(points['value']) ?? asInt(score['delta']);

    return ScoreHistoryModel(
      // كان `json['id'] as int` تحويلاً غير محروس: يرمي على أول سجل يغيب
      // فيه المعرّف أو يصل نصاً، فيُسقط الشاشة كلها لأجل صفّ واحد
      id: asInt(json['id']) ?? 0,
      action: asString(pick(event, const ['code'])) ??
          asString(json['action']) ??
          '',
      points: asString(points['display']) ??
          asString(json['points']) ??
          (delta == null ? '0' : (delta > 0 ? '+$delta' : '$delta')),
      delta: delta,
      previousScore:
          asInt(score['before']) ?? asInt(json['previous_score']) ?? 0,
      newScore: asInt(score['after']) ?? asInt(json['new_score']) ?? 0,
      // نصّ إنجليزي من الخادم — يُحفظ ولا يُعرض
      reason: asString(json['reason']) ?? '',
      highCancelRateApplied: json['high_cancel_rate_applied'] == true,
      createdAt: asDate(pick(json, const ['occurred_at', 'created_at'])),
      reference: reference != null
          ? ScoreReferenceModel.fromJson(reference)
          // الشكل المسطّح القديم: حقلان مفردان بلا تفاصيل
          : (json['reference_type'] != null || json['reference_id'] != null
              ? ScoreReferenceModel(
                  type: asString(json['reference_type']) ?? '',
                  id: asInt(json['reference_id']),
                )
              : null),
    );
  }

  /// للتخزين المحلي — بالشكل المتداخل الذي يرسله الخادم، فيقرأه
  /// [fromJson] كما يقرأ ردّ الشبكة بلا مسار ثانٍ للتفكيك.
  Map<String, dynamic> toJson() => {
        'id': id,
        'event': {'code': action},
        'points': {'value': pointsDelta, 'display': points},
        'score': {
          'before': previousScore,
          'after': newScore,
          'delta': pointsDelta,
        },
        'reason': reason,
        'high_cancel_rate_applied': highCancelRateApplied,
        'occurred_at': createdAt?.toIso8601String(),
        if (reference != null)
          'reference': {
            'type': reference!.type,
            'id': reference!.id,
            'origin': reference!.origin,
            'destination': reference!.destination,
            'departure_time': reference!.departureTime?.toIso8601String(),
            'status': reference!.status,
          },
      };
}

/// صفحة السجلّ مع كتلة `meta`. الرد القديم كان مصفوفة عارية بلا ترقيم،
/// فيُقبل الشكلان: المصفوفة وحدها، أو `{data, meta}`.
class ScoreHistoryPageModel extends ScoreHistoryPage {
  const ScoreHistoryPageModel({
    required super.items,
    super.total,
    super.perPage,
    super.currentPage,
    super.lastPage,
  });

  factory ScoreHistoryPageModel.fromJson(dynamic json) {
    final root = asMap(json) ?? const <String, dynamic>{};
    final rawItems = asList(root['data']) ?? asList(json) ?? const [];
    final meta = asMap(root['meta']) ?? const <String, dynamic>{};

    final items = rawItems
        .whereType<Map>()
        .map((e) => ScoreHistoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final perPage = asInt(meta['per_page']) ?? (items.isEmpty ? 20 : items.length);
    return ScoreHistoryPageModel(
      items: items,
      total: asInt(meta['total']) ?? items.length,
      perPage: perPage <= 0 ? 20 : perPage,
      currentPage: asInt(meta['current_page']) ?? 1,
      lastPage: asInt(meta['last_page']) ?? 1,
    );
  }
}
