import 'dart:io';

import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/policy/data/data_source/policy_local_data_source.dart';
import 'package:alatarekak/features/policy/data/model/policy_content_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'policies_fixture.dart';

/// تخزين السياسات محلياً.
///
/// وثيقة يقرأها من لا حساب له بعد (شاشة إنشاء الحساب)، فهي ليست بيانات
/// مستخدم: مسحها مع كاشه عند الخروج يجعل أول شاشة بعده تعرض النصّ
/// المدمج القديم حتى يردّ الخادم — أو أبداً بلا شبكة.

void main() {
  late Directory tempDir;
  late PolicyLocalDataSourceIm local;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('policy_cache_test');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.cacheBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // قفل ملفات مؤقت على ويندوز — غير مؤثر
    }
  });

  setUp(() async {
    await HiveBoxes.cacheBox.clear();
    local = PolicyLocalDataSourceIm();
  });

  test('بلا نسخة مخزَّنة يعود بـ null', () {
    expect(local.get(), isNull);
  });

  test('المحفوظ يُقرأ كما حُفظ', () async {
    final content = PolicyContentModel.fromJson(
        Map<String, dynamic>.from(policiesResponseFixture['data'] as Map));

    await local.save(content);
    final restored = local.get();

    expect(restored, isNotNull);
    expect(restored!.privacy.sections.length, content.privacy.sections.length);
    expect(restored.faq.first.entries.first.question,
        content.faq.first.entries.first.question);
    expect(restored.settings.consentLabel, content.settings.consentLabel);
  });

  test('نسخة تالفة تُتجاهل ولا ترمي', () async {
    await HiveBoxes.cacheBox.put(HiveKeys.policies, 'ليس JSON');
    expect(local.get(), isNull);
  });

  group('الخروج من الحساب', () {
    test('يمسح كاش المستخدم ويُبقي السياسات', () async {
      final content = PolicyContentModel.fromJson(
          Map<String, dynamic>.from(policiesResponseFixture['data'] as Map));
      await local.save(content);
      await HiveBoxes.cacheBox.put(HiveKeys.score, '{"score":80}');
      await HiveBoxes.cacheBox.put(HiveKeys.notifications, '[]');

      await HiveBoxes.clearUserCache();

      expect(HiveBoxes.cacheBox.get(HiveKeys.score), isNull);
      expect(HiveBoxes.cacheBox.get(HiveKeys.notifications), isNull);
      expect(
        local.get(),
        isNotNull,
        reason: 'شاشة إنشاء الحساب تعرضها لمن لا حساب له',
      );
    });
  });
}
