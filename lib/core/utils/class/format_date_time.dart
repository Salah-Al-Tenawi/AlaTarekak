import 'package:intl/intl.dart';

/// صيغ العدد الأربع لوحدة زمنية واحدة في العربية.
class _UnitForms {
  final String singular; // واحد:    «دقيقة»
  final String dual; //     اثنان:   «دقيقتين»
  final String few; //      ٣–١٠:    «دقائق»
  final String many; //     ١١+:     «دقيقة»

  const _UnitForms(this.singular, this.dual, this.few, this.many);
}

class DateTimeUtils {
  // تنسيق التاريخ فقط (يوم/شهر/سنة)
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // تنسيق الوقت فقط (ساعة:دقيقة + ص/م)
  //
  // الصيغة تُبنى يدوياً لا بـ DateFormat('a'): الأخيرة تُخرج "AM/PM"
  // بالإنجليزية ما لم تُهيَّأ بيانات المحليّة العربية، وقاعدتنا ألّا يظهر
  // نصّ إنجليزي للمستخدم.
  static String formatTime(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour >= 12 ? 'م' : 'ص';
    return '${hour12.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')} $period';
  }

  // تنسيق التاريخ والوقت معاً
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} - ${formatTime(date)}';
  }

  /// وقت آخر رسالة في بطاقة المحادثة — الساعة إن كانت اليوم، وإلا يوم/شهر.
  ///
  /// الخادم يرسل اللحظة نفسها بصيغتين في `GET /chat/conversations`:
  /// `updated_at` تاريخاً ISO على المحادثة، و`last_message.created_at`
  /// نصّاً نسبياً إنجليزياً («9 minutes ago»). نجرّب المرشّحين بالترتيب
  /// ونأخذ أول تاريخ صالح، فإن لم يوجد ترجمنا النصّ النسبي — فلا يظهر
  /// إنجليزي في الواجهة بحال.
  static String chatListTime(List<String?> candidates) {
    for (final raw in candidates) {
      if (raw == null || raw.trim().isEmpty) continue;
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt == null) continue;

      final now = DateTime.now();
      final sameDay =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      if (sameDay) {
        return '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}';
    }

    final fallback =
        candidates.firstWhere((c) => c != null && c.trim().isNotEmpty,
            orElse: () => null);
    return fallback == null ? '' : arabicRelative(fallback);
  }

  /// «9 minutes ago» → «قبل ٩ دقائق».
  ///
  /// المفرد والمثنّى وجمع القلّة (٣–١٠) وجمع الكثرة (١١+) صيغ مختلفة في
  /// العربية، فتُكتب كلها بدل «قبل 9 دقيقة».
  static String arabicRelative(String english) {
    final text = english.trim();
    final lower = text.toLowerCase();
    if (lower == 'just now' || lower == 'now' || lower == 'a moment ago') {
      return 'الآن';
    }

    final match = RegExp(
      r'^(?:about\s+)?(\d+|an?)\s+'
      r'(second|minute|hour|day|week|month|year)s?\s+ago$',
      caseSensitive: false,
    ).firstMatch(text);
    // صيغة لا نعرفها — تُترك كما وصلت بدل اختراع ترجمة خاطئة
    if (match == null) return text;

    final rawCount = match.group(1)!.toLowerCase();
    final count = (rawCount == 'a' || rawCount == 'an')
        ? 1
        : int.tryParse(rawCount) ?? 1;
    final forms = _units[match.group(2)!.toLowerCase()]!;

    if (count == 1) return 'قبل ${forms.singular}';
    if (count == 2) return 'قبل ${forms.dual}';
    if (count <= 10) return 'قبل $count ${forms.few}';
    return 'قبل $count ${forms.many}';
  }

  static const Map<String, _UnitForms> _units = {
    'second': _UnitForms('ثانية', 'ثانيتين', 'ثوانٍ', 'ثانية'),
    'minute': _UnitForms('دقيقة', 'دقيقتين', 'دقائق', 'دقيقة'),
    'hour': _UnitForms('ساعة', 'ساعتين', 'ساعات', 'ساعة'),
    'day': _UnitForms('يوم', 'يومين', 'أيام', 'يوماً'),
    'week': _UnitForms('أسبوع', 'أسبوعين', 'أسابيع', 'أسبوعاً'),
    'month': _UnitForms('شهر', 'شهرين', 'أشهر', 'شهراً'),
    'year': _UnitForms('سنة', 'سنتين', 'سنوات', 'سنة'),
  };

  /// «الأحد، 17 آب» — صيغة التاريخ المعتمدة في شاشات إنشاء الرحلة.
  static String arabicDate(DateTime date) =>
      '${getArabicDayName(date)}، ${date.day} ${arabicMonths[date.month - 1]}';

  static const List<String> arabicMonths = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  // حساب الوقت المتبقي للرحلة
  static String getRemainingTime(DateTime departure) {
    final now = DateTime.now();
    final difference = departure.difference(now);
    
    if (difference.isNegative) {
      return 'الرحلة انتهت';
    }
    
    if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  // حساب الوقت المتبقي مع تفاصيل أكثر
  static String getDetailedRemainingTime(DateTime departure) {
    final now = DateTime.now();
    final difference = departure.difference(now);
    
    if (difference.isNegative) {
      return 'انتهت';
    }
    
    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    final minutes = difference.inMinutes.remainder(60);
    
    final parts = <String>[];
    if (days > 0) parts.add('$days يوم');
    if (hours > 0) parts.add('$hours ساعة');
    if (minutes > 0 || parts.isEmpty) parts.add('$minutes دقيقة');
    
    return parts.join(' و ');
  }

  // التحقق ما إذا كانت الرحلة انتهت
  static bool isTripEnded(DateTime departure) {
    return departure.difference(DateTime.now()).isNegative;
  }

  // الحصول على اسم اليوم بالعربية
  static String getArabicDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الاثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return '';
    }
  }
}