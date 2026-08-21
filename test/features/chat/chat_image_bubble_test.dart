import 'package:alatarekak/features/chat/presentation/view/widget/chat_image_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// صورة المحادثة.
///
/// عيبان ظهرا في الاستعمال:
///
///   ١. **بلا سقف لارتفاعها** — `Image.network` بعرضٍ وحده يُبقي نسبة
///      الصورة، فصورةٌ طولية من كاميرا الهاتف تصير فقاعةً أطول من
///      الشاشة.
///   ٢. **لا تُفتح** — لا شيء يستجيب للمسها، ومن أراد قراءة رقمٍ فيها
///      لم يجد سبيلاً.
void main() {
  const screen = Size(375, 812);

  Future<void> pump(
    WidgetTester tester, {
    String? caption,
    void Function(String url)? onOpen,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: screen,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Align(
                alignment: Alignment.topRight,
                child: ChatImageBubble(
                  // صورة لا تُحمَّل في الاختبار: يبقى مكانها والقياس عليه
                  imageUrl: 'https://example.com/tall.jpg',
                  isMe: true,
                  caption: caption,
                  onOpen: onOpen,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('حجمها محكوم', () {
    testWidgets('لا تتجاوز ثلث الشاشة ارتفاعاً', (tester) async {
      await pump(tester);

      final box = tester.getSize(find.byType(ChatImageBubble));

      expect(box.height,
          lessThanOrEqualTo(screen.height * ChatImageBubble.maxHeightFactor),
          reason: 'كانت الصورة الطولية تصير فقاعة أطول من الشاشة');
    });

    testWidgets('ولا تتجاوز ثلثي العرض', (tester) async {
      await pump(tester);

      expect(tester.getSize(find.byType(ChatImageBubble)).width,
          lessThanOrEqualTo(screen.width * 0.62));
    });

    testWidgets('والتعليق يبقى تحتها', (tester) async {
      await pump(tester, caption: 'هذه نقطة اللقاء');

      expect(find.text('هذه نقطة اللقاء'), findsOneWidget);
    });
  });

  group('تُفتح باللمس — ما لم يكن موجوداً', () {
    testWidgets('الضغط يفتح العارض بالرابط نفسه', (tester) async {
      String? opened;
      await pump(tester, onOpen: (url) => opened = url);

      await tester.tap(find.byType(ChatImageBubble));
      await tester.pump();

      expect(opened, 'https://example.com/tall.jpg');
    });

    testWidgets('وعليها دلالة تُنبئ بأنها تُلمس', (tester) async {
      await pump(tester);

      expect(find.byIcon(Icons.zoom_out_map_rounded), findsOneWidget,
          reason: 'الصورة الساكنة لا تُنبئ بأنها تُفتح');
    });
  });
}
