import 'package:alatarekak/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:integration_test/integration_test.dart';

/// اختبار تكامل (NFR-02) — يعمل على جهاز/محاكي حقيقي:
///   flutter test integration_test/app_test.dart -d `device-id`
///
/// السيناريو: إقلاع التطبيق كاملاً (Hive + Locator + Theme) والتحقق من
/// الوصول إلى شاشة البداية دون أعطال.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('يقلع التطبيق ويعرض الواجهة بالعربية RTL', (tester) async {
    app.main();
    // ننتظر شاشة البداية (Splash) وأي تحويل بعدها
    await tester.pumpAndSettle(const Duration(seconds: 5));

    final materialApp = tester.widget<GetMaterialApp>(
      find.byType(GetMaterialApp),
    );

    expect(materialApp.locale, const Locale('ar'));
    expect(materialApp.textDirection, TextDirection.rtl);
    // لا يوجد شاشة خطأ حمراء — التطبيق أقلع بنجاح
    expect(tester.takeException(), isNull);
  });
}
