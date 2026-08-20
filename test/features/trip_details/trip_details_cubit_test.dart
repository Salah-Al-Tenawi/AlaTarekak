import 'dart:io';

import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
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

class MockChatRepo extends Mock implements ChatRepo {}

/// رد حجز مؤكَّد بشكل BookingResource الحقيقي (السائق متداخل تحت ride)
BookingResponse _confirmedBooking({String status = 'confirmed'}) =>
    BookingResponse.fromJson({
      'success': true,
      'message': 'Ride booked successfully',
      'data': {
        'id': 42,
        'ride_id': 7,
        'status': status,
        'seats': 2,
        'communication_number': '0912345678',
        'total_price': 50000,
        'created_at': '2026-08-13T12:00:00+03:00',
        'ride': {
          'id': 7,
          'pickup_address': 'دمشق',
          'destination_address': 'حمص',
          'departure_time': '2026-08-14T09:00:00+03:00',
          'driver': {'id': 3, 'name': 'سامر خليل', 'avatar': null},
        },
      },
    });

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

    // فتحُ رحلةٍ بصفة مجهولة (من إشعار) يُتبعه جلبٌ من مسار السائق متى
    // تبيّن أنها رحلة المستخدم نفسه — فيلزم الوسيطَ ردٌّ افتراضي، وإلا
    // أعاد `null` وسقط الاختبار على نوعٍ لا علاقة له بما يفحصه.
    when(() => repo.featchTripWithBookings(any()))
        .thenAnswer((_) async => right(fakeTrip(driverId: _myUserId)));
  });

  TripDetailsCubit buildCubit() => TripDetailsCubit(tripDetailsRepoIM: repo);

  group('TripDetailsCubit — الحجز', () {
    blocTest<TripDetailsCubit, TripDetailsState>(
      'نجاح حجز مقعد: Loading ثم RequestBooking',
      build: () {
        when(() => repo.booking(2, 5, '0999999999', any())).thenAnswer(
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
        when(() => repo.booking(any(), any(), any(), any())).thenAnswer(
            (_) async =>
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
        when(() => repo.booking(any(), any(), any(), any())).thenAnswer(
            (_) async => left(const Filuar(
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

    test('idempotency_key يبقى ثابتاً عبر إعادات المحاولة الفاشلة', () async {
      final keys = <String>[];
      when(() => repo.booking(any(), any(), any(), any())).thenAnswer((inv) async {
        keys.add(inv.positionalArguments[3] as String);
        return left(const Filuar(message: 'Not enough seats available'));
      });
      final cubit = buildCubit();

      await cubit.booking(2, 5, '0999999999');
      await cubit.booking(2, 5, '0999999999');

      expect(keys, hasLength(2));
      expect(keys.first, keys.last,
          reason: 'إعادة المحاولة يجب أن ترسل المفتاح نفسه وإلا نُشئ حجز مكرر');
      await cubit.close();
    });

    test('مفتاح جديد بعد نجاح الحجز (حجز لاحق ليس تكراراً)', () async {
      final keys = <String>[];
      when(() => repo.booking(any(), any(), any(), any())).thenAnswer((inv) async {
        keys.add(inv.positionalArguments[3] as String);
        return right(BookingResponse(success: true, message: 'ok'));
      });
      final cubit = buildCubit();

      await cubit.booking(2, 5, '0999999999');
      await cubit.booking(1, 5, '0999999999');

      expect(keys.first, isNot(keys.last));
      await cubit.close();
    });

    test('حجز مؤكَّد: يفتح محادثة مع السائق بلا إرسال تلقائي', () async {
      final chat = MockChatRepo();
      when(() => repo.booking(any(), any(), any(), any()))
          .thenAnswer((_) async => right(_confirmedBooking()));
      when(() => chat.startConversation(userId: any(named: 'userId')))
          .thenAnswer((_) async => right(77));

      final cubit = TripDetailsCubit(tripDetailsRepoIM: repo, chatRepo: chat);
      await cubit.booking(2, 7, '0912345678');

      final state = cubit.state as TripDetailsRequestBooking;
      expect(state.conversationId, 77);
      expect(state.driverName, 'سامر خليل');

      // المحادثة تُفتح مع السائق لا مع أي طرف آخر
      verify(() => chat.startConversation(userId: 3)).called(1);
      // الرسالة الافتتاحية تُكتب في حقل الإدخال والقرار للراكب —
      // لا تُرسَل من الكيوبت
      verifyNever(() => chat.sendTextMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
          ));
      await cubit.close();
    });

    test('حجز pending: لا محادثة — الحجز ما زال بانتظار موافقة السائق',
        () async {
      final chat = MockChatRepo();
      when(() => repo.booking(any(), any(), any(), any())).thenAnswer(
          (_) async => right(_confirmedBooking(status: 'pending')));

      final cubit = TripDetailsCubit(tripDetailsRepoIM: repo, chatRepo: chat);
      await cubit.booking(2, 7, '0912345678');

      expect((cubit.state as TripDetailsRequestBooking).conversationId, isNull);
      verifyNever(() => chat.startConversation(userId: any(named: 'userId')));
      await cubit.close();
    });

    test('فشل فتح المحادثة لا يُفشل الحجز', () async {
      final chat = MockChatRepo();
      when(() => repo.booking(any(), any(), any(), any()))
          .thenAnswer((_) async => right(_confirmedBooking()));
      when(() => chat.startConversation(userId: any(named: 'userId')))
          .thenAnswer((_) async => left(const Filuar(message: 'network down')));

      final cubit = TripDetailsCubit(tripDetailsRepoIM: repo, chatRepo: chat);
      await cubit.booking(2, 7, '0912345678');

      // الحجز ناجح، والمحادثة وحدها هي التي تعذّرت
      expect(cubit.state, isA<TripDetailsRequestBooking>());
      expect((cubit.state as TripDetailsRequestBooking).conversationId, isNull);
      verifyNever(() => chat.sendTextMessage(
            conversationId: any(named: 'conversationId'),
            content: any(named: 'content'),
          ));
      await cubit.close();
    });

    test('لكل رحلة مفتاحها الخاص', () async {
      final keys = <String>[];
      when(() => repo.booking(any(), any(), any(), any())).thenAnswer((inv) async {
        keys.add(inv.positionalArguments[3] as String);
        return left(const Filuar(message: 'Not enough seats available'));
      });
      final cubit = buildCubit();

      await cubit.booking(2, 5, '0999999999');
      await cubit.booking(2, 7, '0999999999');

      expect(keys.first, isNot(keys.last));
      await cubit.close();
    });
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
      'لا يُستدعى driver-confirm بعد finish إطلاقاً (الخادم يؤكّد تلقائياً)',
      build: () {
        when(() => repo.finishTrip(5)).thenAnswer((_) async => right(null));
        return buildCubit();
      },
      act: (cubit) => cubit.finishRide(5),
      wait: const Duration(milliseconds: 100),
      expect: () =>
          [isA<TripDetailsLoading>(), isA<TripDetailsFinishTrip>()],
      verify: (_) => verifyNever(() => repo.confirmTrip(any())),
    );

    blocTest<TripDetailsCubit, TripDetailsState>(
      'رحلة بلا ركّاب: 400 كاذب + الرحلة finished فعلاً → نجاح لا خطأ',
      build: () {
        when(() => repo.finishTrip(5)).thenAnswer((_) async =>
            left(const Filuar(message: 'Ride is not awaiting confirmation')));
        when(() => repo.featchTrip(5))
            .thenAnswer((_) async => right(fakeTrip(status: 'finished')));
        return buildCubit();
      },
      act: (cubit) => cubit.finishRide(5),
      wait: const Duration(milliseconds: 100),
      expect: () =>
          [isA<TripDetailsLoading>(), isA<TripDetailsFinishTrip>()],
    );

    blocTest<TripDetailsCubit, TripDetailsState>(
      'نفس الرسالة لكن الرحلة ليست finished → يبقى خطأ',
      build: () {
        when(() => repo.finishTrip(5)).thenAnswer((_) async =>
            left(const Filuar(message: 'Ride is not awaiting confirmation')));
        when(() => repo.featchTrip(5))
            .thenAnswer((_) async => right(fakeTrip(status: 'active')));
        return buildCubit();
      },
      act: (cubit) => cubit.finishRide(5),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<TripDetailsLoading>(),
        const TripDetailsError(message: 'الرحلة ليست بانتظار التأكيد'),
      ],
    );

    blocTest<TripDetailsCubit, TripDetailsState>(
      'فشل حقيقي (قبل موعد الانطلاق): رسالة معرّبة بلا إعادة جلب',
      build: () {
        when(() => repo.finishTrip(5)).thenAnswer((_) async => left(
            const Filuar(
                message: 'Cannot finish a ride before its departure time')));
        return buildCubit();
      },
      act: (cubit) => cubit.finishRide(5),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<TripDetailsLoading>(),
        const TripDetailsError(message: 'لا يمكن إنهاء الرحلة قبل موعد انطلاقها'),
      ],
      verify: (_) => verifyNever(() => repo.featchTrip(any())),
    );
  });

  // ---------------------------------------------------------------
  // إغلاق الشاشة والطلب في الطريق.
  //
  // المستخدم يفتح تفاصيل رحلة من نتائج البحث ثم يخرج بسرعة إلى تبويب
  // آخر. الشاشة تُغلَق ومعها الكيوبت، ثم يعود ردّ الخادم فيُستدعى
  // `emit` على كيوبت مُغلَق: StateError من مسار غير متزامن لا يلتقطه
  // أحد — «Cannot emit new states after calling close».
  //
  // لا يقع في كل مرة: يحتاج أن يسبق الإغلاقُ وصولَ الردّ، فيظهر
  // متقطّعاً ويصعب تكراره.
  // ---------------------------------------------------------------

  group('TripDetailsCubit — الخروج قبل وصول الرد', () {
    test('جلب الرحلة: الخروج أثناء الطلب لا يرمي', () async {
      when(() => repo.featchTrip(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return right(fakeTrip());
      });

      final cubit = TripDetailsCubit(tripDetailsRepoIM: repo);
      final pending = cubit.fetchTrip(7);

      await cubit.close(); // خرج المستخدم قبل وصول الرد
      await expectLater(pending, completes);
    });

    test('فشل الجلب بعد الخروج لا يرمي كذلك', () async {
      when(() => repo.featchTrip(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return left(const Filuar(message: 'Ride not found'));
      });

      final cubit = TripDetailsCubit(tripDetailsRepoIM: repo);
      final pending = cubit.fetchTrip(7);

      await cubit.close();
      await expectLater(pending, completes);
    });

    test('إنهاء الرحلة: الخروج أثناء الطلب لا يرمي', () async {
      when(() => repo.finishTrip(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return right(unit);
      });

      final cubit = TripDetailsCubit(tripDetailsRepoIM: repo);
      final pending = cubit.finishRide(7);

      await cubit.close();
      await expectLater(pending, completes);
    });

    test('الحجز: الخروج أثناء الطلب لا يرمي', () async {
      when(() => repo.booking(any(), any(), any(), any()))
          .thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return left(const Filuar(message: 'Not enough seats'));
      });

      final cubit = TripDetailsCubit(tripDetailsRepoIM: repo);
      final pending = cubit.booking(2, 7, '0988626577');

      await cubit.close();
      await expectLater(pending, completes);
    });

    test('البقاء في الشاشة يُصدر الحالة كالمعتاد', () async {
      when(() => repo.featchTrip(any()))
          .thenAnswer((_) async => right(fakeTrip()));

      final cubit = TripDetailsCubit(tripDetailsRepoIM: repo);
      await cubit.fetchTrip(7);

      expect(cubit.state, isA<TripDetailsLoaded>());
      await cubit.close();
    });
  });
}
