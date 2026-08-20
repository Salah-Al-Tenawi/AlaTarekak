import 'package:alatarekak/core/utils/class/ride_time_rules.dart';
import 'package:alatarekak/core/utils/widgets/no_show_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// عدّاد بوابة الإبلاغ عن الغياب.
///
/// عيبان ظهرا حين قُصّرت مهلة الساعة إلى دقيقة للتجريب:
///
/// **الأول — العدّاد يَعِد بالضعف.** كان يُحسب `inMinutes + 1`، و
/// `inMinutes` يقتطع الكسر: دقيقة كاملة تُقرأ `1` ثم يُزاد عليها فتصير
/// «دقيقتين». يظهر العيب مع مهلة الدقيقة صريحاً، ويمرّ مع مهلة الساعة
/// لأن «بعد ٦١ دقيقة» بدل «٦٠» لا يلحظه أحد.
///
/// **الثاني — العدّاد جامد.** كان يُقرأ عند فتح الشاشة ثم يُجمَّد، فمن
/// انتظر أمامها لا يرى البوابة تُفتح حتى يغادر ويعود.
void main() {
  group('نصّ العدّاد — تقريب لأعلى بالثواني', () {
    test('دقيقة كاملة تُقال «دقيقة» لا «دقيقتين»', () {
      expect(noShowCountdownLabel(const Duration(seconds: 60)),
          'بعد دقيقة');
    });

    test('دقيقتان كاملتان تُقالان «دقيقتين» لا «3 دقائق»', () {
      expect(noShowCountdownLabel(const Duration(seconds: 120)),
          'بعد دقيقتين');
    });

    test('ثانية واحدة تبقى «دقيقة» — لا «بعد 0»', () {
      expect(noShowCountdownLabel(const Duration(seconds: 1)), 'بعد دقيقة');
    });

    test('الكسر يُقرَّب لأعلى فلا يَعِد العدّاد بما لا يقع', () {
      // 61 ثانية: لا تكفي دقيقة واحدة
      expect(noShowCountdownLabel(const Duration(seconds: 61)),
          'بعد دقيقتين');
      expect(noShowCountdownLabel(const Duration(seconds: 119)),
          'بعد دقيقتين');
    });

    test('ساعة كاملة: ستّون دقيقة لا إحدى وستّون', () {
      expect(noShowCountdownLabel(const Duration(minutes: 60)),
          'بعد 60 دقيقة');
    });

    test('وصيغ العربية محفوظة', () {
      expect(noShowCountdownLabel(const Duration(minutes: 5)),
          'بعد 5 دقائق');
      expect(noShowCountdownLabel(const Duration(minutes: 15)),
          'بعد 15 دقيقة');
    });
  });

  group('البوابة تُفتح والمستخدم ينظر', () {
    /// ساعة يقودها الاختبار: ساعة الاختبار الوهمية تُقدّم المؤقّتات
    /// ولا تُقدّم `DateTime.now()`، فتُقدَّم هذه معها يدوياً.
    late DateTime now;

    Future<void> pumpGate(WidgetTester tester, DateTime departure) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: NoShowGate(
              departure: departure,
              clock: () => now,
              builder: (context, remaining) => Text(
                remaining == null ? 'لم يحضر' : noShowCountdownLabel(remaining),
              ),
            ),
          ),
        ),
      );
    }

    /// يُمرّر الزمن على الساعتين معاً.
    Future<void> advance(WidgetTester tester, Duration by) async {
      now = now.add(by);
      await tester.pump(by);
    }

    setUp(() => now = DateTime(2026, 8, 20, 12));

    testWidgets('قبل انقضاء المهلة: عدّاد لا زرّ', (tester) async {
      // المهلة ساعة، ومضى منها نصفها
      final departure = now.subtract(RideTimeRules.noShowDelay ~/ 2);
      await pumpGate(tester, departure);

      expect(find.textContaining('بعد '), findsOneWidget);
      expect(find.text('لم يحضر'), findsNothing);

      // إيقاف المؤقّت قبل انتهاء الاختبار
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('**تُفتح دون مغادرة الشاشة** — العيب المُصلَح',
        (tester) async {
      // ثانيتان تفصلاننا عن فتح البوابة
      final departure =
          now.subtract(RideTimeRules.noShowDelay - const Duration(seconds: 2));
      await pumpGate(tester, departure);

      expect(find.text('لم يحضر'), findsNothing,
          reason: 'لم تُفتح بعد');

      // ننتظر أمام الشاشة نفسها بلا مغادرة
      await advance(tester, const Duration(seconds: 3));

      expect(find.text('لم يحضر'), findsOneWidget,
          reason: 'كان الزرّ يبقى معطّلاً حتى يغادر المستخدم ويعود');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('مفتوحة أصلاً: الزرّ فوراً وبلا مؤقّت', (tester) async {
      final departure = now.subtract(RideTimeRules.noShowDelay * 2);
      await pumpGate(tester, departure);

      expect(find.text('لم يحضر'), findsOneWidget);
      // لا مؤقّت معلّق يمنع انتهاء الاختبار
    });

    testWidgets('العدّاد يتناقص مع الوقت', (tester) async {
      final departure =
          now.subtract(RideTimeRules.noShowDelay - const Duration(minutes: 3));
      await pumpGate(tester, departure);

      expect(find.text('بعد 3 دقائق'), findsOneWidget);

      await advance(tester, const Duration(minutes: 1));
      expect(find.text('بعد دقيقتين'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
