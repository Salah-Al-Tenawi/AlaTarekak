import 'dart:ui' show Size;

import 'package:alatarekak/core/utils/class/adaptive_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// حدّ تضخّم القياسات على الشاشات العريضة.
///
/// `flutter_screenutil` يقيس بنسبة عرض الشاشة إلى عرض التصميم — و`.sp`
/// و`.w` و`.h` و`.r` كلها منها. وكان التصميم مثبَّتاً على 375، فعلى
/// تابلت عرضه 800 صارت النسبة 2.13: كل خطّ وحشوة مضاعفان مرّتين، في كل
/// شاشة دفعةً واحدة.
double scaleFor(Size screen) => screen.width / adaptiveDesignSize(screen).width;

void main() {
  group('الهواتف لا تتغيّر البتّة', () {
    test('مقاس التصميم نفسه: نسبة واحد', () {
      expect(adaptiveDesignSize(const Size(375, 812)), kBaseDesignSize);
      expect(scaleFor(const Size(375, 812)), 1.0);
    });

    test('هاتف أعرض قليلاً يبقى على تصميمه', () {
      expect(adaptiveDesignSize(const Size(414, 896)), kBaseDesignSize,
          reason: 'نسبته 1.10 — دون السقف، فلا يُمسّ');
    });

    test('وهاتف أضيق يُصغَّر بلا حدّ — التصغير مطلوب', () {
      expect(adaptiveDesignSize(const Size(320, 640)), kBaseDesignSize);
      expect(scaleFor(const Size(320, 640)), lessThan(1.0));
    });
  });

  group('الأجهزة العريضة تقف عند السقف', () {
    test('تابلت 800: النسبة 1.15 لا 2.13', () {
      final scale = scaleFor(const Size(800, 1280));

      expect(scale, closeTo(kMaxDesignScale, 0.001));
      expect(scale, lessThan(2.13),
          reason: 'هذا ما كان يقع: كل خطّ مضاعف مرّتين');
    });

    test('وتابلت 1280 كذلك — السقف لا يُتجاوز مهما اتّسعت', () {
      expect(scaleFor(const Size(1280, 800)), closeTo(kMaxDesignScale, 0.001));
    });

    test('والنسبة تبقى واحدة للعرض والارتفاع — لا تشويه', () {
      const screen = Size(1024, 768);
      final design = adaptiveDesignSize(screen);

      expect(screen.width / design.width,
          closeTo(screen.height / design.height, 0.001));
    });

    test('مقاس بلا أبعاد يسقط إلى التصميم الأصلي', () {
      expect(adaptiveDesignSize(Size.zero), kBaseDesignSize);
    });
  });

  group('الأثر على قياس حقيقي', () {
    /// يقيس `16.sp` كما يراها التطبيق على شاشة بمقاس معيّن.
    Future<double> fontOn(WidgetTester tester, Size screen) async {
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late double measured;
      await tester.pumpWidget(
        LayoutBuilder(
          builder: (context, constraints) => ScreenUtilInit(
            designSize: adaptiveDesignSize(constraints.biggest),
            minTextAdapt: true,
            child: Builder(builder: (context) {
              measured = 16.sp;
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      await tester.pump();
      return measured;
    }

    testWidgets('خطّ 16 يبقى 16 على الهاتف', (tester) async {
      expect(await fontOn(tester, const Size(375, 812)), closeTo(16, 0.1));
    });

    testWidgets('ولا يصير 34 على التابلت', (tester) async {
      final size = await fontOn(tester, const Size(800, 1280));

      expect(size, closeTo(16 * kMaxDesignScale, 0.5));
      expect(size, lessThan(20),
          reason: 'كان 16 × 2.13 ≈ 34 — وهو ما رآه المجرّب');
    });
  });
}
