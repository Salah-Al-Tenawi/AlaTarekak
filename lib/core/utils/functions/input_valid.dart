import 'package:get/get.dart';

inputvaild(String val, String? type, int? max, int? min) {
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

  // التحقق من رقم الهاتف (10 أرقام فقط)
  if (type == "nubmerphone") {
    if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) {
      return "رقم الهاتف يجب أن يكون مكون من 10 أرقام";
    }
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
