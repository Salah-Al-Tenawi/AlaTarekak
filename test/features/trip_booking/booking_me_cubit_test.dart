import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/data/model/cancel_booking_model.dart';
import 'package:alatarekak/features/trip_booking/data/repo/booking_me_repo.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingMeRepo extends Mock implements BookingMeRepo {}

class MockChatRepo extends Mock implements ChatRepo {}

BookingMe _fakeBooking({int bookingId = 10}) => BookingMe(
      bookingId: bookingId,
      status: 'confirmed',
      seats: 2,
      totalPrice: 50000,
      bookingDate: DateTime(2026, 7, 1),
      passengerCommunicationNumber: '0999999999',
      driverCommunicationNumber: '0988888888',
      rideId: 5,
      pickupAddress: 'دمشق',
      destinationAddress: 'حمص',
      departureTime: DateTime(2026, 7, 15, 8),
      distanceKm: 160,
      durationMinutes: 120,
      pricePerSeat: 25000,
      paymentMethod: 'wallet',
      vehicleType: 'sedan',
      rideStatus: 'active',
      driverName: 'أحمد',
      driverRating: 4.5,
      driverAvatar: '',
      userDriver: 3,
    );

CancelBookingModel _fakeCancel() => CancelBookingModel.fromJson(const {
      'status': 'success',
      'message': 'Booking cancelled',
      'data': {
        'booking_id': 10,
        'seats_cancelled': 1,
        'remaining_seats': 1,
        'booking_status': 'partially_cancelled',
        'refund_policy': {
          'refund_percentage': 80.0,
          'refund_amount': 20000.0,
          'refund_processed': true,
        },
      },
    });

void main() {
  late MockBookingMeRepo repo;

  setUp(() {
    repo = MockBookingMeRepo();
  });

  group('BookingMeCubit — getMyBooking', () {
    blocTest<BookingMeCubit, BookingMeState>(
      'نجاح جلب الحجوزات: Listloading ثم ListLoaded بالقائمة',
      build: () {
        when(() => repo.getMeBooking())
            .thenAnswer((_) async => right([_fakeBooking()]));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.getMyBooking(),
      expect: () => [
        isA<BookingMeListloading>(),
        isA<BookingMeListLoaded>()
            .having((s) => s.bookings.length, 'عدد الحجوزات', 1)
            .having((s) => s.bookings.first.bookingId, 'bookingId', 10),
      ],
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'فشل جلب الحجوزات: رسالة الباك إند تُعرّب قبل عرضها',
      build: () {
        when(() => repo.getMeBooking()).thenAnswer((_) async =>
            left(const Filuar(
                message: 'You must be verified as a passenger')));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.getMyBooking(),
      expect: () => [
        isA<BookingMeListloading>(),
        isA<BookingMeErorr>()
            .having((s) => s.message, 'message', 'لم يتم توثيق الحساب'),
      ],
    );
  });

  group('BookingMeCubit — cancelBooking', () {
    blocTest<BookingMeCubit, BookingMeState>(
      'نجاح الإلغاء الجزئي: يمرر نموذج الاسترداد للحالة',
      build: () {
        when(() => repo.cancelBooking(10, 1))
            .thenAnswer((_) async => right(_fakeCancel()));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.cancelBooking(10, 1),
      expect: () => [
        isA<BookingMeloading>(),
        isA<BookingMeCanceled>().having(
            (s) => s.cancelModel.data.refundPolicy.refundPercentage,
            'نسبة الاسترداد',
            80.0),
      ],
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'فشل الإلغاء قبل أقل من ساعتين: رسالة معرّبة',
      build: () {
        when(() => repo.cancelBooking(any(), any())).thenAnswer((_) async =>
            left(const Filuar(
                message:
                    'Cannot cancel less than 2 hours before departure')));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.cancelBooking(10, 1),
      expect: () => [
        isA<BookingMeloading>(),
        isA<BookingMeErorr>().having((s) => s.message, 'message',
            'لا يمكن إلغاء الحجز قبل أقل من ساعتين من موعد الانطلاق'),
      ],
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'نجاح الإلغاء الكامل',
      build: () {
        when(() => repo.cancelWholeBooking(10))
            .thenAnswer((_) async => right(null));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.cancelWholeBooking(10),
      expect: () => [isA<BookingMeloading>(), isA<BookingMeWholeCanceled>()],
    );
  });

  group('BookingMeCubit — تأكيد وإبلاغ', () {
    blocTest<BookingMeCubit, BookingMeState>(
      'تأكيد إنهاء الرحلة من الراكب',
      build: () {
        when(() => repo.finshTrip(10)).thenAnswer((_) async => right(null));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.finishTrip(10),
      expect: () => [isA<BookingMeButtonloading>(), isA<BookingMeFinish>()],
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'تأكيد مكرر (ضغط مزدوج): نجاح صامت لا خطأ — الخادم يرده بحالة 500',
      build: () {
        when(() => repo.finshTrip(10)).thenAnswer((_) async =>
            left(const Filuar(message: 'You have already confirmed this ride')));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.finishTrip(10),
      expect: () => [isA<BookingMeButtonloading>(), isA<BookingMeFinish>()],
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'خطأ منطق عمل حقيقي بحالة 500: رسالة معرّبة لا "خطأ سيرفر"',
      build: () {
        when(() => repo.finshTrip(10)).thenAnswer((_) async => left(
            const Filuar(message: 'Ride is not awaiting confirmation')));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.finishTrip(10),
      expect: () => [
        isA<BookingMeButtonloading>(),
        isA<BookingMeErorr>().having((s) => s.message, 'message',
            'الرحلة ليست بانتظار التأكيد'),
      ],
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'بلاغ عدم حضور السائق: نجاح',
      build: () {
        when(() => repo.driverNoShow(5)).thenAnswer((_) async => right(null));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.reportDriverNoShow(5),
      expect: () => [
        isA<BookingMeButtonloading>(),
        isA<BookingMeDriverNoShowReported>(),
      ],
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'بلاغ عدم حضور السائق قبل موعد الانطلاق: رسالة معرّبة',
      build: () {
        when(() => repo.driverNoShow(any())).thenAnswer((_) async => left(
            const Filuar(
                message: 'Cannot report before the departure time')));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.reportDriverNoShow(5),
      expect: () => [
        isA<BookingMeButtonloading>(),
        isA<BookingMeErorr>().having((s) => s.message, 'message',
            'لا يمكن الإبلاغ قبل موعد الانطلاق'),
      ],
    );
  });

  group('BookingMeCubit — التقييم والتعليق', () {
    blocTest<BookingMeCubit, BookingMeState>(
      'نجاح التقييم: يمرر متوسط التقييم الجديد',
      build: () {
        when(() => repo.rateUser(4.0, 3)).thenAnswer((_) async => right(
            RatingModle(message: 'ok', totalRating: 12, averageRating: 4.3)));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.reateUser(4.0, 3),
      expect: () => [
        isA<BookingMeButtonloading>(),
        isA<BookingMeRated>().having((s) => s.rate, 'المتوسط', 4.3),
      ],
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'نجاح إضافة تعليق',
      build: () {
        when(() => repo.addcommit('رحلة ممتازة', 3)).thenAnswer((_) async =>
            right(const CommentEntity(
                iduser: 3,
                text: 'رحلة ممتازة',
                authorName: 'يزن',
                createdAt: '2026-07-10')));
        return BookingMeCubit(repo);
      },
      act: (cubit) => cubit.addComment('رحلة ممتازة', 3),
      expect: () =>
          [isA<BookingMeButtonloading>(), isA<BookingMeCommented>()],
    );
  });

  group('BookingMeModel — أشكال تغليف قائمة الحجوزات', () {
    Map<String, dynamic> booking() => {
          'id': 7,
          'seats': 2,
          'status': 'confirmed',
          'total_price': 14000,
          'ride': {
            'id': 2,
            'pickup_address': 'دمشق',
            'destination_address': 'حمص',
            'departure_time': '2026-08-16T13:55:00+03:00',
            'driver': {'id': 2, 'name': 'أحمد العظمة', 'rating': 0},
          },
        };

    test('قائمة مباشرة تحت data', () {
      final m = BookingMeModel.fromJson({'success': true, 'data': [booking()]});
      expect(m.data, hasLength(1));
      expect(m.data.single.bookingId, 7);
      expect(m.data.single.driverName, 'أحمد العظمة');
    });

    test('مُرقِّم Laravel تحت data.data لا يُقرأ فارغاً', () {
      final m = BookingMeModel.fromJson({
        'success': true,
        'data': {'current_page': 1, 'last_page': 1, 'data': [booking()]},
      });
      expect(m.data, hasLength(1),
          reason: 'الاشتراط على قائمة مباشرة كان يُظهر «لا حجوزات» لمن له حجز');
    });

    test('مفتاح bookings بدل data', () {
      final m = BookingMeModel.fromJson({
        'status': 'success',
        'bookings': [booking()],
      });
      expect(m.data, hasLength(1));
      expect(m.success, isTrue);
    });

    test('رد بلا قائمة يعطي فارغاً بلا انهيار', () {
      expect(BookingMeModel.fromJson({'success': true}).data, isEmpty);
    });
  });

  // ---------------------------------------------------------------
  // مراسلة السائق. سياسة التطبيق: لا محادثة بلا حجز — وكان الراكب الطرف
  // الوحيد بلا طريق إليها من قائمة حجوزاته، بينما للسائق زرّ مراسلة في
  // شاشة حجوزات رحلته.
  // ---------------------------------------------------------------

  group('BookingMeCubit — مراسلة السائق', () {
    late MockChatRepo chatRepo;

    setUp(() {
      chatRepo = MockChatRepo();
    });

    blocTest<BookingMeCubit, BookingMeState>(
      'فتح المحادثة يحمل معرّفها واسم السائق وصورته إلى الشاشة',
      build: () {
        when(() => chatRepo.startConversation(userId: 3))
            .thenAnswer((_) async => right(77));
        return BookingMeCubit(repo, chatRepo: chatRepo);
      },
      act: (cubit) => cubit.openChatWithDriver(
          userId: 3, name: 'أحمد', avatar: 'a.png'),
      expect: () => [
        isA<BookingMeOpenConversation>()
            .having((s) => s.conversationId, 'المحادثة', 77)
            .having((s) => s.title, 'العنوان', 'أحمد')
            .having((s) => s.avatar, 'الصورة', 'a.png'),
      ],
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'ضغطتان متتاليتان لا تُنشئان محادثتين',
      build: () {
        when(() => chatRepo.startConversation(userId: any(named: 'userId')))
            .thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return right(77);
        });
        return BookingMeCubit(repo, chatRepo: chatRepo);
      },
      act: (cubit) {
        cubit.openChatWithDriver(userId: 3);
        cubit.openChatWithDriver(userId: 3);
      },
      wait: const Duration(milliseconds: 80),
      verify: (_) {
        verify(() => chatRepo.startConversation(userId: 3)).called(1);
      },
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'فشل فتح المحادثة يُعرَّب ولا يصل بنصّ الخادم',
      build: () {
        when(() => chatRepo.startConversation(userId: any(named: 'userId')))
            .thenAnswer((_) async =>
                left(const Filuar(message: 'Conversation not found')));
        return BookingMeCubit(repo, chatRepo: chatRepo);
      },
      act: (cubit) => cubit.openChatWithDriver(userId: 3),
      expect: () => [
        isA<BookingMeErorr>()
            .having((s) => s.message, 'الرسالة', 'المحادثة غير موجودة')
            .having((s) => s.message, 'بلا إنجليزية',
                isNot(contains('Conversation'))),
      ],
    );

    blocTest<BookingMeCubit, BookingMeState>(
      'بلا chatRepo لا يقع شيء — بقية الشاشة تعمل',
      build: () => BookingMeCubit(repo),
      act: (cubit) => cubit.openChatWithDriver(userId: 3),
      expect: () => <BookingMeState>[],
    );
  });
}
