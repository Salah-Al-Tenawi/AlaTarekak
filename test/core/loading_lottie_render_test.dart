import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

/// مؤشّر التحميل — يُصيَّر فعلاً لا يُقرأ فحسب.
///
/// **Lottie يفشل صامتاً**: ملفّ فيه بنية لا يدعمها المشغّل يُحمَّل بلا خطأ
/// ثم يرسم فراغاً، أو يرسم بعض طبقاته ويُسقط البقية. فلا يكفي أن يكون
/// JSON صالحاً ولا أن يُفكّك بلا استثناء — لا بدّ من قراءة البكسل.
///
/// الاختبار يبني الرسم ثم يقيس **تغطية البكسل غير الشفّاف** عبر إطارات
/// من الدورة: لو سقطت طبقة أو تعطّل مقصّ المسار انهارت التغطية.
void main() {
  /// نسبة البكسل غير الشفّاف في اللقطة.
  Future<double> coverage(WidgetTester tester) async {
    final bytes = await _pixels(tester);

    var painted = 0;
    for (var i = 3; i < bytes.length; i += 4) {
      if (bytes[i] > 16) painted++;
    }
    return painted / (bytes.length / 4);
  }

  Future<void> pumpLoader(WidgetTester tester, LottieComposition comp) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: _boundary,
          child: Container(
            width: 200,
            height: 200,
            color: const Color(0xFF101820),
            child: Lottie(composition: comp, animate: false, frameRate: null),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  late LottieComposition composition;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final bytes = await File('assets/lottie/loading_route.json').readAsBytes();
    composition = await LottieComposition.fromBytes(bytes);
  });

  group('الملفّ يُفكَّك كما وُصف', () {
    test('مربّع — فيُعرض بـ BoxFit.contain بلا تشويه', () {
      expect(composition.bounds.width, composition.bounds.height);
    });

    test('دورته في حدود ثانيتين — مؤشّر لا مقدّمة فيلم', () {
      final ms = composition.duration.inMilliseconds;
      expect(ms, greaterThan(900));
      expect(ms, lessThan(2200));
    });

    test('مداه الزمني كامل — لا إطار ضائع', () {
      expect(composition.startFrame, 0);
      expect(composition.endFrame, greaterThan(60));
    });

    test('معدّل الإطارات ستّون — حركة ناعمة لا متقطّعة', () {
      expect(composition.frameRate, 60);
    });
  });

  group('يرسم فعلاً — قراءة البكسل', () {
    testWidgets('الإطار الأول ليس فارغاً', (tester) async {
      await pumpLoader(tester, composition);

      final painted = await coverage(tester);
      expect(painted, greaterThan(0.99),
          reason: 'الخلفية تملأ اللوحة — لو قلّت فالرسم لم يقع أصلاً');
    });

    testWidgets('اللون البرتقالي حاضر — الطبقات الملوّنة رُسمت',
        (tester) async {
      await pumpLoader(tester, composition);

      final bytes = await _pixels(tester);

      var orange = 0;
      for (var i = 0; i < bytes.length; i += 4) {
        final r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
        // #ED8B10 وما قاربه بعد المزج بالخلفية
        if (r > 150 && g > 70 && g < 190 && b < 110) orange++;
      }
      expect(orange, greaterThan(200),
          reason: 'القوس والمسافر وخطّ المنتصف كلّها برتقالية — '
              'غيابها يعني أن الطبقات لم تُرسم');
    });
  });
}

final _boundary = GlobalKey();

/// بكسل اللوحة خاماً.
///
/// **`runAsync` ضرورية**: `toImage` تمرّ على محرّك الرسم بزمن حقيقي، و
/// `testWidgets` يُجمّد الزمن — فتُنتظر إلى الأبد ويعلّق الاختبار.
Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary =
      _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;

  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}
