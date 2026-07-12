import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// NFR-14: مفتاح تشفير صندوق الجلسة (AES-256) محفوظ في التخزين الآمن
/// للمنصة (Android Keystore / iOS Keychain) — لا يُكتب أبداً في ملفات عادية
/// أو SharedPreferences.
class SecureKeyService {
  SecureKeyService._();

  static const String _keyName = 'hive_auth_encryption_key';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// يقرأ مفتاح التشفير أو ينشئه أول مرة.
  /// `created = true` تعني أن هذا أول تشغيل بالتشفير — أي أن صندوق الجلسة
  /// الموجود على القرص (إن وجد) ما زال غير مشفر ويحتاج ترحيلاً.
  static Future<({List<int> key, bool created})> getOrCreateKey() async {
    final stored = await _storage.read(key: _keyName);
    if (stored != null) {
      return (key: base64Url.decode(stored), created: false);
    }

    final key = Hive.generateSecureKey();
    await _storage.write(key: _keyName, value: base64UrlEncode(key));
    return (key: key, created: true);
  }
}
