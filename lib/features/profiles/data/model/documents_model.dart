import 'package:alatarekak/core/api/api_end_points.dart';

/// روابط صور مستندات التوثيق كما يعيدها الباك إند.
///
/// انتبه: السيرفر يسمّي الحقل نفسه بثلاث تسميات مختلفة حسب المسار —
///   • رفع المستندات  (§6.7 POST /profile/verify/driver) → `driving_license_pic`
///   • الملف الشخصي   (§6.1 GET  /profile)               → `license_pic`
///   • حالة التوثيق   (§6.8 GET  /profile/verify/status) → `license`
/// كنا نقرأ اسم حقل الرفع فقط، فكانت رخصة القيادة تظهر «غير مرفوع»
/// رغم رفعها. لذلك نقبل هنا كل التسميات المعروفة لكل حقل.
class DocumentsModel {
  final String? faceIdPic;
  final String? backIdPic;
  final String? licensePic;
  final String? mechanicCardPic;

  DocumentsModel({
    this.faceIdPic,
    this.backIdPic,
    this.licensePic,
    this.mechanicCardPic,
  });

  /// أول قيمة نصية غير فارغة بين التسميات المحتملة
  static String? _pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  factory DocumentsModel.fromJson(Map<String, dynamic> json) {
    return DocumentsModel(
      faceIdPic: _pick(json, const [ApiKey.faceIdPic, 'face_id']),
      backIdPic: _pick(json, const [ApiKey.backIdPic, 'back_id']),
      licensePic: _pick(
          json, const ['license_pic', ApiKey.licensePic, 'license']),
      mechanicCardPic:
          _pick(json, const [ApiKey.mechanicCardPic, 'mechanic_card']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.faceIdPic: faceIdPic,
      ApiKey.backIdPic: backIdPic,
      ApiKey.licensePic: licensePic,
      ApiKey.mechanicCardPic: mechanicCardPic,
    };
  }
}
