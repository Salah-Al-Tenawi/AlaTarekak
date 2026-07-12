import 'dart:io';

import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// اختبارات NFR-14: صندوق الجلسة مشفر على القرص، مع ترحيل
/// جلسات الإصدارات القديمة غير المشفرة دون فقدانها.
void main() {
  const secretToken = 'super-secret-access-token-12345';
  const testUser = UserModel(
    id: 1,
    firstName: 'يزن',
    lastName: 'صلاح',
    email: 'test@example.com',
    accessToken: secretToken,
    refreshToken: 'refresh-token',
  );

  late Directory tempDir;
  late HiveAesCipher cipher;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_secure_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    cipher = HiveAesCipher(Hive.generateSecureKey());
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // ويندوز قد يبقي قفلاً قصيراً على الملف — لا يؤثر على الاختبار
    }
  });

  test('تثبيت جديد: يفتح صندوقاً مشفراً ولا يكتب التوكن نصاً صريحاً',
      () async {
    final box = await HiveService.openAuthBoxEncrypted(cipher,
        migrateFromPlain: true);

    await box.put(HiveKeys.user, testUser);
    await box.flush();

    final raw = String.fromCharCodes(await File(box.path!).readAsBytes());
    expect(raw.contains(secretToken), isFalse,
        reason: 'التوكن يجب ألا يظهر نصاً صريحاً في ملف الصندوق');
    expect(box.get(HiveKeys.user)!.accessToken, secretToken);
  });

  test('الترحيل: جلسة الصندوق القديم غير المشفر تُنقل ويُعاد تشفير الملف',
      () async {
    // صندوق قديم غير مشفر فيه جلسة مستخدم (وضع ما قبل التحديث)
    final plain = await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
    await plain.put(HiveKeys.user, testUser);
    await plain.flush();
    final rawBefore =
        String.fromCharCodes(await File(plain.path!).readAsBytes());
    expect(rawBefore.contains(secretToken), isTrue,
        reason: 'قبل الترحيل التوكن مكشوف على القرص');
    await plain.close();

    // أول تشغيل بعد تفعيل التشفير
    final box = await HiveService.openAuthBoxEncrypted(cipher,
        migrateFromPlain: true);

    // الجلسة لم تُفقد
    expect(box.get(HiveKeys.user)!.accessToken, secretToken);
    expect(box.get(HiveKeys.user)!.email, 'test@example.com');

    // والملف الجديد مشفر
    await box.flush();
    final rawAfter =
        String.fromCharCodes(await File(box.path!).readAsBytes());
    expect(rawAfter.contains(secretToken), isFalse);
  });

  test('إعادة الفتح بنفس المفتاح تعيد الجلسة (التشغيلات اللاحقة)', () async {
    final first = await HiveService.openAuthBoxEncrypted(cipher,
        migrateFromPlain: true);
    await first.put(HiveKeys.user, testUser);
    await first.close();

    final second = await HiveService.openAuthBoxEncrypted(cipher,
        migrateFromPlain: false);
    expect(second.get(HiveKeys.user)!.accessToken, secretToken);
  });
}
