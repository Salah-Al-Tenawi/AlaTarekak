import 'package:alatarekak/features/profiles/data/model/documents_model.dart';
import 'package:alatarekak/features/profiles/data/model/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// الخادم يسمّي حقول المستندات بثلاث تسميات مختلفة حسب المسار. كنا نقرأ
/// تسمية الرفع وحدها، فكانت رخصة القيادة تظهر «غير مرفوع» رغم رفعها —
/// هذه الاختبارات تحرس قبول التسميات الثلاث جميعاً.

/// §6.1 — GET /profile → `license_pic`
const _profileShape = {
  'face_id_pic': 'https://host/storage/face.jpg',
  'back_id_pic': 'https://host/storage/back.jpg',
  'license_pic': 'https://host/storage/license.jpg',
  'mechanic_card_pic': 'https://host/storage/mechanic.jpg',
};

/// §6.7 — POST /profile/verify/driver → `driving_license_pic`
const _uploadShape = {
  'face_id_pic': 'https://host/storage/face.jpg',
  'back_id_pic': 'https://host/storage/back.jpg',
  'driving_license_pic': 'https://host/storage/license.jpg',
  'mechanic_card_pic': 'https://host/storage/mechanic.jpg',
};

/// §6.8 — GET /profile/verify/status → بلا لاحقة `_pic`
const _statusShape = {
  'face_id': 'https://host/storage/face.jpg',
  'back_id': 'https://host/storage/back.jpg',
  'license': 'https://host/storage/license.jpg',
  'mechanic_card': 'https://host/storage/mechanic.jpg',
};

void _expectAllFour(DocumentsModel docs) {
  expect(docs.faceIdPic, 'https://host/storage/face.jpg');
  expect(docs.backIdPic, 'https://host/storage/back.jpg');
  expect(docs.licensePic, 'https://host/storage/license.jpg');
  expect(docs.mechanicCardPic, 'https://host/storage/mechanic.jpg');
}

void main() {
  group('DocumentsModel — التسميات الثلاث للحقل نفسه', () {
    test('شكل الملف الشخصي (license_pic) يُقرأ كاملاً', () {
      _expectAllFour(DocumentsModel.fromJson(_profileShape));
    });

    test('شكل الرفع (driving_license_pic) يُقرأ كاملاً', () {
      _expectAllFour(DocumentsModel.fromJson(_uploadShape));
    });

    test('شكل حالة التوثيق (بلا لاحقة _pic) يُقرأ كاملاً', () {
      _expectAllFour(DocumentsModel.fromJson(_statusShape));
    });

    test('الأشكال الثلاثة تعطي النتيجة نفسها', () {
      final fromProfile = DocumentsModel.fromJson(_profileShape);
      final fromUpload = DocumentsModel.fromJson(_uploadShape);
      final fromStatus = DocumentsModel.fromJson(_statusShape);

      expect(fromUpload.licensePic, fromProfile.licensePic);
      expect(fromStatus.licensePic, fromProfile.licensePic);
    });
  });

  group('DocumentsModel — القيم الغائبة والفارغة', () {
    test('الحقل الغائب يبقى null', () {
      final docs = DocumentsModel.fromJson(const {
        'face_id_pic': 'https://host/storage/face.jpg',
        'back_id_pic': 'https://host/storage/back.jpg',
      });

      expect(docs.faceIdPic, isNotNull);
      expect(docs.licensePic, isNull);
      expect(docs.mechanicCardPic, isNull);
    });

    test('النص الفارغ لا يُحسب مرفوعاً', () {
      final docs = DocumentsModel.fromJson(const {
        'license_pic': '',
        'mechanic_card_pic': '   ',
      });

      expect(docs.licensePic, isNull);
      expect(docs.mechanicCardPic, isNull);
    });

    test('null صريح لا يطغى على تسمية لاحقة تحمل القيمة', () {
      final docs = DocumentsModel.fromJson(const {
        'license_pic': null,
        'driving_license_pic': 'https://host/storage/license.jpg',
      });

      expect(docs.licensePic, 'https://host/storage/license.jpg');
    });

    test('كائن مستندات فارغ لا يرمي استثناءً', () {
      final docs = DocumentsModel.fromJson(const {});
      expect(docs.faceIdPic, isNull);
      expect(docs.licensePic, isNull);
    });
  });

  group('DocumentsModel — رحلة الكاش المحلي', () {
    test('toJson ثم fromJson يحفظ الروابط الأربعة', () {
      final restored =
          DocumentsModel.fromJson(DocumentsModel.fromJson(_profileShape).toJson());
      _expectAllFour(restored);
    });
  });

  group('ProfileModel — المستندات تصل من رد /profile كاملاً', () {
    test('رخصة القيادة تصل مع بقية المستندات (الخطأ المُصلَح)', () {
      final profile = ProfileModel.fromJson({
        'success': true,
        'data': {
          'user_id': 12,
          'full_name': 'أحمد السيد',
          'verification_status': 'approved',
          'documents': _profileShape,
        },
      });

      final docs = profile.documents;
      expect(docs, isNotNull);
      _expectAllFour(docs!);
    });

    test('السائق يُميَّز عن الراكب برخصته (اشتقاق profile_body)', () {
      final driver = DocumentsModel.fromJson(_profileShape);
      final passenger = DocumentsModel.fromJson(const {
        'face_id_pic': 'https://host/storage/face.jpg',
        'back_id_pic': 'https://host/storage/back.jpg',
      });

      isDriver(DocumentsModel d) =>
          d.licensePic != null || d.mechanicCardPic != null;

      expect(isDriver(driver), isTrue);
      expect(isDriver(passenger), isFalse);
    });
  });
}
