import 'package:intl/intl.dart';

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