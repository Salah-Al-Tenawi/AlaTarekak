import 'dart:io';

import 'package:alatarekak/core/service/safe_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// `emit` بعد إغلاق الشاشة.
///
/// نمط كل كيوبت في التطبيق واحد: ينتظر الشبكة ثم يُصدر حالة. فإن غادر
/// المستخدم الشاشة قبل وصول الردّ، يُستدعى `emit` على كيوبت مُغلَق فيرمي
/// bloc من مسار غير متزامن لا يلتقطه أحد — ويُسقط الإطار لا الشاشة وحدها.
///
/// وقع فعلاً في «تفاصيل الرحلة»: خروج سريع من نتائج البحث قبل وصول الرد.

class _Counter extends SafeCubit<int> {
  _Counter() : super(0);

  void bump() => emit(state + 1);

  /// يحاكي دالة تنتظر الشبكة ثم تُصدر — والمستخدم يغادر أثناء الانتظار.
  Future<void> loadSlowly() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    emit(99);
  }
}

void main() {
  group('الكيوبت المفتوح يعمل كالمعتاد', () {
    test('الإصدار يمرّ ويغيّر الحالة', () {
      final c = _Counter();
      addTearDown(c.close);

      c.bump();
      c.bump();

      expect(c.state, 2);
    });

    test('تدفّق الحالات يصل للمستمعين', () async {
      final c = _Counter();
      final seen = <int>[];
      c.stream.listen(seen.add);

      c.bump();
      c.bump();
      await Future<void>.delayed(Duration.zero);
      await c.close();

      expect(seen, [1, 2]);
    });
  });

  group('بعد الإغلاق', () {
    test('الإصدار يُبتلع ولا يرمي', () async {
      final c = _Counter();
      await c.close();

      expect(() => c.bump(), returnsNormally);
    });

    test('الحالة تبقى على آخر قيمة قبل الإغلاق', () async {
      final c = _Counter();
      c.bump();
      await c.close();

      c.bump();

      expect(c.state, 1, reason: 'لا شيء ينتظر حالة بعد الإغلاق');
    });

    test('الخروج أثناء انتظار الشبكة لا يرمي — وهو العيب الأصلي',
        () async {
      final c = _Counter();
      final pending = c.loadSlowly();

      await c.close(); // غادر المستخدم الشاشة
      await expectLater(pending, completes);
    });

    test('البقاء حتى وصول الرد يُصدر الحالة', () async {
      final c = _Counter();
      addTearDown(c.close);

      await c.loadSlowly();

      expect(c.state, 99);
    });
  });

  group('التطبيق كله يرث الحارس', () {
    test('لا كيوبت يرث Cubit مباشرةً', () async {
      final offenders = <String>[];

      await for (final entity
          in Directory('lib').list(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // القاعدة نفسها هي الوحيدة المسموح لها بذلك
        if (entity.path.endsWith('safe_cubit.dart')) continue;
        final source = await entity.readAsString();
        if (source.contains('extends Cubit<')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'كيوبت يرث Cubit مباشرةً يرث معه العيب: emit بعد الإغلاق '
            'يرمي. اجعله يرث SafeCubit.',
      );
    });
  });
}
