import 'dart:io';

import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/trip_details/data/model/booking_model.dart';
import 'package:alatarekak/features/trip_details/data/model/trip_details_mode.dart';
import 'package:alatarekak/features/trip_details/data/repo/trip_details_repo.dart';
import 'package:alatarekak/features/trip_details/presantaion/manger/cubit/tripdetails_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockTripDetailsRepo extends Mock implements TripDetailsRepoIM {}

/// معرف المستخدم الحالي المخزن في Hive — يحدد وضع الشاشة myView/otherView.
const int _myUserId = 1;

void main() {
  late MockTripDetailsRepo repo;
  late Directory tempDir;

  setUpAll(() async {
    // fetchTrip يقرأ myid() من صندوق الجلسة — نهيئ Hive مؤقتاً بجلسة حقيقية
    tempDir = await Directory.systemTemp.createTemp('trip_details_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    final box = await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
    await box.put(
      HiveKeys.user,
      const UserModel(
        id: _myUserId,
        firstName: 'يزن',
        lastName: 'صلاح',
        email: 'me@example.com',
        accessToken: 't',
        refreshToken: 'r',
      ),
    );
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // قفل ملفات مؤقت على ويندوز — غير مؤثر
    }
  });

  setUp(() {
    repo = MockTripDetailsRepo();
  });

  TripDetailsCubit buildCubit() => TripDetailsCubit(tripDetailsRepoIM: repo);

  group('TripDetailsCubit — الحجز', () {
    blocTest<TripDetailsCubit, TripDetailsState>(
      'نجاح حجز مقعد: Loading ثم RequestBooking',
      build: () {
        when(() => repo.booking(2, 5, '0999999999')).thenAnswer(
            (_) async => right(BookingResponse(success: true, message: 'ok')));
        return buildCubit();
      },
      act: (cubit) => cubit.booking(2, 5, '0999999999'),
      expect: () => [
        isA<TripDetailsLoading>(),
        isA<TripDetailsRequestBooking>()
            .having((s) => s.booking.success, 'success', isTrue),
      ],
    );

    blocTest<TripDetailsCubit, TripDetailsState>(
      'فشل الحجز لعدم كفاية المقاعد: رسالة معرّبة',
      build: () {
        when(() => repo.booking(any(), any(), any())).thenAnswer((_) async =>
            left(const Filuar(message: 'Not enough seats available')));
        return buildCubit();
      },
      act: (cubit) => cubit.booking(9, 5, '0999999999'),
      expect: () => [
        isA<TripDetailsLoading>(),
        const TripDetailsError(message: 'عدد المقاعد المتاحة غير كافٍ'),
      ],
    );

    blocTest<TripDetailsCubit, TripDetailsState>(
      'فشل الحجز في رحلة المستخدم نفسه: رسالة معرّبة',
      build: () {
        when(() => repo.booking(any(), any(), any())).thenAnswer((_) async =>
            left(const Filuar(
                message: 'Drivers cannot book their own rides')));
        return buildCubit();
      },
      act: (cubit) => cubit.booking(1, 5, '0999999999'),
      expect: () => [
        isA<TripDetailsLoading>(),
        const TripDetailsError(
            message: 'لا يمكنك حجز مقعد في رحلتك الخاصة'),
      ],
    );
  });

  group('TripDetailsCubit — وضع العرض (قاعدة العمل)', () {
    blocTest<TripDetailsCubit, TripDetailsState>(
      'الرحلة يقودها المستخدم الحالي → وضع myView (أزرار السائق)',
      build: () {
        when(() => repo.featchTrip(5))
            .thenAnswer((_) async => right(fakeTrip(driverId: _myUserId)));
        return buildCubit();
      },
      act: (cubit) => cubit.fetchTrip(5),
      expect: () => [
        isA<TripDetailsLoading>(),
        isA<TripDetailsLoaded>()
            .having((s) => s.mode, 'mode', TripDetailsMode.myView),
      ],
    );

    blocTest<TripDetailsCubit, TripDetailsState>(
      'الرحلة لسائق آخر → وضع otherView (أزرار الراكب)',
      build: () {
        when(() => repo.featchTrip(5))
            .thenAnswer((_) async => right(fakeTrip(driverId: 99)));
        return buildCubit();
      },
      act: (cubit) => cubit.fetchTrip(5),
      expect: () => [
        isA<TripDetailsLoading>(),
        isA<TripDetailsLoaded>()
            .having((s) => s.mode, 'mode', TripDetailsMode.otherView),
      ],
    );

    blocTest<TripDetailsCubit, TripDetailsState>(
      'رحلة غير موجودة: رسالة معرّبة',
      build: () {
        when(() => repo.featchTrip(any())).thenAnswer(
            (_) async => left(const Filuar(message: 'Ride not found')));
        return buildCubit();
      },
      act: (cubit) => cubit.fetchTrip(404),
      expect: () => [
        isA<TripDetailsLoading>(),
        const TripDetailsError(message: 'الرحلة غير موجودة'),
      ],
    );
  });

  group('TripDetailsCubit — إنهاء الرحلة (للسائق)', () {
    blocTest<TripDetailsCubit, TripDetailsState>(
      'نجاح الإنهاء',
      build: () {
        when(() => repo.finishTrip(5)).thenAnswer((_) async => right(null));
        return buildCubit();
      },
      act: (cubit) => cubit.finishRide(5),
      expect: () =>
          [isA<TripDetailsLoading>(), isA<TripDetailsFinishTrip>()],
    );

    blocTest<TripDetailsCubit, TripDetailsState>(
      'إنهاء + تأكيد: نجاح الاثنين → FinishTrip',
      build: () {
        when(() => repo.finishTrip(5)).thenAnswer((_) async => right(null));
        when(() => repo.confirmTrip(5)).thenAnswer((_) async => right(null));
        return buildCubit();
      },
      act: (cubit) => cubit.finishAndConfirmRide(5),
      wait: const Duration(milliseconds: 100),
      expect: () =>
          [isA<TripDetailsLoading>(), isA<TripDetailsFinishTrip>()],
    );

    blocTest<TripDetailsCubit, TripDetailsState>(
      'إنهاء + تأكيد: فشل التأكيد → رسالة معرّبة من خريطة driverConfirm',
      build: () {
        when(() => repo.finishTrip(5)).thenAnswer((_) async => right(null));
        when(() => repo.confirmTrip(5)).thenAnswer((_) async =>
            left(const Filuar(message: 'Ride already confirmed')));
        return buildCubit();
      },
      act: (cubit) => cubit.finishAndConfirmRide(5),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<TripDetailsLoading>(),
        const TripDetailsError(message: 'قمت بتأكيد هذه الرحلة مسبقاً'),
      ],
    );
  });
}
