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
/// كان عدد الحجوزات لا يُعرض إطلاقاً، والمقاعد الصفرية تُكتب «مقاعد متاحة»
/// فتُقرأ إثباتاً على رحلة ممتلئة. هذه الاختبارات تقرأ نصّ البطاقة المرسوم.

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

  group('عدد الحجوزات يظهر على البطاقة', () {
    testWidgets('حجزان', (tester) async {
      await pumpCard(
          tester, _row(id: 2, availableSeats: 2, bookingsCount: 2));
      expect(find.text('حجزان'), findsOneWidget);
    });

    testWidgets('حجز واحد — لا «1 حجوزات»', (tester) async {
      await pumpCard(
          tester, _row(id: 4, availableSeats: 0, bookingsCount: 1));
      expect(find.text('حجز واحد'), findsOneWidget);
      expect(find.text('1 حجوزات'), findsNothing);
    });

    testWidgets('ثلاثة فأكثر بصيغة الجمع', (tester) async {
      await pumpCard(
          tester, _row(id: 5, availableSeats: 1, bookingsCount: 4));
      expect(find.text('4 حجوزات'), findsOneWidget);
    });

    testWidgets('لا حجوزات — تُكتب نفياً لا صفراً', (tester) async {
      await pumpCard(
          tester, _row(id: 3, availableSeats: 2, bookingsCount: 0));
      expect(find.text('لا حجوزات'), findsOneWidget);
      expect(find.text('0 حجوزات'), findsNothing);
    });
  });

  group('المقاعد المتاحة', () {
    testWidgets('الصفر يُصاغ نفياً صريحاً (الخطأ المُصلَح)', (tester) async {
      await pumpCard(tester,
          _row(id: 4, availableSeats: 0, bookingsCount: 1, status: 'full'));
      expect(find.text('لا مقاعد متاحة'), findsOneWidget);
      expect(find.text('مقاعد متاحة'), findsNothing,
          reason: 'النصّ وحده كان يُقرأ إثباتاً على رحلة ممتلئة');
    });

    testWidgets('مقعد واحد — لا «1 مقاعد»', (tester) async {
      await pumpCard(
          tester, _row(id: 6, availableSeats: 1, bookingsCount: 0));
      expect(find.text('مقعد واحد متاح'), findsOneWidget);
    });

    testWidgets('مقعدان بصيغة المثنّى', (tester) async {
      await pumpCard(
          tester, _row(id: 2, availableSeats: 2, bookingsCount: 2));
      expect(find.text('مقعدان متاحان'), findsOneWidget);
    });

    testWidgets('أربعة بصيغة الجمع', (tester) async {
      await pumpCard(
          tester, _row(id: 1, availableSeats: 4, bookingsCount: 0));
      expect(find.text('4 مقاعد متاحة'), findsOneWidget);
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
      expect(find.text('لا حجوزات'), findsOneWidget);
    });
  });

  group('بقية محتوى البطاقة', () {
    testWidgets('السعر والمسار والحالة تظهر', (tester) async {
      await pumpCard(
          tester, _row(id: 2, availableSeats: 2, bookingsCount: 2));

      expect(find.text('7,000 ل.س / راكب'), findsOneWidget);
      expect(find.textContaining('الفالوجة'), findsOneWidget);
      expect(find.text('السفارة الأرجنتينية'), findsOneWidget);
      expect(find.text('متاح'), findsOneWidget);
    });

    testWidgets('القائمة لا ترسل اسم السائق — تُعرض «رحلتي»', (tester) async {
      await pumpCard(
          tester, _row(id: 2, availableSeats: 2, bookingsCount: 2));
      expect(find.text('رحلتي'), findsOneWidget);
    });
  });
}
