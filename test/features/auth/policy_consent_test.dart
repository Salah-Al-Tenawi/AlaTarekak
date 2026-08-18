import 'package:alatarekak/features/auth/presentation/view/widget/policy_consent_check.dart';
import 'package:alatarekak/features/policy/text/pollicy_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  group('PolicyConsentCheck — الموافقة الصريحة', () {
    testWidgets('غير مؤشَّر افتراضياً — لا موافقة ضمنية', (tester) async {
      await tester.pumpWidget(_wrap(
        PolicyConsentCheck(value: false, onChanged: (_) {}),
      ));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('الضغط يُبلّغ المستدعي بالقيمة الجديدة', (tester) async {
      bool? received;
      await tester.pumpWidget(_wrap(
        PolicyConsentCheck(value: false, onChanged: (v) => received = v),
      ));

      await tester.tap(find.byType(Checkbox));
      expect(received, isTrue);
    });

    testWidgets('التنبيه يظهر فقط عند طلبه', (tester) async {
      const message = 'يجب الموافقة على السياسات لإنشاء الحساب';

      await tester.pumpWidget(_wrap(
        PolicyConsentCheck(value: false, onChanged: (_) {}),
      ));
      expect(find.text(message), findsNothing);

      await tester.pumpWidget(_wrap(
        PolicyConsentCheck(
            value: false, onChanged: (_) {}, showError: true),
      ));
      expect(find.text(message), findsOneWidget);
    });
  });

  group('PolicyText — النصوص تصف التطبيق فعلاً', () {
    test('لا تذكر بيانات لا يجمعها التطبيق', () {
      final all = [
        ...PolicyText.privacy,
        ...PolicyText.cancellation,
      ].expand((s) => [s.title, s.intro ?? '', ...s.points]).join(' ');

      // النسخة السابقة كانت تزعم جمعها وهي غير موجودة في الكود إطلاقاً
      expect(all, isNot(contains('تاريخ الميلاد')));
      expect(all, isNot(contains('التأمين')));
    });

    test('تذكر رقم الهاتف والمحفظة التي تُفتح عليه تلقائياً', () {
      final collected = PolicyText.privacy
          .expand((s) => s.points)
          .join(' ');

      expect(collected, contains('رقم الهاتف'));
      expect(collected, contains('محفظتك'));
    });

    test('تذكر الأطراف الثالثة الحقيقية لا Google وWhatsApp وحدهما', () {
      final sharing = PolicyText.privacy
          .firstWhere((s) => s.title.contains('نشارك'))
          .points
          .join(' ');

      expect(sharing, contains('OpenRouteService'));
      expect(sharing, contains('GraphHopper'));
      expect(sharing, contains('Pusher'));
    });

    test('نسب الاسترداد تطابق قواعد الخادم', () {
      final refund = PolicyText.cancellation
          .firstWhere((s) => s.title.contains('الدفع الإلكتروني'))
          .points;

      expect(refund, hasLength(4));
      expect(refund[0], contains('30%'));
      expect(refund[1], contains('70%'));
      expect(refund[2], contains('50%'));
      expect(refund[3], contains('لا يُسترد'));
    });

    test('كل قسم له عنوان ومحتوى', () {
      for (final s in [...PolicyText.privacy, ...PolicyText.cancellation]) {
        expect(s.title, isNotEmpty);
        expect(s.intro != null || s.points.isNotEmpty, isTrue,
            reason: 'القسم "${s.title}" بلا محتوى');
      }
    });
  });

  group('سطر الموافقة يأتي من لوحة الأدمن', () {
    testWidgets('النصّ المُمرَّر يُعرض بدل المدمج', (tester) async {
      const fromAdmin = 'أقرّ بموافقتي على سياسة الخصوصية وسياسة الإلغاء';

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: PolicyConsentCheck(
                  value: false,
                  consentLabel: fromAdmin,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('أقرّ بموافقتي'), findsOneWidget);
      expect(find.textContaining(PolicyText.consentLabel), findsNothing);
    });

    testWidgets('بلا نصّ من اللوحة يعود إلى المدمج', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: PolicyConsentCheck(value: false, onChanged: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(PolicyText.consentLabel), findsOneWidget);
    });
  });
}
