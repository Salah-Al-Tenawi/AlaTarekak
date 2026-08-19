import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/status_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// شريط التصنيف المشترك بين «حجوزاتي» و«رحلاتي».
///
/// كانت كل شاشة ستبني رقاقاتها بنفسها، فتختلف الأنصاف والحدود والوزن
/// بينها كما اختلفت بطاقات الرحلة قبل توحيدها. هذه الاختبارات تخصّ
/// اللبنة نفسها لا الشاشتين.
void main() {
  late List<String> tapped;

  List<StatusFilterOption> options({
    String selected = 'الكل',
    Map<String, int> counts = const {'الكل': 6, 'ملغاة': 2, 'منتهية': 0},
  }) {
    return [
      for (final label in const ['الكل', 'ملغاة', 'منتهية'])
        StatusFilterOption(
          label: label,
          color: MyColors.primary,
          icon: Icons.circle,
          count: counts[label] ?? 0,
          isSelected: label == selected,
          onTap: () => tapped.add(label),
        ),
    ];
  }

  Future<void> pumpBar(
    WidgetTester tester,
    List<StatusFilterOption> opts,
  ) async {
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
            child: Scaffold(body: StatusFilterBar(options: opts)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => tapped = []);

  testWidgets('كل خيار يُرسم بتسميته وعدّاده', (tester) async {
    await pumpBar(tester, options());

    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('ملغاة'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('العدّاد يُخفى حين يكون صفراً — لا «منتهية 0»', (tester) async {
    await pumpBar(tester, options());

    expect(find.text('منتهية'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('الضغط يُبلّغ الخيار المضغوط وحده', (tester) async {
    await pumpBar(tester, options());

    await tester.tap(find.text('ملغاة'));
    await tester.pumpAndSettle();

    expect(tapped, ['ملغاة']);
  });

  testWidgets('الرقاقة الفارغة تبقى قابلة للضغط', (tester) async {
    await pumpBar(tester, options());

    // إخفاؤها يجعل الشريط يرقص كلما تغيّرت القائمة
    await tester.tap(find.text('منتهية'));
    await tester.pumpAndSettle();

    expect(tapped, ['منتهية']);
  });

  testWidgets('المختار يُعلَن مختاراً لقارئ الشاشة', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBar(tester, options(selected: 'ملغاة'));

    expect(
      tester.getSemantics(find.text('ملغاة')),
      matchesSemantics(
        isButton: true,
        isSelected: true,
        isFocusable: true,
        hasSelectedState: true,
        // فعلا الضغط والتركيز من `InkWell`: استثناء الأبناء من الدلالات
        // يخفي تكرار التسمية ولا يسلب الرقاقة قابليّتها للتفعيل
        hasTapAction: true,
        hasFocusAction: true,
        label: 'ملغاة، 2',
        textDirection: TextDirection.rtl,
      ),
    );

    handle.dispose();
  });

  testWidgets('الشريط يمرّر أفقياً بدل أن يفيض', (tester) async {
    // عشر رقاقات: أعرض بكثير من 375
    await pumpBar(tester, [
      for (var i = 0; i < 10; i++)
        StatusFilterOption(
          label: 'مجموعة رقم $i',
          color: MyColors.primary,
          icon: Icons.circle,
          count: i,
          isSelected: i == 0,
          onTap: () {},
        ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('آخر رقاقة مبنيّة ولو كانت خارج الشاشة', (tester) async {
    // بناء كسول كان يترك آخرها غير مبنيّ فلا يصله التمرير البرمجي
    await pumpBar(tester, [
      for (var i = 0; i < 10; i++)
        StatusFilterOption(
          label: 'مجموعة رقم $i',
          color: MyColors.primary,
          icon: Icons.circle,
          count: 1,
          isSelected: false,
          onTap: () => tapped.add('$i'),
        ),
    ]);

    expect(find.text('مجموعة رقم 9'), findsOneWidget);

    await tester.ensureVisible(find.text('مجموعة رقم 9'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مجموعة رقم 9'));

    expect(tapped, ['9']);
  });
}
