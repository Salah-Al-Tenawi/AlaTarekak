const String bookingType = "يُحدد هذا الخيار طريقة حجز المقاعد في رحلتك:\n\n"
    "• أي شخص: يُمكن للركاب الحجز فورًا دون انتظار الموافقة\n"
    "• بعد الموافقة: يتطلب كل حجز موافقتك المسبقة قبل التأكيد";

String botomBarHomeTitles(int index) {
  switch (index) {
    case 0:
      return "إنشاء رحلة";
    case 1:
      return "البحث عن رحلة";
    case 2:
      return "رحلاتي";
    default:
      return "";
  }
}