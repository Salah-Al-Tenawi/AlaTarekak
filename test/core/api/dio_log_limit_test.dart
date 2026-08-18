import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// حدّ ما يُطبع من جسم الرد في وضع التطوير.
///
/// كل سطر يُطبع يمرّ إلى سجلّ النظام عبر قناة المنصّة، وهي بطيئة على
/// الأجهزة المتوسطة. ورد `GET /rides` بثماني رحلات يقارب 15 ك.ب — نحو
/// **19 سطراً** مقابل سطر واحد لبقية النداءات — فكانت شاشة «رحلاتي»
/// تتجمّد في `debug` وحدها بينما تعمل في `--profile` بلا تقطّع.

/// يلتقط ما يُطبع بدل إرساله إلى السجلّ.
List<String> _capture(void Function() body) {
  final lines = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) lines.add(message);
  };
  try {
    body();
  } finally {
    debugPrint = original;
  }
  return lines;
}

/// يستدعي المُسجّل الداخلي عبر الواجهة التي يمرّرها Dio.
void _log(String text) {
  // ignore: invalid_use_of_visible_for_testing_member
  DioConSumer.logForTesting(text);
}

void main() {
  final defaultLimit = DioConSumer.logBodyLimit;
  tearDown(() => DioConSumer.logBodyLimit = defaultLimit);

  test('الحدّ الافتراضي مضبوط ولا يُترك بلا سقف', () {
    expect(DioConSumer.logBodyLimit, isNotNull);
    expect(DioConSumer.logBodyLimit, lessThanOrEqualTo(4000));
  });

  test('الردّ القصير يُطبع كما هو بلا قصّ', () {
    final lines = _capture(() => _log('{"success":true}'));

    expect(lines.join(), '{"success":true}');
    expect(lines.join(), isNot(contains('قُطع')));
  });

  test('ردّ الرحلات الطويل يُقصّ ويُذكر طوله الكامل', () {
    final huge = '{"data":[${'x' * 15000}]}';

    final lines = _capture(() => _log(huge));
    final printed = lines.join();

    expect(printed.length, lessThan(huge.length ~/ 3),
        reason: 'الطباعة هي الكلفة — لا تُطبع 15 ك.ب لأجل تشخيص شكل');
    expect(printed, contains('قُطع'));
    expect(printed, contains('${huge.length}'),
        reason: 'الطول الكامل يُذكر ليُعرف أن هناك ما لم يُطبع');
  });

  test('بداية الرد تصل كاملة — الشكل يُقرأ منها', () {
    final huge = '{"success":true,"data":[{"id":538,'
        '"driver_id":1001,${'x' * 15000}}]}';

    final printed = _capture(() => _log(huge)).join();

    expect(printed, contains('"success":true'));
    expect(printed, contains('"id":538'));
    expect(printed, contains('"driver_id":1001'),
        reason: 'أول الحقول تكفي لتشخيص اختلاف شكل الرد عن النموذج');
  });

  test('رفع الحدّ إلى null يُعيد الطباعة كاملة', () {
    DioConSumer.logBodyLimit = null;
    final huge = 'y' * 5000;

    final printed = _capture(() => _log(huge)).join();

    expect(printed.length, huge.length);
    expect(printed, isNot(contains('قُطع')));
  });

  test('السطر يُقسَّم فلا يقصّه سجلّ أندرويد', () {
    // سجلّ أندرويد يبتر السطر عند نحو ألف محرف
    final lines = _capture(() => _log('z' * 2500));

    expect(lines.length, greaterThan(1));
    for (final line in lines) {
      expect(line.length, lessThanOrEqualTo(800));
    }
  });
}
