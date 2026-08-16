/// قراءة متسامحة لحقول JSON.
///
/// الخادم يرسل الحقل نفسه بأنماط مختلفة حسب المسار: المبلغ قد يصل نصاً
/// ("26000.00") أو رقماً، والموقع قد يصل كائناً متداخلاً أو حقولاً مسطّحة،
/// والحقل قد يغيب أصلاً. والقراءة المباشرة `json['x']` تنهار عندها برسالة
/// `Null is not a subtype of int` — وهي رسالة لا تدلّ على الحقل المكسور
/// ولا على ما وصل فعلاً، فيتحوّل كل تغيير في الخادم إلى بحث أعمى.
///
/// هذه الدوال تقرأ ما يمكن قراءته، وتُسمّي الحقل صراحةً حين يستحيل.
library;

int? asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.round();
  return null;
}

double? asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// النصّ كما وصل. الأرقام تُحوَّل لأن الخادم يرسل السعر نصاً حيناً ورقماً
/// حيناً، والواجهة تعرضه نصاً في الحالتين.
String? asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is num || v is bool) return v.toString();
  return null;
}

DateTime? asDate(dynamic v) {
  if (v is DateTime) return v;
  final s = asString(v);
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

Map<String, dynamic>? asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

List<dynamic>? asList(dynamic v) => v is List ? v : null;

/// أول قيمة غير فارغة بين مفاتيح مترادفة.
///
/// يوجد للحقل الواحد أكثر من اسم بحسب المسار: `departure` في الرد المحوَّل
/// و`departure_time` في الصفّ الخام. قراءتهما معاً تُبقي التطبيق عاملاً
/// أياً كان المسار الذي غيّره الخادم.
dynamic pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v != null) return v;
  }
  return null;
}

/// حقل لا يقوم الكيان بدونه — ورسالته تذكر ما وصل فعلاً.
///
/// الغرض تشخيصي: أي تغيير لاحق في الخادم يُقرأ من رسالة واحدة بدل تتبّع
/// `Null is not a subtype of ...` يدوياً في الشيفرة.
class JsonFieldMissing implements Exception {
  final String entity;
  final String field;
  final Iterable<String> received;

  JsonFieldMissing(this.entity, this.field, this.received);

  @override
  String toString() => '$entity: الحقل «$field» مفقود في رد الخادم — '
      'المفاتيح الواصلة: ${received.join(', ')}';
}

T requireField<T>(T? value, String entity, String field,
    Map<String, dynamic> source) {
  if (value == null) throw JsonFieldMissing(entity, field, source.keys);
  return value;
}
