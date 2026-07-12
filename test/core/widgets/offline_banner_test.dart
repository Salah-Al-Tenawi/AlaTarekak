import 'package:alatarekak/core/utils/widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// NFR-17: شريط انقطاع الاتصال يظهر ويختفي مع حالة الشبكة.
void main() {
  testWidgets('يظهر الشريط عند الانقطاع ويختفي عند عودة الاتصال',
      (tester) async {
    final isOffline = ValueNotifier<bool>(false);
    addTearDown(isOffline.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: OfflineBanner(
            isOffline: isOffline,
            child: const Scaffold(body: Text('المحتوى')),
          ),
        ),
      ),
    );

    // متصل: لا شريط، والمحتوى ظاهر
    expect(find.text(OfflineBanner.offlineMessage), findsNothing);
    expect(find.text('المحتوى'), findsOneWidget);

    // انقطاع: يظهر الشريط دون إخفاء المحتوى
    isOffline.value = true;
    await tester.pumpAndSettle();
    expect(find.text(OfflineBanner.offlineMessage), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.text('المحتوى'), findsOneWidget);

    // عودة الاتصال: يختفي الشريط
    isOffline.value = false;
    await tester.pumpAndSettle();
    expect(find.text(OfflineBanner.offlineMessage), findsNothing);
  });
}
