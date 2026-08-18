import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

/// حركات دخول العناصر.
///
/// كل عنصر في القوائم يُغلَّف بـ [FadeSlideIn]، فقائمة من ثماني بطاقات
/// تُشغّل ثماني حركات متزامنة عند كل عرض. وعلى الأجهزة الضعيفة يكفي ذلك
/// لتقطّع محسوس.
///
/// مفتاحان يُطفئانها: إعداد النظام «تقليل الحركة» (يحترمه التطبيق
/// تلقائياً)، و[AppAnim.entranceEnabled] لتشخيص التقطّع يدوياً.

Widget _wrap(Widget child, {bool disableAnimations = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
    );

void main() {
  tearDown(() => AppAnim.entranceEnabled = true);

  testWidgets('الحركة تعمل افتراضياً', (tester) async {
    await tester.pumpWidget(_wrap(const FadeSlideIn(child: Text('رحلة'))));

    expect(find.byType(Animate), findsOneWidget);
    expect(find.text('رحلة'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('«تقليل الحركة» في النظام يُطفئها — والمحتوى يبقى',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const FadeSlideIn(child: Text('رحلة')), disableAnimations: true),
    );

    expect(find.byType(Animate), findsNothing,
        reason: 'لا حركة لمن طلب من نظامه ألّا يراها');
    expect(find.text('رحلة'), findsOneWidget,
        reason: 'المحتوى يُعرض كاملاً — الحركة زينة لا شرط');
  });

  testWidgets('مفتاح الإطفاء اليدوي يعمل كذلك', (tester) async {
    AppAnim.entranceEnabled = false;

    await tester.pumpWidget(_wrap(const FadeSlideIn(child: Text('رحلة'))));

    expect(find.byType(Animate), findsNothing);
    expect(find.text('رحلة'), findsOneWidget);
  });

  testWidgets('التدرّج مطفأ كذلك حين تُطفأ الحركة', (tester) async {
    AppAnim.entranceEnabled = false;

    await tester.pumpWidget(
      _wrap(
        Column(
          children: const [
            StaggeredItem(index: 0, child: Text('أولى')),
            StaggeredItem(index: 5, child: Text('سادسة')),
          ],
        ),
      ),
    );

    expect(find.byType(Animate), findsNothing);
    expect(find.text('أولى'), findsOneWidget);
    expect(find.text('سادسة'), findsOneWidget);
  });

  test('سقف التدرّج يمنع تأخيراً طويلاً في القوائم الكبيرة', () {
    // بلا سقف يبدأ العنصر رقم 40 بعد أكثر من ثانيتين، فتبدو القائمة
    // معلّقة وهي تعمل
    expect(AppAnim.maxStaggered, lessThanOrEqualTo(8));
    expect(AppAnim.stagger * AppAnim.maxStaggered,
        lessThanOrEqualTo(const Duration(milliseconds: 600)));
  });
}
