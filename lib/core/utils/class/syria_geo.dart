import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// حدود سوريا الجغرافية — التطبيق يخدم سوريا وحدها.
///
/// **مستطيل لا مضلّع، وعن قصد.** حدود سوريا الحقيقية خطّ متعرّج، ورسمه
/// بمضلّع مكتوب يدوياً يخطئ حتماً عند الأطراف — فيُرفض راكب في القامشلي
/// أو أبو كمال أو قنيطرة وهم داخل البلد. المستطيل **كريم**: لا يرفض
/// نقطة سورية أبداً، ويكتفي بمنع ما هو بعيد بيّن (البحر، داخل تركيا،
/// العراق، الأردن، السعودية).
///
/// وما يفلت منه شريطٌ حدودي لبناني ضيّق. يسدّه أمران قائمان:
///   • البحث مقيَّد بـ`countrycodes: 'sy'` في Nominatim، فنتائجه سورية
///     بحكم المصدر.
///   • الخادم يحسم عند إنشاء الرحلة.
///
/// ولو أردنا الدقّة التامّة فالطريق معروف: ملفّ GeoJSON لحدود سوريا
/// يُضاف أصلاً ويُختبر ضدّه نقطة-في-مضلّع — لا تخمين إحداثيات من الذاكرة.
class SyriaGeo {
  SyriaGeo._();

  static const double minLat = 32.30;
  static const double maxLat = 37.35;
  static const double minLng = 35.55;
  static const double maxLng = 42.40;

  /// وسط البلد تقريباً — مركز افتراضي للخرائط.
  static const LatLng center = LatLng(34.80, 38.90);

  static bool contains(LatLng point) =>
      point.latitude >= minLat &&
      point.latitude <= maxLat &&
      point.longitude >= minLng &&
      point.longitude <= maxLng;

  /// لتقييد كاميرا الخريطة فلا يصل المستخدم إلى الخارج أصلاً.
  static final LatLngBounds bounds = LatLngBounds(
    const LatLng(minLat, minLng),
    const LatLng(maxLat, maxLng),
  );

  static const String outsideMessage =
      'اختر نقطة داخل سوريا — الرحلات محصورة داخل البلد';
}

/// خيارات التفاعل الموحّدة لكل خرائط التطبيق.
///
/// **بلا دوران:** إصبعان للتقريب يدوران الخريطة معه بأدنى فرق زاوية،
/// فيجد المستخدم الشمال مائلاً ولا يعرف كيف يعيده. كانت معطّلة في
/// خريطتين من أربع فاختلف السلوك بين شاشة وأخرى.
const InteractionOptions kMapInteraction = InteractionOptions(
  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
);
