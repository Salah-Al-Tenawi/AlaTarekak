import 'package:alatarekak/core/utils/widgets/rate_user_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// ورقة التقييم المشتركة — الراكب يقيّم سائقه، والسائق يقيّم راكبه.
///
/// كان التقييم حواراً مبنيّاً يدوياً بمقاسات ثابتة لا تتبع الشاشة، ونجومه
/// بلا تسمية تقول ماذا تعني الثلاث من الخمس، وبلا موضع لتعليق — ومسار
/// التعليق موجود في الخادم ولا يناديه أحد.
void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    Size size = const Size(375, 812),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: RateUserSheet(
                name: 'أحمد',
                question: 'كيف كانت رحلتك مع أحمد؟',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// يضغط النجمة رقم [index] (من الصفر).
  Future<void> tapStar(WidgetTester tester, int index) async {
    await tester.tap(find.byIcon(Icons.star_rounded).at(index));
    await tester.pumpAndSettle();
  }

  /// يفتح الورقة كما تُفتح في التطبيق، يملؤها، ثم يُعيد ما خرجت به.
  Future<RateUserResult?> openAndSubmit(
    WidgetTester tester, {
    required int star,
    String? comment,
    bool skip = false,
  }) async {
    RateUserResult? result;

    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await RateUserSheet.show(
                      context,
                      name: 'أحمد',
                      question: 'كيف كانت رحلتك مع أحمد؟',
                    );
                  },
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    await tapStar(tester, star);
    if (comment != null) {
      await tester.enterText(find.byType(TextField), comment);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(skip ? 'لاحقاً' : 'إرسال التقييم'));
    await tester.pumpAndSettle();

    return result;
  }

  group('المحتوى', () {
    testWidgets('السؤال يسمّي من يُقيَّم — فلا يُقيَّم أحد بالخطأ',
        (tester) async {
      await pumpSheet(tester);

      expect(find.text('كيف كانت رحلتك مع أحمد؟'), findsOneWidget);
    });

    testWidgets('خمس نجوم وحقل تعليق موسوم اختيارياً', (tester) async {
      await pumpSheet(tester);

      expect(find.byType(RatingBar), findsOneWidget);
      expect(find.text('أضف تعليقاً (اختياري)'), findsOneWidget);
    });

    testWidgets('لا عدّاد أحرف فوق حقل فارغ', (tester) async {
      await pumpSheet(tester);

      expect(find.textContaining('/500'), findsNothing);
    });
  });

  group('التسمية تقول ماذا تعني الدرجة', () {
    testWidgets('نجمة واحدة → «سيّئة»', (tester) async {
      await pumpSheet(tester);
      await tapStar(tester, 0);

      expect(find.text('سيّئة'), findsOneWidget);
    });

    testWidgets('ثلاث → «جيدة»', (tester) async {
      await pumpSheet(tester);
      await tapStar(tester, 2);

      expect(find.text('جيدة'), findsOneWidget);
    });

    testWidgets('خمس → «ممتازة»', (tester) async {
      await pumpSheet(tester);
      await tapStar(tester, 4);

      expect(find.text('ممتازة'), findsOneWidget);
    });

    testWidgets('قبل الاختيار لا تسمية', (tester) async {
      await pumpSheet(tester);

      for (final label in const ['سيّئة', 'مقبولة', 'جيدة', 'ممتازة']) {
        expect(find.text(label), findsNothing);
      }
    });
  });

  group('الإرسال', () {
    testWidgets('معطّل حتى تُختار نجمة — زرٌّ بلا أثر يبدو عطلاً',
        (tester) async {
      await pumpSheet(tester);

      final before = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'إرسال التقييم'));
      expect(before.onPressed, isNull);

      await tapStar(tester, 3);

      final after = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'إرسال التقييم'));
      expect(after.onPressed, isNotNull);
    });

    testWidgets('يُعيد الدرجة، والتعليق null حين يُترك فارغاً',
        (tester) async {
      final result = await openAndSubmit(tester, star: 4);

      expect(result, isNotNull);
      expect(result!.rating, 5);
      expect(result.comment, isNull, reason: 'حقل فارغ لا يُرسَل نصّاً فارغاً');
    });

    testWidgets('التعليق يُقصّ من طرفيه', (tester) async {
      final result =
          await openAndSubmit(tester, star: 3, comment: '  سائق محترم  ');

      expect(result!.rating, 4);
      expect(result.comment, 'سائق محترم');
    });

    testWidgets('تعليق بمسافات وحدها يُعدّ فارغاً', (tester) async {
      final result = await openAndSubmit(tester, star: 0, comment: '   ');

      expect(result!.comment, isNull);
    });

    testWidgets('«لاحقاً» يُغلق بلا نتيجة — التقييم اختياري', (tester) async {
      final result = await openAndSubmit(tester, star: 4, skip: true);

      expect(result, isNull);
    });
  });

  group('الاستجابة للقياس', () {
    for (final size in const [
      Size(320, 568),
      Size(360, 740),
      Size(375, 812),
      Size(430, 932),
    ]) {
      testWidgets('عرض ${size.width.toInt()}: بلا فيض', (tester) async {
        await pumpSheet(tester, size: size);
        await tapStar(tester, 4);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
