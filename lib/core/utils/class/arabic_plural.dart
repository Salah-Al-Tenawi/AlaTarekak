/// صيغ العدد في العربية — مصدر واحد.
///
/// العربية تُفرد وتُثنّي وتجمع جمعَي قلّة وكثرة، و«2 دقيقة» أو «5 دقيقة»
/// يقرأها المستخدم خطأً في التطبيق لا في بياناته. كانت الصياغة مكتوبة
/// داخل عدّاد الانطلاق وحده، ثم احتاجها عدّاد فتح بوابة الإبلاغ وترجمة
/// رسائل الخادم — فجُمعت هنا.
library;

/// العدد بوحدته:
///
///   1  → «دقيقة»          (مفرد بلا رقم)
///   2  → «دقيقتين»        (مثنّى بلا رقم)
///   3–10 → «5 دقائق»      (جمع قلّة مع الرقم)
///   11+  → «15 دقيقة»     (جمع كثرة بالمفرد)
String arabicCount(
  int value, {
  required String singular,
  required String dual,
  required String plural,
}) {
  if (value == 1) return singular;
  if (value == 2) return dual;
  if (value >= 3 && value <= 10) return '$value $plural';
  return '$value $singular';
}

/// «٤٥ دقيقة» / «دقيقتين» / «7 دقائق».
String arabicMinutes(int minutes) => arabicCount(
      minutes,
      singular: 'دقيقة',
      dual: 'دقيقتين',
      plural: 'دقائق',
    );

/// «3 ساعات» / «ساعتين» / «ساعة».
String arabicHours(int hours) => arabicCount(
      hours,
      singular: 'ساعة',
      dual: 'ساعتين',
      plural: 'ساعات',
    );

/// «5 أيام» / «يومين» / «يوم».
String arabicDays(int days) => arabicCount(
      days,
      singular: 'يوم',
      dual: 'يومين',
      plural: 'أيام',
    );
