import 'dart:io';

import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_me/presantion/view/widget/trip_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// بطاقة الرحلة في «رحلاتي» مبنيّة على صفّ `GET /api/rides` الحقيقي.
///
/// كان رأسها إطار صورة فارغاً وكلمة «رحلتي» — والسائق هنا هو المستخدم
/// نفسه دائماً، والخادم لا يرسل كائن `driver` في `GET /rides` أصلاً. صار
/// الرأس موعد الانطلاق: هو ما يميّز رحلة عن أخرى.
///
/// والأرقام صارت قيمةً فوق عنوان فئة بدل جمل تطابق العدد: «2 مقعدان»
/// تكرار، و«1 مقاعد» خطأ. هذه الاختبارات تقرأ نصّ البطاقة المرسوم.

/// صفّ خام واحد من القائمة — تُعدَّل منه الحقول موضع الاختبار.
Map<String, dynamic> _row({
  required int id,
  required int availableSeats,
  required int bookingsCount,
  String status = 'active',
  int distance = 7823,
  int duration = 582,
}) =>
    {
      'id': id,
      'driver_id': 2,
      'pickup_address': 'حي الفالوجة, اليرموك, محافظة دمشق, سوريا',
      'destination_address': 'السفارة الأرجنتينية',
      'pickup_location': {'lat': 33.476405, 'lng': 36.305053},
      'destination_location': {'lat': 33.520877, 'lng': 36.283538},
      'distance': distance,
      'duration': duration,
      'chosen_route_index': 0,
      // موعد بعيد في المستقبل: يُثبّت قسم الإجراءات فلا يتأرجح مع ساعة التشغيل
      'departure_time': '2030-01-01T11:00:00.000000Z',
      'available_seats': availableSeats,
      'price_per_seat': '7000.00',
      'vehicle_type': 'Toyota corolaa',
      'payment_method': 'e-pay',
      'booking_type': 'direct',
      'status': status,
      'notes': null,
      'communication_number': '+963988626577',
      'bookings_count': bookingsCount,
    };

void main() {
  late Directory tempDir;

  setUp(() async {
    // البطاقة تسأل myid() لتعرف إن كانت الرحلة للمستخدم الحالي
    tempDir = await Directory.systemTemp.createTemp('trip_item_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    final box = await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
    await box.put(
      HiveKeys.user,
      const UserModel(
        id: 2,
        firstName: 'أحمد',
        lastName: 'العظمة',
        email: 'driver@example.com',
        accessToken: 'token',
        refreshToken: 'refresh',
      ),
    );
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // ويندوز قد يبقي قفلاً قصيراً على الملف
    }
  });

  Future<void> pumpCard(WidgetTester tester, Map<String, dynamic> row) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: ItemTrip(trip: TripModel.fromMap(row)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('الأرقام: قيمة فوق عنوان فئة', () {
    testWidgets('الحجوزات تُعرض بعددها', (tester) async {
      await pumpCard(
          tester, _row(id: 2, availableSeats: 2, bookingsCount: 2));

      expect(find.text('2'), findsWidgets);
      expect(find.text('حجوزات مؤكَّدة'), findsOneWidget);
    });

    testWidgets('لا صياغة تطابق العدد — لا «1 حجوزات» ولا «حجزان»',
        (tester) async {
      await pumpCard(
          tester, _row(id: 4, availableSeats: 1, bookingsCount: 1));

      expect(find.textContaining('1 حجوزات'), findsNothing);
      expect(find.text('حجزان'), findsNothing);
      expect(find.text('حجوزات مؤكَّدة'), findsOneWidget);
    });

    testWidgets('صفر حجوزات يظهر رقماً صريحاً', (tester) async {
      await pumpCard(
          tester, _row(id: 3, availableSeats: 2, bookingsCount: 0));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('حجوزات مؤكَّدة'), findsOneWidget);
    });

    testWidgets('المقاعد كذلك: رقم فوق عنوانها', (tester) async {
      await pumpCard(
          tester, _row(id: 1, availableSeats: 4, bookingsCount: 0));

      expect(find.text('4'), findsOneWidget);
      expect(find.text('مقاعد متاحة'), findsOneWidget);
      expect(find.textContaining('4 مقاعد متاحة'), findsNothing,
          reason: 'الرقم صار قيمة مستقلّة فوق العنوان');
    });

    testWidgets('الرحلة الممتلئة: صفر ظاهر لا نصّ يُقرأ إثباتاً',
        (tester) async {
      await pumpCard(tester,
          _row(id: 4, availableSeats: 0, bookingsCount: 1, status: 'full'));

      // «مقاعد متاحة» وحدها كانت تُقرأ إثباتاً على رحلة ممتلئة —
      // الرقم فوقها يحسم المعنى
      expect(find.text('مقاعد متاحة'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('المسافة والمدّة', () {
    testWidgets('مسافة قصيرة بخانة عشرية ومدّة بالدقائق', (tester) async {
      await pumpCard(tester,
          _row(id: 3, availableSeats: 2, bookingsCount: 0)); // 7823م · 582ث
      expect(find.text('7.8 كم · 10 د'), findsOneWidget);
    });

    testWidgets('مسافة طويلة مقرَّبة ومدّة بالساعات', (tester) async {
      await pumpCard(
        tester,
        _row(
            id: 1,
            availableSeats: 4,
            bookingsCount: 0,
            distance: 47818,
            duration: 4500), // 75 دقيقة
      );
      expect(find.text('48 كم · 1 س 15 د'), findsOneWidget);
    });

    testWidgets('رحلة بلا مسافة لا تعرض رقاقة فارغة', (tester) async {
      await pumpCard(
        tester,
        _row(
            id: 7,
            availableSeats: 2,
            bookingsCount: 0,
            distance: 0,
            duration: 0),
      );
      expect(find.textContaining('كم ·'), findsNothing);
      // بقية البطاقة سليمة رغم غياب المسار
      expect(find.text('حجوزات مؤكَّدة'), findsOneWidget);
    });
  });

  group('بقية محتوى البطاقة', () {
    testWidgets('السعر والمسار والحالة تظهر', (tester) async {
      await pumpCard(
          tester, _row(id: 2, availableSeats: 2, bookingsCount: 2));

      expect(find.text('7,000 ل.س'), findsOneWidget);
      expect(find.text('للراكب الواحد'), findsOneWidget);
      expect(find.textContaining('الفالوجة'), findsOneWidget);
      expect(find.text('السفارة الأرجنتينية'), findsOneWidget);
      expect(find.text('متاح'), findsOneWidget);
    });
  });

  group('الرأس: الموعد لا صورة السائق', () {
    testWidgets('«رحلتي» لم تعد تُعرض', (tester) async {
      await pumpCard(
          tester, _row(id: 2, availableSeats: 2, bookingsCount: 2));

      expect(find.text('رحلتي'), findsNothing,
          reason: 'كلمة لا تميّز رحلة عن أخرى، وإلى جانبها إطار صورة فارغ');
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('يعرض يوم الانطلاق ورقمه وشهره وساعته', (tester) async {
      // 2030-01-01T11:00:00Z — الثلاثاء، أول كانون الثاني
      await pumpCard(
          tester, _row(id: 2, availableSeats: 2, bookingsCount: 2));

      expect(find.text('1'), findsWidgets);          // رقم اليوم
      expect(find.text('كانون الثاني'), findsOneWidget);
      expect(find.text('الثلاثاء'), findsOneWidget);
      expect(find.textContaining(':'), findsWidgets); // الساعة
    });

    testWidgets('بأسماء الشهور الشامية لا «يناير»', (tester) async {
      final row = _row(id: 9, availableSeats: 2, bookingsCount: 0);
      row['departure_time'] = '2030-07-15T08:30:00.000000Z';
      await pumpCard(tester, row);

      expect(find.text('تموز'), findsOneWidget);
      expect(find.text('يوليو'), findsNothing);
    });
  });

  group('إجراءات السائق: الإلغاء وحده (تغيّر المتطلبات)', () {
    /// موعد نسبيّ من الآن، فالبطاقة تقرأ ساعة النظام.
    Map<String, dynamic> _at(Duration fromNow, {String status = 'active'}) {
      final row = _row(id: 20, availableSeats: 2, bookingsCount: 1,
          status: status);
      row['departure_time'] =
          DateTime.now().toUtc().add(fromNow).toIso8601String();
      return row;
    }

    testWidgets('«إنهاء الرحلة» لم يعد موجوداً بحال', (tester) async {
      for (final d in [
        const Duration(hours: 3),
        const Duration(minutes: -5),
        const Duration(hours: -3),
      ]) {
        await pumpCard(tester, _at(d));
        expect(find.text('إنهاء الرحلة'), findsNothing,
            reason: 'السائق لم يعد يُنهي الرحلة — تكتمل بتأكيد الركّاب');
      }
    });

    testWidgets('قبل الانطلاق بساعتين: إلغاء متاح مع العدّ التنازلي',
        (tester) async {
      await pumpCard(tester, _at(const Duration(hours: 2)));

      expect(find.text('إلغاء'), findsOneWidget);
      expect(find.textContaining('متبقٍ'), findsOneWidget);
    });

    testWidgets('قبل الانطلاق بأربعين دقيقة: الإلغاء ما زال متاحاً',
        (tester) async {
      await pumpCard(tester, _at(const Duration(minutes: 40)));

      expect(find.text('إلغاء'), findsOneWidget,
          reason: 'لا مهلة مسبقة — أُلغيت بقرار صريح');
      expect(find.textContaining('متبقٍ'), findsOneWidget);
    });

    testWidgets('قبل الانطلاق بدقيقتين: الإلغاء متاح', (tester) async {
      await pumpCard(tester, _at(const Duration(minutes: 2)));

      expect(find.text('إلغاء'), findsOneWidget);
    });

    testWidgets('لا أثر لتنبيه إغلاق باب الإلغاء بحال', (tester) async {
      for (final d in [
        const Duration(hours: 5),
        const Duration(minutes: 40),
        const Duration(minutes: 2),
      ]) {
        await pumpCard(tester, _at(d));
        expect(find.textContaining('أُغلق باب الإلغاء'), findsNothing);
      }
    });

    testWidgets('رحلة مكتملة المقاعد: الإلغاء متاح كغيرها', (tester) async {
      await pumpCard(
          tester, _at(const Duration(hours: 2), status: 'full'));

      expect(find.text('إلغاء'), findsOneWidget,
          reason: 'اكتمال المقاعد لا يسلب السائق حقّ الإلغاء قبل الموعد');
    });

    testWidgets('بعد الانطلاق: لا إجراء ولا عدّ', (tester) async {
      await pumpCard(tester, _at(const Duration(minutes: -20)));

      expect(find.text('إلغاء'), findsNothing);
      expect(find.textContaining('متبقٍ'), findsNothing);
      expect(find.text('إنهاء الرحلة'), findsNothing);
    });

    testWidgets('رحلة ملغاة: لا أزرار', (tester) async {
      await pumpCard(
          tester, _at(const Duration(hours: 5), status: 'cancelled'));

      expect(find.text('إلغاء'), findsNothing);
    });

    testWidgets('رحلة منتهية: لا أزرار', (tester) async {
      await pumpCard(
          tester, _at(const Duration(hours: 5), status: 'finished'));

      expect(find.text('إلغاء'), findsNothing);
    });

    testWidgets('حالة لا نعرفها: يُسمح بالإلغاء والخادم يحسم (الخطأ المُصلَح)',
        (tester) async {
      await pumpCard(
          tester, _at(const Duration(hours: 5), status: 'scheduled'));

      expect(find.text('إلغاء'), findsOneWidget,
          reason: 'كان الشرط يسمح لـ active وحدها، فتبتلع أي حالة جديدة '
              'كلّ الإجراءات بصمت');
    });

    testWidgets('حالة بحروف كبيرة أو مسافات لا تُخفي الزرّ', (tester) async {
      await pumpCard(
          tester, _at(const Duration(hours: 5), status: ' Active '));

      expect(find.text('إلغاء'), findsOneWidget);
    });

    testWidgets('رحلة السائق نفسه بلا كائن driver: الإجراءات تظهر',
        (tester) async {
      // `GET /rides` يرسل `driver_id` مفرداً لا كائن `driver` — وكان
      // شرط `trip.driver.id == myid()` يبتلع كلّ الإجراءات متى اختلّ
      final row = _at(const Duration(hours: 5));
      row.remove('driver_id');
      await pumpCard(tester, row);

      expect(find.text('إلغاء'), findsOneWidget,
          reason: 'هذه شاشة «رحلاتي» — كل رحلة فيها للمستخدم بالتعريف');
    });
  });
}
