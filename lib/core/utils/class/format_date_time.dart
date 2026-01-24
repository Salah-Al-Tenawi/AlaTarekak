import 'package:intl/intl.dart';

class DateTimeUtils {
  // تنسيق التاريخ فقط (يوم/شهر/سنة)
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // تنسيق الوقت فقط (ساعة:دقيقة + ص/م)
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  // تنسيق التاريخ والوقت معاً
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy - hh:mm a').format(date);
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
    if (days > 0) parts.add('${days} يوم');
    if (hours > 0) parts.add('${hours} ساعة');
    if (minutes > 0 || parts.isEmpty) parts.add('${minutes} دقيقة');
    
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