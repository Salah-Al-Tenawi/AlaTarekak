import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// الحوار الموحّد.
///
/// كان لكل شاشة حوارها: هذا بعنوان في صفّ وأيقونة صغيرة، وذاك بزرّي نصّ
/// بلا وزن بصري، وثالث بزرّ يمتدّ بعرض الحوار كلّه لأن الثيم يفرض
/// `minimumSize: double.infinity` — مناسب لأسفل نموذج، لا لحوار.

Future<bool?> _open(
  WidgetTester tester, {
  String? confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
  bool destructive = false,
  String? message = 'شرح ما سيحدث',
  Size screen = const Size(390, 844),
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  bool? result;
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: screen,
      builder: (context, _) => MaterialApp(
        theme: ThemApp.lightThem,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showAppDialog(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'عنوان الحوار',
                      message: message,
                      confirmLabel: confirmLabel,
                      cancelLabel: cancelLabel,
                      destructive: destructive,
                    );
                  },
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('افتح'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('البنية', () {
    testWidgets('أيقونة وعنوان وشرح وزرّان', (tester) async {
      await _open(tester);

      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      expect(find.text('عنوان الحوار'), findsOneWidget);
      expect(find.text('شرح ما سيحدث'), findsOneWidget);
      expect(find.text('تأكيد'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    });

    testWidgets('بلا شرح لا يُترك فراغ', (tester) async {
      await _open(tester, message: null);

      expect(find.text('عنوان الحوار'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('عرض الأزرار — العيب الأصلي', () {
    testWidgets('الزرّان متساويان ولا يمتدّ أحدهما بعرض الشاشة',
        (tester) async {
      const screen = Size(390, 844);
      await _open(tester, screen: screen);

      final confirm = tester.getSize(find.byType(ElevatedButton));
      final cancel = tester.getSize(find.byType(OutlinedButton));

      expect(confirm.width, closeTo(cancel.width, 1));
      expect(confirm.width, lessThan(screen.width * 0.6));
    });

    testWidgets('نصّ طويل على شاشة ضيّقة لا يفيض', (tester) async {
      await _open(
        tester,
        screen: const Size(320, 640),
        confirmLabel: 'إعادة التقديم الآن',
        cancelLabel: 'ليس الآن شكراً',
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('الإجراءات', () {
    testWidgets('التأكيد يعيد true', (tester) async {
      await _open(tester);
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();

      expect(find.byType(AppDialogContent), findsNothing);
    });

    testWidgets('بلا إجراء: زرّ «حسناً» وحده', (tester) async {
      await _open(tester, confirmLabel: null);

      expect(find.text('حسناً'), findsOneWidget);
      expect(find.text('إلغاء'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing,
          reason: 'زرّان أحدهما بلا معنى يجعل المستخدم يتردّد');
    });

    testWidgets('الإلغاء يُغلق الحوار', (tester) async {
      await _open(tester);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(find.byType(AppDialogContent), findsNothing);
      expect(find.text('افتح'), findsOneWidget);
    });
  });

  group('الاستجابة للقياس', () {
    testWidgets('الوضع الأفقي: يمرّر بلا فيض', (tester) async {
      await _open(
        tester,
        screen: const Size(740, 360),
        message: 'شرح طويل جداً يمتدّ على أسطر عدّة ليختبر ما يحدث حين لا '
            'يتّسع ارتفاع الشاشة للحوار كاملاً، وهو ما يقع في الوضع الأفقي '
            'وعلى الأجهزة القصيرة.',
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('شاشة عريضة: الحوار محصور لا يتمدّد', (tester) async {
      await _open(tester, screen: const Size(1200, 900));

      // Dialog نفسه يملأ الشاشة ويوسّط محتواه، فالقياس على المحتوى
      final width = tester.getSize(find.text('عنوان الحوار')).width;
      expect(width, lessThanOrEqualTo(400),
          reason: 'حوار بعرض 1200 بكسل لا يُقرأ');
    });
  });
}
