import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// حوار «الخروج من التطبيق».
///
/// آخر حوار بقي على `AlertDialog` الخام: عنوان «تأكيد» وسؤال مجرّد
/// وزرّان نصّيان بلا وزن بصري، بينما وُحّد ما عداه على [showAppDialog].
///
/// والنصّ نفسه كان ناقصاً: «هل تريد الخروج؟» لا تقول للمستخدم إن كان
/// سيخرج من حسابه أم من التطبيق وحده — وهو الفرق الذي يهمّه.

/// يفتح الحوار ويكتب نتيجته في [sink] حين تصل — لا يُعيدها،
/// لأن الدالة تعود قبل أن يضغط الاختبار زرّاً.
Future<void> _openExitDialog(WidgetTester tester,
    {List<bool?>? sink}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        theme: ThemApp.lightThem,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    // النصّ نفسه المستعمل في home.dart
                    final r = await showAppDialog(
                      context,
                      icon: Icons.exit_to_app_rounded,
                      title: 'الخروج من التطبيق',
                      message:
                          'ستبقى مسجّلاً في حسابك، ورحلاتك وحجوزاتك كما هي. '
                          'وستصلك الإشعارات حتى وأنت خارج التطبيق.',
                      confirmLabel: 'خروج',
                      cancelLabel: 'البقاء',
                      destructive: true,
                    );
                    sink?.add(r);
                  },
                  child: const Text('اخرج'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('اخرج'));
  await tester.pumpAndSettle();
}

void main() {
  group('الشكل', () {
    testWidgets('بهوية التطبيق لا AlertDialog خام', (tester) async {
      await _openExitDialog(tester);

      expect(find.byType(AppDialogContent), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byIcon(Icons.exit_to_app_rounded), findsOneWidget);
    });

    testWidgets('يوضّح أن الحساب يبقى — لا مجرّد «هل تريد الخروج؟»',
        (tester) async {
      await _openExitDialog(tester);

      expect(find.text('الخروج من التطبيق'), findsOneWidget);
      expect(find.textContaining('ستبقى مسجّلاً في حسابك'), findsOneWidget);
      expect(find.textContaining('الإشعارات'), findsOneWidget);
    });

    testWidgets('الزرّان بنصّ صريح لا «نعم» و«لا»', (tester) async {
      await _openExitDialog(tester);

      expect(find.text('خروج'), findsOneWidget);
      expect(find.text('البقاء'), findsOneWidget);
      expect(find.text('نعم'), findsNothing);
      expect(find.text('لا'), findsNothing);
    });
  });

  group('النتيجة', () {
    testWidgets('«خروج» يعيد true', (tester) async {
      final result = <bool?>[];
      await _openExitDialog(tester, sink: result);

      await tester.tap(find.text('خروج'));
      await tester.pumpAndSettle();

      expect(result, [true]);
    });

    testWidgets('«البقاء» يعيد false — والتطبيق لا يُغلق', (tester) async {
      final result = <bool?>[];
      await _openExitDialog(tester, sink: result);

      await tester.tap(find.text('البقاء'));
      await tester.pumpAndSettle();

      expect(result, [false]);
      expect(find.byType(AppDialogContent), findsNothing);
    });
  });
}
