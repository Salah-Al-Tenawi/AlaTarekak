/// نصّ العدّ التنازلي إلى موعد الانطلاق.
///
/// كان مكتوباً داخل بطاقة «حجوزاتي» كدالة خاصّة، فلمّا انقسمت البطاقة إلى
/// ملخّص وورقة تفاصيل احتاجه الاثنان. **دالّة نقيّة** تأخذ [now]
/// اختيارياً فتُختبر بلا انتظار ولا ساعة نظام.
library;

import 'package:alatarekak/core/utils/class/arabic_plural.dart';

/// ما بقي على الانطلاق مفصّلاً — `null` إن حلّ الموعد أو مضى.
///
/// يُعرض في بطاقة الملخّص حيث لا مكان لجملة كاملة.
String? remainingUntilDeparture(DateTime departure, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (!departure.isAfter(current)) return null;

  final difference = departure.difference(current);
  final days = difference.inDays;
  final hours = difference.inHours % 24;
  final minutes = difference.inMinutes % 60;

  final parts = <String>[
    if (days > 0) arabicDays(days),
    if (hours > 0) arabicHours(hours),
    // الدقائق تُذكر وحدها أو مع الساعات؛ ذكرها مع الأيام ضجيج
    if (minutes > 0 && days == 0) arabicMinutes(minutes),
  ];

  return parts.isEmpty ? null : parts.join(' و ');
}

/// الجملة الكاملة كما تُعرض في ورقة التفاصيل.
String countdownToDeparture(DateTime departure, {DateTime? now}) {
  final remaining = remainingUntilDeparture(departure, now: now);
  return remaining == null ? 'انطلقت الرحلة' : 'باقٍ على الانطلاق: $remaining';
}
