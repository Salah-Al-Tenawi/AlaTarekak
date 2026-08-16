import 'package:alatarekak/core/utils/functions/json_parse.dart';

class DriverModel {
  final int id;
  final String name;
  final String? avatar;

  /// عشري لا صحيح: التقييم متوسّط حسابي يصل «4.5» من الخادم، وتقريبه
  /// إلى صحيح يُسقط نصف نجمة بلا سبب.
  final double rating;

  DriverModel({
    required this.id,
    required this.name,
    this.avatar,
    required this.rating,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: asInt(json['id']) ?? 0,
      name: _name(json),
      avatar: asString(json['avatar']),
      rating: asDouble(json['rating']) ?? 0,
    );
  }

  /// الاسم يصل بصورتين: حقلاً واحداً `name`، أو مفصولاً إلى `first_name`
  /// و`last_name` كما في مسار البحث. قراءة `name` وحدها كانت تُظهر بطاقة
  /// سائق بلا اسم رغم وصول الاسم كاملاً في الرد.
  static String _name(Map<String, dynamic> json) {
    final single = asString(pick(json, const ['name', 'full_name']))?.trim();
    if (single != null && single.isNotEmpty) return single;

    final parts = [
      asString(json['first_name'])?.trim(),
      asString(json['last_name'])?.trim(),
    ].where((p) => p != null && p.isNotEmpty).cast<String>();

    return parts.join(' ');
  }

  /// السائق يصل كائناً كاملاً في الرد المحوَّل، ومعرّفاً مفرداً في الصفّ
  /// الخام (`"driver_id": 2`). المعرّف وحده يكفي الشاشة لتعرف أن صاحب
  /// الرحلة هو المستخدم الحالي، ولتفتح ملفه عند الضغط — والاسم والصورة
  /// يبقيان فارغين حتى يُرسلهما الخادم.
  factory DriverModel.fromAny(dynamic value) {
    final map = asMap(value);
    if (map != null) return DriverModel.fromJson(map);

    return DriverModel(id: asInt(value) ?? 0, name: '', rating: 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'rating': rating,
    };
  }
}
