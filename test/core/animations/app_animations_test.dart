import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// أنيميشن الدخول يجب أن يكون منتهياً دائماً (NFR-20) —
/// pumpAndSettle يفشل لو وُجدت حركة لا نهائية.
void main() {
  testWidgets('FadeSlideIn يعرض المحتوى فوراً ويُكمل حركته', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FadeSlideIn(child: Text('محتوى'))),
    );

    // المحتوى موجود في الشجرة منذ الإطار الأول (لا وميض فراغ)
    expect(find.text('محتوى'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('محتوى'), findsOneWidget);
  });

  testWidgets('StaggeredItem يقيّد تأخير العناصر البعيدة في القوائم الطويلة',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: StaggeredItem(index: 500, child: Text('عنصر'))),
    );

    // لو لم يُقيَّد التأخير لانتظر العنصر 500 × 60ms = نصف دقيقة.
    // نقفز بعد أقصى تأخير مقيد (8 × 60ms) + مدة الدخول ثم نتأكد من الاكتمال.
    await tester.pump(AppAnim.stagger * AppAnim.maxStaggered);
    await tester.pumpAndSettle();
    expect(find.text('عنصر'), findsOneWidget);
  });

  testWidgets('StateSwitcher يبدّل بين حالتين بنعومة', (tester) async {
    Widget build(Widget child) =>
        MaterialApp(home: StateSwitcher(child: child));

    await tester.pumpWidget(build(const Text('تحميل', key: ValueKey('a'))));
    await tester.pumpAndSettle();
    expect(find.text('تحميل'), findsOneWidget);

    await tester.pumpWidget(build(const Text('محتوى', key: ValueKey('b'))));
    await tester.pumpAndSettle();
    expect(find.text('محتوى'), findsOneWidget);
    expect(find.text('تحميل'), findsNothing);
  });
}
