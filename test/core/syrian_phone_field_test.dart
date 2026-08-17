import 'package:alatarekak/core/utils/class/syrian_phone.dart';
import 'package:alatarekak/core/utils/widgets/syrian_phone_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// حقل رقم الهاتف المشترك — يطلبه التطبيق في أربعة مواضع: إنشاء الحساب،
/// تفعيل المحفظة، إنشاء رحلة، وحجز مقعد. كان كل موضع يكتب حقله بنفسه،
/// وأربعتهم بلا ما يقول إن الرقم **سوري حصراً** — فيكتشفه المستخدم من
/// رفض الخادم بعد أن يملأ النموذج.

void main() {
  late TextEditingController controller;
  late GlobalKey<FormState> formKey;

  setUp(() {
    controller = TextEditingController();
    formKey = GlobalKey<FormState>();
  });

  tearDown(() => controller.dispose());

  Future<void> pump(
    WidgetTester tester, {
    String? helperText,
    Widget? suffixIcon,
    bool enabled = true,
  }) async {
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
            // الشاشات المستضيفة كلها عربية — الحقل وحده يخرج عن اتجاهها
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Form(
                key: formKey,
                child: SyrianPhoneField(
                  controller: controller,
                  helperText: helperText,
                  suffixIcon: suffixIcon,
                  enabled: enabled,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// النموذج قد يحوي حقولاً أخرى في الشاشات الحقيقية — الحكم هو ظهور
  /// رسالة الرقم لا قيمة `validate()`.
  Future<bool> rejected(WidgetTester tester) async {
    formKey.currentState!.validate();
    await tester.pump();
    return find.text(SyrianPhone.error).evaluate().isNotEmpty;
  }

  group('المفتاح مثبَّت ومرئي', () {
    testWidgets('«963+» ظاهر قبل أن يكتب المستخدم شيئاً', (tester) async {
      await pump(tester);
      expect(find.text('+963'), findsOneWidget);
    });

    testWidgets('يبقى ظاهراً بعد الكتابة', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField), '988626577');
      await tester.pump();

      expect(find.text('+963'), findsOneWidget);
    });

    testWidgets('التلميح يُسمّي المطلوب ولا يرسم صيغة أرقام', (tester) async {
      await pump(tester);

      expect(find.text('رقم الهاتف'), findsOneWidget);
      // قالب مثل «9XX XXX XXX» يوحي بأنه الصيغة الوحيدة، والحقل يقبل
      // أوسع منها
      expect(SyrianPhoneField.hint, isNot(contains('X')));
    });

    testWidgets('الحقل LTR داخل شاشة RTL فيقع المفتاح يساراً', (tester) async {
      await pump(tester);

      final field = tester.widget<Directionality>(
        find
            .ancestor(
                of: find.byType(TextFormField),
                matching: find.byType(Directionality))
            .first,
      );
      expect(field.textDirection, TextDirection.ltr);
    });

    testWidgets('المفتاح رسمٌ لا محتوى — لا يدخل في قيمة الحقل',
        (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField), '988626577');

      expect(controller.text, '988626577');
    });
  });

  group('ما يُقبل وما يُرفض', () {
    testWidgets('الرقم بلا صفر (كما يوحي المفتاح) يمرّ', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField), '988626577');

      expect(await rejected(tester), isFalse);
    });

    testWidgets('الصيغة المحلية بالصفر تمرّ أيضاً', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField), '0988626577');

      expect(await rejected(tester), isFalse);
    });

    testWidgets('لصق الرقم بمفتاحه الدولي يمرّ رغم فلتر الأرقام',
        (tester) async {
      await pump(tester);
      // الفلتر يُسقط «+» فيصير 963988626577، وSyrianPhone يقرأها
      await tester.enterText(find.byType(TextFormField), '+963988626577');

      expect(controller.text, '963988626577');
      expect(await rejected(tester), isFalse);
      expect(SyrianPhone.normalize(controller.text), '0988626577');
    });

    testWidgets('الحروف لا تُكتب أصلاً', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField), '09ab88626c577');

      expect(controller.text, '0988626577');
    });

    testWidgets('رقم غير سوري يُرفض برسالة تذكر الصيغتين', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField), '0888626577');

      expect(await rejected(tester), isTrue);
    });

    testWidgets('الحقل الفارغ يُرفض برسالته الخاصة', (tester) async {
      await pump(tester);
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('الرجاء إدخال رقم الهاتف'), findsOneWidget);
      expect(find.text(SyrianPhone.error), findsNothing,
          reason: 'الفراغ ليس صيغة خاطئة');
    });
  });

  group('ما يختلف بين المواضع الأربعة', () {
    testWidgets('السطر المساعد (الحجز)', (tester) async {
      await pump(tester, helperText: 'يُقبل 0988626577 أو +963988626577');
      expect(find.textContaining('يُقبل'), findsOneWidget);
    });

    testWidgets('مؤشّر الصحّة (إنشاء رحلة)', (tester) async {
      await pump(tester,
          suffixIcon: const Icon(Icons.check_circle_rounded));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('الحقل يُعطَّل أثناء الإرسال (المحفظة)', (tester) async {
      await pump(tester, enabled: false);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });
  });
}
