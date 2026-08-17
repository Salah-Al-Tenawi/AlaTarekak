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

  /// حدّا العمل من §5.1 — تُعرضان للمستخدم ليعرف ما ينقصه.
  static const int minScoreToCreate = 50;
  static const int minScoreToBook = 40;

  /// المستويات كما في الخادم.
  ///
  /// كانت الخريطة تحوي `platinum` وهو **لا وجود له عندهم**، وتُغفل
  /// `restricted` وهو المستوى الافتراضي في رد الملف الشخصي — فيُعرض
  /// «Restricted» بالإنجليزية للمستخدم.
  static const Map<String, String> tierLabels = {
    'restricted': 'مقيَّد',
    'bronze': 'برونزي',
    'silver': 'فضي',
    'gold': 'ذهبي',
  };

  String get tierLabel => tierLabels[tier.trim().toLowerCase()] ?? tier;
}

/// ما تسبّب في تغيّر النقاط — رحلة أو حجز.
///
/// المواصفة كانت تعرض `reference_type` و`reference_id` مفردين، أما
/// `/score/transactions` فيرسل كائناً كاملاً فيه المسار والموعد والحالة —
/// فيصير بإمكان السجلّ أن يقول **أي** رحلة خصمت النقاط لا رقمها فقط.
class ScoreReferenceEntity {
  final String type;
  final int? id;
  final String? origin;
  final String? destination;
  final DateTime? departureTime;
  final String? status;

  const ScoreReferenceEntity({
    this.type = '',
    this.id,
    this.origin,
    this.destination,
    this.departureTime,
    this.status,
  });

  bool get isEmpty => id == null && (origin ?? '').isEmpty;

  /// «عمّان → الزرقاء» — يُخفى السطر إن نقص أحد الطرفين
  String? get routeLabel {
    final from = origin?.trim();
    final to = destination?.trim();
    if (from == null || from.isEmpty || to == null || to.isEmpty) return null;
    return '$from → $to';
  }
}

/// صفحة من سجلّ النقاط — `meta` في رد `/score/transactions`.
class ScoreHistoryPage {
  final List<ScoreHistoryEntity> items;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  const ScoreHistoryPage({
    required this.items,
    this.total = 0,
    this.perPage = 20,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  bool get hasMore => currentPage < lastPage;
}

/// سجل تغيرات النقاط (§5.2)
class ScoreHistoryEntity {
  final int id;
  final String action;

  /// كما يرسله الخادم: "+5" أو "-10"
  final String points;
  final int previousScore;
  final int newScore;

  /// نصّ إنجليزي من الخادم (§5.2) — لا يُعرض للمستخدم كما هو.
  final String reason;

  /// طُبِّق جزاء معدّل الإلغاء المرتفع على هذه الحركة.
  final bool highCancelRateApplied;

  final DateTime? createdAt;

  /// الرحلة أو الحجز الذي سبّب التغيّر.
  final ScoreReferenceEntity? reference;

  /// الفرق رقماً حين يرسله الخادم صريحاً (`points.value` أو `score.delta`)،
  /// وهو أوثق من انتزاعه من نصّ العرض.
  final int? delta;

  const ScoreHistoryEntity({
    required this.id,
    required this.action,
    required this.points,
    required this.previousScore,
    required this.newScore,
    required this.reason,
    this.highCancelRateApplied = false,
    this.createdAt,
    this.reference,
    this.delta,
  });

  /// الفرق رقماً — الرقم الصريح أولاً، وإلا انتزاعاً من "+5" / "-10"
  int get pointsDelta =>
      delta ?? int.tryParse(points.replaceAll('+', '').trim()) ?? 0;

  /// كانت `points.startsWith('+')` تُصنّف «+0» إيجابية — والحركات بصفر
  /// نقطة تُسجَّل فعلاً في السجل ويجب ألّا تُعرض كمكافأة.
  bool get isPositive => pointsDelta > 0;
  bool get isNegative => pointsDelta < 0;
  bool get isNeutral => pointsDelta == 0;

  /// «تمت إضافة 10 نقاط» · «تم خصم 5 نقاط» — السطر الأساسي في السجل،
  /// مشتقّ من [points] وحده فيصحّ أياً كان `action` الذي يرسله الخادم.
  String get deltaLabel {
    if (isNeutral) return 'بلا تغيير في النقاط';
    final phrase = pointsPhrase(pointsDelta.abs());
    return isPositive ? 'تمت إضافة $phrase' : 'تم خصم $phrase';
  }

  /// صيغ العدد العربية: نقطة · نقطتين · ٣–١٠ نقاط · ١١+ نقطة
  static String pointsPhrase(int count) {
    if (count == 1) return 'نقطة واحدة';
    if (count == 2) return 'نقطتين';
    if (count <= 10) return '$count نقاط';
    return '$count نقطة';
  }

  /// سبب الحركة بالعربية حين نعرف `action`؛ وإلا `null` فلا يُعرض سطر
  /// ثانٍ بدل عرض نصّ الخادم الإنجليزي.
  String? get actionLabel => _actionLabels[action.trim().toLowerCase()];

  static const Map<String, String> _actionLabels = {
    'ride_completed': 'إكمال رحلة',
    'ride_created': 'إنشاء رحلة',
    'ride_cancelled': 'إلغاء رحلة',
    'ride_cancelled_by_driver': 'إلغاء الرحلة من السائق',
    // رُصد في رد /score/transactions
    'driver_cancel_ride_late': 'إلغاء السائق للرحلة متأخراً',
    'booking_completed': 'إتمام حجز',
    'booking_confirmed': 'تأكيد حجز',
    'booking_cancelled': 'إلغاء حجز',
    'passenger_cancelled': 'إلغاء الراكب لمقاعده',
    'seats_partially_cancelled': 'إلغاء جزء من المقاعد',
    'no_show': 'عدم الحضور',
    'no_show_recorded': 'تسجيل عدم حضورك',
    'passenger_no_show': 'عدم حضور الراكب',
    'driver_no_show': 'عدم حضور السائق',
    'driver_no_show_recorded': 'بلاغ عدم حضور بحقك',
    'high_cancel_rate': 'معدّل إلغاء مرتفع',
    'complaint_resolved': 'نتيجة شكوى',
    'verification_approved': 'توثيق الحساب',
    'account_banned': 'حظر الحساب',
    'account_unbanned': 'إعادة تفعيل الحساب',
  };
}
