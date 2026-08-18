import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/widget/trip_details_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// خطأ شاشة تفاصيل الرحلة.
///
/// المهم هنا ليس الشكل بل **الإجراء المعروض**: من فشل حجزه لنقص الرصيد
/// كان يرى زرّ «أعد المحاولة» وحده — وإعادة المحاولة برصيد لم يتغيّر
/// تعيد الخطأ نفسه إلى ما لا نهاية.

const String _lowBalance = 'رصيد محفظتك غير كافٍ لإتمام الحجز';
const String _otherError = 'هذه الرحلة لم تعد متاحة للحجز';

Future<void> _pump(
  WidgetTester tester, {
  required String message,
  VoidCallback? onRetry,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => GetMaterialApp(
        theme: ThemApp.lightThem,
        getPages: [
          GetPage(
            name: RouteName.wallet,
            page: () => const Scaffold(body: Text('شاشة المحفظة')),
          ),
        ],
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: TripDetailsErrorView(
              message: message,
              onRetry: onRetry ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('كشف نقص الرصيد', () {
    test('الرسالة المعرّبة تُميَّز', () {
      expect(HandelErorrMessage.isInsufficientBalance(_lowBalance), isTrue);
      expect(
        HandelErorrMessage.isInsufficientBalance(
            'رصيد محفظتك لا يكفي رسوم إنشاء الرحلة، اشحن محفظتك ثم أعد المحاولة'),
        isTrue,
      );
    });

    test('بقية الأخطاء لا تُصنَّف نقص رصيد', () {
      expect(HandelErorrMessage.isInsufficientBalance(_otherError), isFalse);
      expect(
        HandelErorrMessage.isInsufficientBalance('عدد المقاعد المتاحة غير كافٍ'),
        isFalse,
        reason: '«غير كافٍ» وحدها لا تعني الرصيد',
      );
    });
  });

  group('نقص الرصيد — الإجراء المفيد أولاً', () {
    testWidgets('يعرض «اشحن محفظتي» و«أعد المحاولة» معاً', (tester) async {
      await _pump(tester, message: _lowBalance);

      expect(find.text('اشحن محفظتي'), findsOneWidget);
      expect(find.text('أعد المحاولة'), findsOneWidget);
      expect(find.text('رصيدك لا يكفي'), findsOneWidget);
      expect(find.text(_lowBalance), findsOneWidget);
    });

    testWidgets('الشحن هو الزرّ الأساسي لا الثانوي', (tester) async {
      await _pump(tester, message: _lowBalance);

      expect(
        find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.text('اشحن محفظتي'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(OutlinedButton),
          matching: find.text('أعد المحاولة'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('أيقونة المحفظة لا أيقونة العطل', (tester) async {
      await _pump(tester, message: _lowBalance);

      expect(find.byIcon(Icons.account_balance_wallet_outlined),
          findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('الضغط على «اشحن محفظتي» ينقل إلى المحفظة فعلاً',
        (tester) async {
      await _pump(tester, message: _lowBalance);

      await tester.tap(find.text('اشحن محفظتي'));
      await tester.pumpAndSettle();

      expect(find.text('شاشة المحفظة'), findsOneWidget);
      expect(Get.currentRoute, RouteName.wallet);
    });

    testWidgets('و«أعد المحاولة» الثانوي يعيد الطلب', (tester) async {
      var retries = 0;
      await _pump(
        tester,
        message: _lowBalance,
        onRetry: () => retries++,
      );

      await tester.tap(find.text('أعد المحاولة'));
      await tester.pump();

      expect(retries, 1);
    });
  });

  group('بقية الأخطاء', () {
    testWidgets('«أعد المحاولة» وحدها، بلا زرّ شحن', (tester) async {
      await _pump(tester, message: _otherError);

      expect(find.text('أعد المحاولة'), findsOneWidget);
      expect(find.text('اشحن محفظتي'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('الرسالة تُعرض كما هي بلا بادئة «خطأ:»', (tester) async {
      await _pump(tester, message: _otherError);

      expect(find.text(_otherError), findsOneWidget);
      expect(find.textContaining('خطأ:'), findsNothing);
    });

    testWidgets('الضغط يعيد الطلب', (tester) async {
      var retries = 0;
      await _pump(tester, message: _otherError, onRetry: () => retries++);

      await tester.tap(find.text('أعد المحاولة'));
      await tester.pump();

      expect(retries, 1);
    });
  });
}
