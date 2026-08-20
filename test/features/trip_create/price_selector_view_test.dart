import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/domin/ride_price_rules.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_select_price_and_booking_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// شاشة السعر: **نقترح ولا نُجبر**.
///
/// كان الرقم نصّاً لا يُلمس، وعدّاداً بلا سقف: من أراد سعراً بعيداً عن
/// المقترح ضغط عشرين ضغطة، ومن أراد رقماً غير مضاعفات الخطوة لم يجد
/// إليه سبيلاً. والآن: مقترح ظاهر، وعدّاد، وحقل يُكتب فيه — بشرط سقف
/// الكيلومتر.

/// المسافة ثابتة، والأرقام مشتقّة منها: تُغيَّر تسعيرة الكيلومتر في
/// [RidePriceRules] فتتبعها هذه التأكيدات بلا تحرير.
const double _km = 4.5;

final int _suggested = RidePriceRules.suggestedFor(_km);
final int _step = RidePriceRules.stepFor(_suggested);
final int _floor = RidePriceRules.minFor(_km);
final int _ceiling = RidePriceRules.maxFor(_km);
final String _suggestedRate =
    RidePriceRules.rateLabel(RidePriceRules.ratePerKm(_km, _suggested));

TripFrom _tripFrom() => TripFrom(distance: _km);

Future<TripFrom> _pump(WidgetTester tester, {TripFrom? from}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final trip = from ?? _tripFrom();

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        theme: ThemApp.lightThem,
        home: Directionality(
          textDirection: TextDirection.rtl,
          // في وضع المعالج تعود الخطوة بلا Scaffold — المعالج يوفّره
          child: Scaffold(
            body: TripSelectPriceAndBookingType(
              tripFrom: trip,
              onNext: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return trip;
}

Finder get _priceField => find.byType(TextField).first;

String _shownPrice(WidgetTester tester) =>
    tester.widget<TextField>(_priceField).controller!.text;

void main() {
  group('السعر المقترح', () {
    testWidgets('يظهر محسوباً على سعر الكيلومتر المقترح', (tester) async {
      await _pump(tester);

      expect(_shownPrice(tester), '$_suggested');
      expect(find.textContaining('$_suggestedRate ل.س للكيلومتر'),
          findsOneWidget);
    });

    testWidgets('يُقال للسائق إنه المقترح', (tester) async {
      await _pump(tester);

      expect(find.text('هذا هو السعر المقترح لرحلتك'), findsOneWidget);
    });

    testWidgets('سعر السائق المحفوظ لا يُكتب فوقه', (tester) async {
      final saved = _suggested - _step;
      final trip = _tripFrom()..price = saved;
      await _pump(tester, from: trip);

      expect(_shownPrice(tester), '$saved');
      expect(find.textContaining('السعر المقترح $_suggested'), findsOneWidget);
    });
  });

  group('العدّاد', () {
    testWidgets('الزيادة بخطوة واحدة', (tester) async {
      await _pump(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(_shownPrice(tester), '${_suggested + _step}');
    });

    testWidgets('النقصان بخطوة واحدة', (tester) async {
      await _pump(tester);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();

      expect(_shownPrice(tester), '${_suggested - _step}');
    });

    testWidgets('لا يتجاوز ±30٪ مهما ضُغط', (tester) async {
      final trip = await _pump(tester);

      for (var i = 0; i < 30; i++) {
        await tester.tap(find.byIcon(Icons.add_rounded));
      }
      await tester.pumpAndSettle();

      expect(trip.price, RidePriceRules.stepperRange(_km).max);
      expect(trip.price, lessThanOrEqualTo(RidePriceRules.maxFor(_km)));
    });

    testWidgets('«استعمله» يعيد المقترح', (tester) async {
      await _pump(tester);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text('استعمله'), findsOneWidget);

      await tester.tap(find.text('استعمله'));
      await tester.pumpAndSettle();

      expect(_shownPrice(tester), '$_suggested');
      expect(find.text('استعمله'), findsNothing);
    });
  });

  group('الكتابة اليدوية', () {
    testWidgets('سعر ضمن الحدود يُقبل ويُحفظ', (tester) async {
      final trip = await _pump(tester);

      final within = _floor + _step;
      await tester.enterText(_priceField, '$within');
      await tester.pumpAndSettle();

      expect(trip.price, within);
      expect(find.textContaining('أعلى سعر'), findsNothing);
    });

    testWidgets('سعر أعلى من المقترح بكثير يُقبل ما دام دون السقف',
        (tester) async {
      final trip = await _pump(tester);

      final justUnder = _ceiling - _step;
      await tester.enterText(_priceField, '$justUnder');
      await tester.pumpAndSettle();

      expect(trip.price, justUnder,
          reason: 'نقترح ولا نُجبر — ما دون السقف مقبول');
      expect(find.textContaining('أعلى سعر'), findsNothing);
    });

    testWidgets('تجاوز سقف الكيلومتر يُرفض بسببه', (tester) async {
      await _pump(tester);

      await tester.enterText(_priceField, '${_ceiling + _step}');
      await tester.pumpAndSettle();

      expect(find.textContaining('أعلى سعر لهذه الرحلة $_ceiling'),
          findsOneWidget);
      expect(
          find.textContaining(
              '${RidePriceRules.rateLabel(RidePriceRules.maxRatePerKm)} '
              'ل.س للكيلومتر'),
          findsOneWidget);
    });

    testWidgets('النزول تحت الأرضية يُرفض بسببه', (tester) async {
      await _pump(tester);

      await tester.enterText(_priceField, '${_floor - _step}');
      await tester.pumpAndSettle();

      expect(find.textContaining('أقلّ سعر لهذه الرحلة $_floor'),
          findsOneWidget);
    });

    testWidgets('الخطأ يزول بتصحيح الرقم', (tester) async {
      await _pump(tester);

      await tester.enterText(_priceField, '${_ceiling + _step}');
      await tester.pumpAndSettle();
      expect(find.textContaining('أعلى سعر'), findsOneWidget);

      await tester.enterText(_priceField, '$_suggested');
      await tester.pumpAndSettle();

      expect(find.textContaining('أعلى سعر'), findsNothing);
    });

    testWidgets('الحروف لا تُكتب أصلاً', (tester) async {
      await _pump(tester);

      await tester.enterText(_priceField, 'مئة');
      await tester.pumpAndSettle();

      expect(_shownPrice(tester), isEmpty);
    });
  });

  group('سعر الكيلومتر معروض دائماً', () {
    testWidgets('يتغيّر مع تغيّر السعر', (tester) async {
      await _pump(tester);
      expect(find.textContaining('$_suggestedRate ل.س للكيلومتر'),
          findsOneWidget);

      await tester.enterText(_priceField, '$_ceiling');
      await tester.pumpAndSettle();

      expect(
          find.textContaining(
              '${RidePriceRules.rateLabel(RidePriceRules.maxRatePerKm)} '
              'ل.س للكيلومتر'),
          findsOneWidget);
    });
  });
}
