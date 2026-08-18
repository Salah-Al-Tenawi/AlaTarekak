import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/core/utils/functions/show_image.dart';
import 'package:alatarekak/core/utils/widgets/app_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// عارض الصورة بملء الشاشة (صور الملف الشخصي والمركبات).
///
/// عيبان: كان يعرض بـ `cover` فيقصّ أطراف الصورة — ومن يفتح صورة رخصة
/// أو مركبة يفتحها ليراها كاملة — وكانت رسالة تعذّر التحميل بألوان خام
/// (`Colors.grey[200]`، زرّ `Colors.red`) لا صلة لها بهوية التطبيق.

Future<void> _openViewer(WidgetTester tester, String url) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => GetMaterialApp(
        theme: ThemApp.lightThem,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openImage(url),
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('افتح'));
  await tester.pumpAndSettle();
}

void main() {
  group('عرض الصورة', () {
    testWidgets('تُعرض كاملة (contain) لا مقصوصة (cover)', (tester) async {
      await _openViewer(tester, 'assets/images/app_logo.png');

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        image.fit,
        BoxFit.contain,
        reason: 'cover يقصّ أطراف الصورة، والغاية هنا الرؤية لا التزيين',
      );
    });

    testWidgets('يُتاح التكبير باللمس', (tester) async {
      await _openViewer(tester, 'assets/images/app_logo.png');

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('حدّ لفكّ الترميز يقي الذاكرة من صور الكاميرا الضخمة',
        (tester) async {
      await _openViewer(tester, 'assets/images/app_logo.png');

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<ResizeImage>());
    });

    testWidgets('زرّ إغلاق ظاهر يُغلق العارض', (tester) async {
      await _openViewer(tester, 'assets/images/app_logo.png');
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.text('افتح'), findsOneWidget);
    });
  });

  group('تعذّر تحميل الصورة', () {
    testWidgets('يُعرض بمكوّن الخطأ المشترك لا بألوان خام', (tester) async {
      await _openViewer(tester, 'assets/images/لا-وجود-لها.png');

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('تعذّر تحميل الصورة'), findsOneWidget);
      expect(find.text('إغلاق'), findsOneWidget);
    });

    testWidgets('زرّ الإغلاق في بطاقة الخطأ يُغلق العارض', (tester) async {
      await _openViewer(tester, 'assets/images/لا-وجود-لها.png');

      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorView), findsNothing);
      expect(find.text('افتح'), findsOneWidget);
    });

    testWidgets('زرّ الإغلاق لا يمتدّ بعرض الشاشة', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _openViewer(tester, 'assets/images/لا-وجود-لها.png');

      final width = tester.getSize(find.byType(ElevatedButton)).width;
      expect(width, lessThan(390 * 0.75));
    });
  });
}
