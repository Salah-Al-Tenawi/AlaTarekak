import 'package:alatarekak/core/utils/class/syrian_phone.dart';
import 'package:alatarekak/features/auth/presentation/view/widget/text_fileds_singin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// حقل رقم الهاتف في نموذج إنشاء الحساب.
///
/// الخادم يقبل الأرقام السورية وحدها (`^09\d{8}$`)، ولم يكن في الحقل ما
/// يقول ذلك: لا مفتاح ولا صيغة — فيملأ المستخدم النموذج كلّه ثم يُرفض.

void main() {
  late TextEditingController firstname;
  late TextEditingController lastname;
  late TextEditingController email;
  late TextEditingController phone;
  late TextEditingController password;
  late TextEditingController passwordConfirm;
  late GlobalKey<FormState> formKey;

  setUp(() {
    firstname = TextEditingController();
    lastname = TextEditingController();
    email = TextEditingController();
    phone = TextEditingController();
    password = TextEditingController();
    passwordConfirm = TextEditingController();
    formKey = GlobalKey<FormState>();
  });

  tearDown(() {
    for (final c in [
      firstname,
      lastname,
      email,
      phone,
      password,
      passwordConfirm
    ]) {
      c.dispose();
    }
  });

  Future<void> pump(WidgetTester tester) async {
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
            // النموذج عربي بالكامل — الحقل وحده يجب أن يخرج عن اتجاهه
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: TextFieldsSingin(
                    firstname: firstname,
                    lastname: lastname,
                    email: email,
                    phoneNumber: phone,
                    password: password,
                    passwordConfirm: passwordConfirm,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder phoneField() => find.ancestor(
        of: find.text('+963'),
        matching: find.byType(TextFormField),
      );

  group('المفتاح الدولي مثبَّت في الحقل', () {
    testWidgets('«963+» ظاهر قبل أن يكتب المستخدم شيئاً', (tester) async {
      await pump(tester);
      expect(find.text('+963'), findsOneWidget);
    });

    testWidgets('التلميح يقول ما هو المطلوب', (tester) async {
      await pump(tester);
      expect(find.text('رقم الهاتف'), findsOneWidget);
    });

    testWidgets('الحقل بترتيب LTR فيقع المفتاح يساراً لا يميناً',
        (tester) async {
      await pump(tester);

      final direction = tester
          .widget<Directionality>(find.ancestor(
            of: find.text('+963'),
            matching: find.byType(Directionality),
          ).first)
          .textDirection;
      expect(direction, TextDirection.ltr);
    });

    testWidgets('المفتاح ثابت لا يدخل في قيمة الحقل', (tester) async {
      await pump(tester);
      await tester.enterText(phoneField(), '988626577');

      expect(phone.text, '988626577',
          reason: 'النصّ المكتوب وحده — المفتاح رسمٌ لا محتوى');
    });
  });

  group('ما يقبله الحقل وما يرفضه', () {
    /// النموذج فيه حقول أخرى فارغة، فقيمة `validate()` لا تعني شيئاً عن
    /// الهاتف وحده — الحكم هو ظهور رسالة الرقم تحت حقله.
    Future<bool> phoneRejected(WidgetTester tester) async {
      formKey.currentState!.validate();
      await tester.pump();
      return find.text(SyrianPhone.error).evaluate().isNotEmpty;
    }

    testWidgets('الرقم بلا صفر (كما يوحي المفتاح) يمرّ', (tester) async {
      await pump(tester);
      await tester.enterText(phoneField(), '988626577');

      expect(await phoneRejected(tester), isFalse);
    });

    testWidgets('الصيغة المحلية بالصفر تمرّ أيضاً — لا نعرقل من كتبها',
        (tester) async {
      await pump(tester);
      await tester.enterText(phoneField(), '0988626577');

      expect(await phoneRejected(tester), isFalse);
    });

    testWidgets('رقم غير سوري يُرفض برسالة تذكر الصيغتين', (tester) async {
      await pump(tester);
      await tester.enterText(phoneField(), '0888626577');

      expect(await phoneRejected(tester), isTrue);
      expect(find.text(SyrianPhone.error), findsOneWidget);
    });

    testWidgets('الحقل الفارغ يُرفض قبل الإرسال', (tester) async {
      await pump(tester);
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('لا يمكن ترك الحقل فارغ'), findsWidgets);
    });

    testWidgets('الحروف لا تُكتب أصلاً — المفتاح أمامه فالمُدخل أرقام',
        (tester) async {
      await pump(tester);
      await tester.enterText(phoneField(), '09ab88626c577');

      expect(phone.text, '0988626577',
          reason: 'الحروف تُسقَط ويبقى ترتيب الأرقام');
    });

    testWidgets('لصق الرقم بمفتاحه الدولي يمرّ رغم فلتر الأرقام',
        (tester) async {
      await pump(tester);
      // الفلتر يُسقط «+» فيصير 963988626577، وSyrianPhone يقرأها
      await tester.enterText(phoneField(), '+963988626577');
      formKey.currentState!.validate();
      await tester.pump();

      expect(phone.text, '963988626577');
      expect(find.text(SyrianPhone.error), findsNothing);
      expect(SyrianPhone.normalize(phone.text), '0988626577');
    });
  });
}
