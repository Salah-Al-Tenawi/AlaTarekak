import 'dart:math' as math;

/// تسعير الرحلة — بالليرة السورية الجديدة.
///
/// **نقترح ولا نُجبر:** السائق يرى سعراً محسوباً على مسافة رحلته، ثم له
/// أن يقبله أو يناغشه بالعدّاد أو يكتب سعره بيده. القيد الوحيد الصلب هو
/// سقف الكيلومتر، فلا يُنشر سعر خارج المعقول على المنصّة.
///
/// **دوال نقيّة** لا تلمس واجهة ولا حالة، فتُختبَر وحدها.
class RidePriceRules {
  RidePriceRules._();

  /// سعر الكيلومتر المقترح.
  static const int suggestedRatePerKm = 60;

  /// أعلى سعر كيلومتر يُقبل — حتى بالكتابة اليدوية.
  static const int maxRatePerKm = 100;

  /// أدنى سعر كيلومتر يُقبل: نصف المقترح.
  static const int minRatePerKm = 30;

  /// مدى العدّاد حول المقترح — ما بعده يُكتب باليد.
  static const double quickRangeRatio = 0.30;

  /// نسبة الخطوة من السعر المقترح، قبل تقريبها إلى رقم مريح.
  static const double _stepRatio = 0.03;

  /// أرقام يألفها الناس في الأسعار — لا 8 ولا 24.
  static const List<int> _niceSteps = [
    1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000,
  ];

  /// خطوة الزيادة والنقصان، تكبر مع السعر.
  ///
  /// نحو 3% من المقترح مقرَّبةً إلى أقرب رقم مريح **فوقها**: تعطي 10
  /// لرحلة بـ270، و25 لرحلة بـ800 — وهما ما اتُّفق عليه.
  static int stepFor(int suggested) {
    if (suggested <= 0) return _niceSteps.first;

    final target = suggested * _stepRatio;
    for (final step in _niceSteps) {
      if (step >= target) return step;
    }
    return _niceSteps.last;
  }

  /// السعر المقترح لمسافة بالكيلومترات، مقرَّباً إلى خطوته.
  ///
  /// التقريب إلى الخطوة يُبقي العدّاد على أرقام نظيفة: من 270 إلى 280 لا
  /// من 273 إلى 283.
  static int suggestedFor(double km) {
    if (km <= 0) return 0;

    final raw = km * suggestedRatePerKm;
    final step = stepFor(raw.round());
    final rounded = (raw / step).round() * step;

    return math.max(rounded, minFor(km));
  }

  /// أدنى سعر مقبول للمسافة — بالكتابة اليدوية أيضاً.
  static int minFor(double km) =>
      km <= 0 ? 0 : math.max(1, (km * minRatePerKm).round());

  /// أعلى سعر مقبول للمسافة. القيد الصلب الوحيد.
  static int maxFor(double km) =>
      km <= 0 ? 0 : math.max(1, (km * maxRatePerKm).round());

  /// حدود العدّاد: ±[quickRangeRatio] حول المقترح، محصورة بالحدّين
  /// المطلقين.
  ///
  /// [current] يوسّع المدى ليشمله إن كان السائق قد كتب سعراً خارجه —
  /// وإلا لوجد زرّي العدّاد معطَّلين بلا سبب مفهوم.
  static ({int min, int max}) stepperRange(double km, {int? current}) {
    final suggested = suggestedFor(km);
    final absMin = minFor(km);
    final absMax = maxFor(km);

    var low = math.max(absMin, (suggested * (1 - quickRangeRatio)).round());
    var high = math.min(absMax, (suggested * (1 + quickRangeRatio)).round());

    if (current != null) {
      low = math.min(low, math.max(absMin, current));
      high = math.max(high, math.min(absMax, current));
    }

    return (min: low, max: high);
  }

  /// السعر التالي بعد ضغطة زيادة أو نقصان، محصوراً في مدى العدّاد.
  static int nextPrice(double km, int current, {required bool increase}) {
    final range = stepperRange(km, current: current);
    final step = stepFor(suggestedFor(km));

    final moved = increase ? current + step : current - step;
    return moved.clamp(range.min, range.max);
  }

  /// سعر الكيلومتر الفعلي لسعر مكتوب — يُعرض للسائق ليرى ما يفعله.
  static double ratePerKm(double km, int price) =>
      km <= 0 ? 0 : price / km;

  /// سبب رفض سعر مكتوب يدوياً، أو `null` إن كان مقبولاً.
  static String? validate(double km, int? price) {
    if (price == null || price <= 0) return 'أدخل سعراً صحيحاً';
    if (km <= 0) return null; // لا مسافة بعد — الخادم يحسم

    final max = maxFor(km);
    if (price > max) {
      return 'أعلى سعر لهذه الرحلة $max ل.س '
          '($maxRatePerKm ل.س للكيلومتر)';
    }

    final min = minFor(km);
    if (price < min) {
      return 'أقلّ سعر لهذه الرحلة $min ل.س '
          '($minRatePerKm ل.س للكيلومتر)';
    }

    return null;
  }
}
