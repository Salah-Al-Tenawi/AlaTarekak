/// تنسيق المبالغ — مصدر واحد لكل شاشة تعرض مالاً.
///
/// الخادم يرسل المبالغ نصوصاً بخانتين عشريتين ("26000.00")، وعرضها كما هي
/// يُقرأ رقماً غريباً في واجهة عربية. الليرة السورية لا كسور عملية لها،
/// فتُحذف الأصفار العشرية ويُفصل الألف بفاصلة.
class Money {
  Money._();

  /// "26000.00" → "26,000" · 1500.5 → "1,500.50"
  static String format(dynamic value) {
    final v = _toDouble(value);
    if (v == null) return '—';

    final abs = v.abs();
    final text = abs.toStringAsFixed(abs.truncateToDouble() == abs ? 0 : 2);
    final parts = text.split('.');
    final digits = parts[0]
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    final body = parts.length > 1 ? '$digits.${parts[1]}' : digits;
    return v < 0 ? '−$body' : body;
  }

  /// المبلغ متبوعاً بالعملة — الصيغة المعتمدة في كل الشاشات.
  static String withCurrency(dynamic value) => '${format(value)} ل.س';

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
  }
}
