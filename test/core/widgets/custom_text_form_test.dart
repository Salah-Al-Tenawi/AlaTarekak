import 'package:alatarekak/core/utils/widgets/custom_text_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrapForTest(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  group('CustomTextformfild', () {
    testWidgets('يعرض عنوان الحقل ويكتب النص في الـ controller',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(wrapForTest(
        CustomTextformfild(title: 'البريد الإلكتروني', controller: controller),
      ));

      expect(find.text('البريد الإلكتروني'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(controller.text, 'test@example.com');
    });

    testWidgets('يخفي النص عند scureText = true (حقل كلمة المرور)',
        (tester) async {
      await tester.pumpWidget(wrapForTest(
        const CustomTextformfild(title: 'كلمة المرور', scureText: true),
      ));

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.obscureText, isTrue);
    });

    testWidgets('يعرض رسالة الـ validator عند فشل التحقق', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(wrapForTest(
        Form(
          key: formKey,
          child: CustomTextformfild(
            title: 'البريد الإلكتروني',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
          ),
        ),
      ));

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    });
  });
}
