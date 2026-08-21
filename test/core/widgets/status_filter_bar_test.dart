import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/class/adaptive_design.dart';
import 'package:alatarekak/core/utils/widgets/status_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// شريط رقاقات التصنيف — «رحلاتي» و«حجوزاتي».
///
/// **كان يتجمّع في يسار الشاشة على التابلت.** الشريط `SingleChildScrollView`
/// أفقيّ، وصفُّه يأخذ عرضه الطبيعي وحده — فحين تضيق الرقاقات عن عرض
/// الشاشة يضعها العارض عند حافته اليسرى مهما كان الاتجاه، وتُترك يمينُ
/// الشاشة فارغةً وهي أوّل ما تقع عليه العين في واجهة عربية.
///
/// وعلى الهاتف كان العيب مستوراً: الرقاقات تملأ العرض وتفيض عنه.
void main() {
  const labels = ['الكل', 'متاحة', 'ممتلئة', 'منتهية'];

  Future<void> pump(WidgetTester tester, Size screen) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        // المقياس المتكيّف نفسه الذي يستعمله التطبيق
        designSize: adaptiveDesignSize(screen),
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: StatusFilterBar(
                options: [
                  for (final label in labels)
                    StatusFilterOption(
                      label: label,
                      color: MyColors.primary,
                      icon: Icons.circle,
                      count: 1,
                      isSelected: label == labels.first,
                      onTap: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// حافة الرقاقة الأولى اليمنى — يجب أن تكون قريبة من يمين الشاشة.
  double firstChipRight(WidgetTester tester) =>
      tester.getRect(find.text(labels.first)).right;

  group('الشريط يبدأ من يمين الشاشة', () {
    testWidgets('على التابلت — العيب المُصلَح', (tester) async {
      const width = 1024.0;
      await pump(tester, const Size(width, 768));

      final right = firstChipRight(tester);

      expect(right, greaterThan(width * 0.85),
          reason: 'كانت الرقاقات تتجمّع في النصف الأيسر ويُترك اليمين '
              'فارغاً — أوّل ما تقع عليه العين');

      // وآخر رقاقة تبقى داخل الشاشة: الصفّ لا يفيض بلا داعٍ
      expect(tester.getRect(find.text(labels.last)).left, greaterThan(0));
    });

    testWidgets('وعلى شاشة أعرض بعد', (tester) async {
      const width = 1280.0;
      await pump(tester, const Size(width, 800));

      expect(firstChipRight(tester), greaterThan(width * 0.85));
    });

    testWidgets('والهاتف كما كان — الرقاقات تملأ عرضه', (tester) async {
      const width = 375.0;
      await pump(tester, const Size(width, 812));

      expect(firstChipRight(tester), greaterThan(width * 0.85));
    });
  });

  group('ترتيب الرقاقات', () {
    testWidgets('الأولى يمين الأخيرة — لا العكس', (tester) async {
      await pump(tester, const Size(1024, 768));

      expect(
        tester.getCenter(find.text(labels.first)).dx,
        greaterThan(tester.getCenter(find.text(labels.last)).dx),
        reason: 'في العربية تُقرأ الأولى أولاً — أي من اليمين',
      );
    });

    testWidgets('وكلّها ظاهرة على شاشة عريضة', (tester) async {
      await pump(tester, const Size(1024, 768));

      for (final label in labels) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });
}
