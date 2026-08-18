import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/core/utils/class/syria_geo.dart';

/// سبب تعذّر تحديد الموقع — كلٌّ يستدعي تصرّفاً مختلفاً من المستخدم.
enum LocationFailure {
  /// خدمة الموقع مطفأة في الجهاز كلّه.
  serviceDisabled,

  /// رفض الإذن هذه المرّة — يمكن أن يُسأل مجدداً.
  denied,

  /// رفضه رفضاً دائماً — لا يُسأل بعدها، والحلّ من إعدادات النظام.
  deniedForever,

  /// الموقع خارج سوريا — التطبيق يخدم داخلها.
  outsideSyria,

  /// تعذّر الحصول على إحداثيات (لا إشارة، أو مهلة).
  unavailable,
}

/// نتيجة طلب الموقع: نقطة، أو سبب واضح للتعذّر.
sealed class LocationResult {
  const LocationResult();
}

final class LocationSuccess extends LocationResult {
  final LatLng point;
  const LocationSuccess(this.point);
}

final class LocationDenied extends LocationResult {
  final LocationFailure reason;
  const LocationDenied(this.reason);

  /// رسالة عربية جاهزة للعرض.
  String get message => switch (reason) {
        LocationFailure.serviceDisabled =>
          'خدمة الموقع مغلقة في جهازك — شغّلها ثم أعد المحاولة',
        LocationFailure.denied =>
          'لم يُسمح للتطبيق بالوصول إلى موقعك',
        LocationFailure.deniedForever =>
          'الإذن مرفوض دائماً — فعّله من إعدادات التطبيق لتحديد موقعك',
        LocationFailure.outsideSyria =>
          'موقعك الحالي خارج سوريا — حدّد النقطة على الخريطة',
        LocationFailure.unavailable =>
          'تعذّر تحديد موقعك الآن — تأكّد من الإشارة وأعد المحاولة',
      };

  /// هل يُفتح للمستخدم بابٌ يصلح به الحال بنفسه؟
  bool get canOpenSettings => reason == LocationFailure.deniedForever;
}

/// تحديد موقع المستخدم الحالي.
///
/// **الإذن يُطلب عند الحاجة لا عند الإقلاع**: من يفتح التطبيق أول مرة
/// فيُسأل عن موقعه بلا سبب ظاهر يرفض غالباً — والرفض الدائم لا يُسأل
/// بعده. فيُطلب حين يضغط «موقعي» وقد فهم لماذا.
///
/// وكل تعذّر يُميَّز بسببه: المطفأة تُشغَّل، والمرفوضة دائماً تُفتح من
/// الإعدادات، والخارجة عن سوريا تُصحَّح على الخريطة. رسالة واحدة عامة
/// لثلاث حالات تترك المستخدم لا يدري ما يفعل.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// للاختبار: بديل يُغني عن جهاز حقيقي.
  static Future<LocationResult> Function()? debugOverride;

  Future<LocationResult> currentPoint() async {
    final override = debugOverride;
    if (override != null) return override();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationDenied(LocationFailure.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationDenied(LocationFailure.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationDenied(LocationFailure.denied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // مهلة صريحة: بلا إشارة كافية يبقى الطلب معلّقاً بلا نهاية
          // ويظنّ المستخدم أن التطبيق عَلِق
          timeLimit: Duration(seconds: 15),
        ),
      );

      final point = LatLng(position.latitude, position.longitude);
      if (!SyriaGeo.contains(point)) {
        return const LocationDenied(LocationFailure.outsideSyria);
      }

      return LocationSuccess(point);
    } catch (_) {
      return const LocationDenied(LocationFailure.unavailable);
    }
  }

  /// يفتح إعدادات التطبيق ليعيد المستخدم تفعيل الإذن المرفوض دائماً.
  Future<void> openSettings() => Geolocator.openAppSettings();
}
