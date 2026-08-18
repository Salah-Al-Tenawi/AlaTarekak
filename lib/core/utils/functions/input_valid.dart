import 'package:get/get.dart';

import 'package:alatarekak/core/utils/class/syrian_phone.dart';

String? inputvaild(String val, String? type, int? max, int? min) {
  if (val.isEmpty) {
    return "لا يمكن ترك الحقل فارغ";
  }

  // التحقق من اسم المستخدم
  if (type == "username") {
    if (!isValidUsername(val)) {
      return "اسم المستخدم غير صالح";
    }
  }

  // التحقق من البريد الإلكتروني
  if (type == "email") {
    if (!GetUtils.isEmail(val)) {
      return "بريد إلكتروني غير صالح";
    }
  }

  // رقم التواصل: الخادم يفرض ^09\d{8}$ ويرفض ما عداه بـ 422 — بما فيه
  // صيغة المفتاح الدولي. لكن رفضَ رقم صحيح لأن صاحبه كتب مفتاح بلده ليس
  // تحقّقاً بل عرقلة، فتُقبل كل الصيغ هنا ويُطبَّع الرقم في مصادر البيانات
  // قبل إرساله. انظر [SyrianPhone].
  if (type == "nubmerphone") {
    if (!SyrianPhone.isValid(val)) return SyrianPhone.error;
  }

  // التحقق من الرابط
  if (type == "url") {
    if (!GetUtils.isURL(val)) {
      return "رابط إلكتروني غير صالح";
    }
  }

  // التحقق من الوصف
  if (type == "descrption") {
    if (val.length < 10) {
      return "لا يمكن للوصف أن يكون اقل من 10 حروف";
    }
  }

  // التحقق من الحد الأدنى للطول
  if (min != null) {
    if (val.length < min) {
      switch (type) {
        case "username":
          return "اسم المستخدم يجب ان يكون أكبر من $min أحرف";
        case "password":
          return "كلمة المرور يجب ان تكون أكبر من $min أحرف أو رموز";
      }
    }
  }

  // التحقق من الحد الأقصى للطول
  if (max != null) {
    if (val.length > max) {
      switch (type) {
        case "username":
          return "اسم المستخدم يجب ان يكون أصغر من $max أحرف";
        case "password":
          return "كلمة المرور يجب ان تكون أصغر من $max حرف أو رمز";
      }
    }
  }

  return null; // لا يوجد خطأ
}

bool isValidUsername(String username) {
  const usernamePattern = r'^[a-zA-Z\u0600-\u06FF\s]+$';
  return RegExp(usernamePattern).hasMatch(username);
}

/// تقسيم الاسم الكامل إلى اسم أول واسم أخير.
///
/// الخادم يخزّنهما حقلين ويعيدهما مجموعين في `full_name`. وشاشة التعديل
/// تعرض حقلاً واحداً كما هو معروض في الملف، فالفصل يقع هنا: أول كلمة
/// اسم أول، وما بعدها اسم العائلة كاملاً — فـ«محمد علي الحسن» تصير
/// «محمد» و«علي الحسن» لا «محمد علي» و«الحسن».
({String first, String last}) splitFullName(String fullName) {
  final parts =
      fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return (first: '', last: '');
  if (parts.length == 1) return (first: parts.first, last: '');
  return (first: parts.first, last: parts.sublist(1).join(' '));
}

/// تحقّق الاسم الكامل في شاشة تعديل المعلومات.
///
/// يشترط كلمتين: الخادم يحفظ `first_name` و`last_name` كلاً على حدة،
/// واسم من كلمة واحدة يترك حقل العائلة فارغاً فيرفضه.
String? validateFullName(String value) {
  final name = value.trim();
  if (name.isEmpty) return 'الاسم مطلوب';

  final parts = splitFullName(name);
  if (parts.last.isEmpty) return 'أدخل الاسم الأول واسم العائلة';
  if (parts.first.length < 2 || parts.last.length < 2) {
    return 'كل جزء من الاسم حرفان على الأقل';
  }
  if (name.length > 40) return 'الاسم طويل جداً';
  if (RegExp(r'[0-9]').hasMatch(name)) return 'الاسم لا يحتوي أرقاماً';

  return null;
}
