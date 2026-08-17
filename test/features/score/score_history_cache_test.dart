import 'dart:io';

import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/score/data/data_source/score_local_data_source.dart';
import 'package:alatarekak/features/score/data/model/score_model.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// كاش سجلّ النقاط.
///
/// النقاط كانت مخزَّنة والسجل لا: يُفتح الرأس فوراً بالرقم القديم بينما
/// يبقى ما تحته فارغاً حتى يردّ الخادم — أو أبداً إن تعذّرت الشبكة.

ScoreHistoryModel _entry({
  int id = 42,
  String code = 'ride_completed',
  int value = 10,
}) =>
    ScoreHistoryModel.fromJson({
      'id': id,
      'event': {'code': code},
      'points': {'value': value, 'display': value >= 0 ? '+$value' : '$value'},
      'score': {'before': 80, 'after': 80 + value, 'delta': value},
      'reason': 'Ride completed',
      'high_cancel_rate_applied': false,
      'occurred_at': '2026-08-17T09:35:00+00:00',
    });

void main() {
  late Directory tempDir;
  late ScoreLocalDataSourceIm local;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('score_cache_test');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.cacheBoxName);
    local = ScoreLocalDataSourceIm();
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('حفظ الصفحة الأولى واسترجاعها', () {
    test('بلا كاش يعود null لا قائمة فارغة', () {
      expect(local.getHistoryFirstPage(), isNull);
    });

    test('الحركة تعود بكل حقولها بعد دورة حفظ/قراءة', () async {
      await local.saveHistoryFirstPage(ScoreHistoryPage(
        items: [_entry()],
        total: 84,
        currentPage: 1,
        lastPage: 5,
      ));

      final restored = local.getHistoryFirstPage()!;
      final item = restored.items.single;

      expect(item.id, 42);
      expect(item.action, 'ride_completed');
      expect(item.pointsDelta, 10);
      expect(item.previousScore, 80);
      expect(item.newScore, 90);
      expect(item.createdAt?.toUtc(), DateTime.utc(2026, 8, 17, 9, 35));
      expect(item.deltaLabel, 'تمت إضافة 10 نقاط',
          reason: 'العرض العربي يصحّ من الكاش كما من الشبكة');
    });

    test('الخصم وجزاء معدّل الإلغاء ينجوان من الدورة', () async {
      final raw = ScoreHistoryModel.fromJson({
        'id': 7,
        'event': {'code': 'driver_cancel_ride_late'},
        'points': {'value': -15, 'display': '-15'},
        'score': {'before': 90, 'after': 75, 'delta': -15},
        'high_cancel_rate_applied': true,
        'occurred_at': '2026-08-16T10:00:00+00:00',
      });
      await local.saveHistoryFirstPage(ScoreHistoryPage(items: [raw]));

      final item = local.getHistoryFirstPage()!.items.single;
      expect(item.pointsDelta, -15);
      expect(item.highCancelRateApplied, isTrue);
      expect(item.actionLabel, 'إلغاء السائق للرحلة متأخراً');
    });

    test('الترتيب محفوظ', () async {
      await local.saveHistoryFirstPage(ScoreHistoryPage(items: [
        _entry(id: 1),
        _entry(id: 2),
        _entry(id: 3),
      ]));

      expect(local.getHistoryFirstPage()!.items.map((e) => e.id).toList(),
          [1, 2, 3]);
    });
  });

  group('حدود الكاش', () {
    test('لا يدّعي معرفة ما بقي عند الخادم', () async {
      await local.saveHistoryFirstPage(ScoreHistoryPage(
        items: [_entry()],
        total: 84,
        lastPage: 5,
      ));

      final restored = local.getHistoryFirstPage()!;
      expect(restored.hasMore, isFalse,
          reason: 'الترقيم يصحّحه التحديث الشبكي — الكاش لا يخمّنه');
      expect(restored.total, 1, reason: 'إجمالي ما خُزِّن لا ما عند الخادم');
    });

    test('سجل فارغ لا يُخزَّن كصفحة', () async {
      await local.saveHistoryFirstPage(const ScoreHistoryPage(items: []));
      expect(local.getHistoryFirstPage(), isNull);
    });

    test('كاش تالف يُتجاهل ولا يرمي', () async {
      await HiveBoxes.cacheBox.put(HiveKeys.scoreHistory, 'ليس JSON');
      expect(local.getHistoryFirstPage(), isNull);
    });

    test('المسح يُزيل النقاط والسجل معاً', () async {
      await local.saveScore(ScoreModel.fromJson(const {'score': 85}));
      await local.saveHistoryFirstPage(ScoreHistoryPage(items: [_entry()]));

      await local.clear();

      expect(local.getScore(), isNull);
      expect(local.getHistoryFirstPage(), isNull,
          reason: 'وإلا بقي سجل مستخدم سابق ظاهراً بعد الخروج');
    });
  });
}
