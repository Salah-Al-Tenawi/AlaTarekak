import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/utils/class/no_show_report.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/model/booking_user_modle.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/repo/booking_users_in_trip_repo_imp.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/manger/cubit/booking_user_in_trip_cubit.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingUsersInTripRepo extends Mock
    implements BookingUsersInTripRepoImp {}

class MockChatRepo extends Mock implements ChatRepo {}

void main() {
  late MockBookingUsersInTripRepo repo;

  setUp(() {
    repo = MockBookingUsersInTripRepo();
  });

  group('BookingUserInTripCubit — قبول راكب (للسائق)', () {
    blocTest<BookingUserInTripCubit, BookingUserInTripState>(
      'نجاح القبول: Updated بحالة الرحلة الجديدة',
      build: () {
        when(() => repo.acceptPassanger(7)).thenAnswer((_) async => right(
            BookingUserModle(
                message: 'ok', payment: true, statusRide: 'confirmed')));
        return BookingUserInTripCubit(repo);
      },
      act: (cubit) => cubit.acceptPassanger(7),
      expect: () => [
        isA<BookingUserInTripLoading>(),
        const BookingUserInTripUpdated(bookingId: 7, statusRide: 'confirmed'),
      ],
    );

    blocTest<BookingUserInTripCubit, BookingUserInTripState>(
      'فشل القبول من غير السائق: رسالة معرّبة',
      build: () {
        when(() => repo.acceptPassanger(any())).thenAnswer((_) async => left(
            const Filuar(
                message: 'Only the ride driver can accept bookings')));
        return BookingUserInTripCubit(repo);
      },
      act: (cubit) => cubit.acceptPassanger(7),
      expect: () => [
        isA<BookingUserInTripLoading>(),
        isA<BookingUserInTripErorr>()
            .having((s) => s.message, 'message', 'متاح لسائق الرحلة فقط'),
      ],
    );
  });

  group('BookingUserInTripCubit — رفض راكب', () {
    blocTest<BookingUserInTripCubit, BookingUserInTripState>(
      'نجاح الرفض: الحالة تُقرأ من رد الخادم (cancelled لا rejected)',
      build: () {
        when(() => repo.rejectPassanger(7)).thenAnswer((_) async => right({
              'success': true,
              'message': 'Booking rejected successfully',
              'data': {'id': 7, 'status': 'cancelled'},
            }));
        return BookingUserInTripCubit(repo);
      },
      act: (cubit) => cubit.rejectPassanger(7),
      expect: () => [
        isA<BookingUserInTripLoading>(),
        const BookingUserInTripUpdated(bookingId: 7, statusRide: 'cancelled'),
      ],
    );

    blocTest<BookingUserInTripCubit, BookingUserInTripState>(
      'رد بلا كائن حجز: تُستخدم cancelled احتياطياً — لا "rejected" الملفّقة',
      build: () {
        when(() => repo.rejectPassanger(7))
            .thenAnswer((_) async => right(null));
        return BookingUserInTripCubit(repo);
      },
      act: (cubit) => cubit.rejectPassanger(7),
      expect: () => [
        isA<BookingUserInTripLoading>(),
        const BookingUserInTripUpdated(bookingId: 7, statusRide: 'cancelled'),
      ],
    );

    blocTest<BookingUserInTripCubit, BookingUserInTripState>(
      'فشل الرفض لحجز غير معلق: رسالة معرّبة',
      build: () {
        when(() => repo.rejectPassanger(any())).thenAnswer((_) async => left(
            const Filuar(message: 'Only pending bookings can be rejected')));
        return BookingUserInTripCubit(repo);
      },
      act: (cubit) => cubit.rejectPassanger(7),
      expect: () => [
        isA<BookingUserInTripLoading>(),
        isA<BookingUserInTripErorr>().having((s) => s.message, 'message',
            'لا يمكن رفض هذا الحجز في حالته الحالية'),
      ],
    );
  });

  group('BookingUserInTripCubit — بلاغ عدم حضور الراكب', () {
    // البلاغ لم يعد تحديثَ بطاقةٍ صامتاً: له رسالة تُقال للسائق (مهلة
    // اعتراض، أو شكوى فُتحت عند التعارض)، والحالة `no_show` تصل مع
    // إعادة الجلب التي تُطلقها الشاشة.
    blocTest<BookingUserInTripCubit, BookingUserInTripState>(
      'نجاح البلاغ: نتيجة «مُبلَّغ» تذكر مهلة اعتراض الراكب',
      build: () {
        when(() => repo.passengerNoShow(7)).thenAnswer((_) async => right({
              'status': 'success',
              'message': 'No-show report submitted. The passenger has 2 '
                  'hours to dispute. If no dispute, the penalty is applied '
                  'automatically.',
            }));
        return BookingUserInTripCubit(repo);
      },
      act: (cubit) => cubit.passengerNoShow(7),
      expect: () => [
        isA<BookingUserInTripLoading>(),
        isA<BookingUserInTripNoShowReported>()
            .having((s) => s.bookingId, 'bookingId', 7)
            .having((s) => s.outcome, 'outcome', NoShowOutcome.reported)
            .having((s) => s.message, 'message', contains('ساعتان')),
      ],
    );

    blocTest<BookingUserInTripCubit, BookingUserInTripState>(
      'تعارض: يصل 200 كالنجاح، ويُقرأ من نصّه لا من رمزه',
      build: () {
        when(() => repo.passengerNoShow(7)).thenAnswer((_) async => right({
              'status': 'success',
              'message': 'Both parties filed a no-show report. A support '
                  'complaint has been opened automatically. No automatic '
                  'penalty will be applied — the support team will '
                  'investigate.',
            }));
        return BookingUserInTripCubit(repo);
      },
      act: (cubit) => cubit.passengerNoShow(7),
      expect: () => [
        isA<BookingUserInTripLoading>(),
        isA<BookingUserInTripNoShowReported>()
            .having((s) => s.outcome, 'outcome', NoShowOutcome.conflict)
            .having((s) => s.message, 'message', contains('شكوى')),
      ],
    );

    blocTest<BookingUserInTripCubit, BookingUserInTripState>(
      '«سبق أن أبلغت» يصل 422 وهو نجاح متأخّر لا خطأ',
      build: () {
        when(() => repo.passengerNoShow(7)).thenAnswer((_) async => left(
            const Filuar(
                message: 'You have already submitted a no-show report for '
                    'this booking.')));
        return BookingUserInTripCubit(repo);
      },
      act: (cubit) => cubit.passengerNoShow(7),
      expect: () => [
        isA<BookingUserInTripLoading>(),
        isA<BookingUserInTripNoShowReported>()
            .having((s) => s.outcome, 'outcome', NoShowOutcome.alreadyReported),
      ],
    );

    blocTest<BookingUserInTripCubit, BookingUserInTripState>(
      'فشل البلاغ قبل موعد الانطلاق: رسالة معرّبة',
      build: () {
        when(() => repo.passengerNoShow(any())).thenAnswer((_) async => left(
            const Filuar(
                message: 'Cannot report before the departure time')));
        return BookingUserInTripCubit(repo);
      },
      act: (cubit) => cubit.passengerNoShow(7),
      expect: () => [
        isA<BookingUserInTripLoading>(),
        isA<BookingUserInTripErorr>().having((s) => s.message, 'message',
            'لا يمكن الإبلاغ قبل موعد الانطلاق'),
      ],
    );
  });

  group('BookingUserInTripCubit — مراسلة الراكب (للسائق)', () {
    test('نجاح الفتح: حالة الانتقال إلى المحادثة ببيانات الراكب', () async {
      final chat = MockChatRepo();
      when(() => chat.startConversation(userId: any(named: 'userId')))
          .thenAnswer((_) async => right(9));

      final cubit = BookingUserInTripCubit(repo, chatRepo: chat);
      await cubit.openChatWithPassenger(
          userId: 15, name: 'أحمد علي', avatar: null);

      final state = cubit.state as BookingUserInTripOpenConversation;
      expect(state.conversationId, 9);
      expect(state.title, 'أحمد علي');
      verify(() => chat.startConversation(userId: 15)).called(1);
      await cubit.close();
    });

    test('ضغطتان متتاليتان لا تُنشئان محادثتين', () async {
      final chat = MockChatRepo();
      when(() => chat.startConversation(userId: any(named: 'userId')))
          .thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return right(9);
      });

      final cubit = BookingUserInTripCubit(repo, chatRepo: chat);
      // ضغطتان قبل عودة الطلب الأول
      await Future.wait([
        cubit.openChatWithPassenger(userId: 15),
        cubit.openChatWithPassenger(userId: 15),
      ]);

      verify(() => chat.startConversation(userId: 15)).called(1);
      await cubit.close();
    });

    test('فشل الفتح: رسالة معرّبة لا انتقال', () async {
      final chat = MockChatRepo();
      when(() => chat.startConversation(userId: any(named: 'userId')))
          .thenAnswer((_) async =>
              left(const Filuar(message: 'Conversation not found')));

      final cubit = BookingUserInTripCubit(repo, chatRepo: chat);
      await cubit.openChatWithPassenger(userId: 15);

      expect(cubit.state, isA<BookingUserInTripErorr>());
      expect((cubit.state as BookingUserInTripErorr).message,
          'المحادثة غير موجودة');
      await cubit.close();
    });

    test('بلا chatRepo: لا شيء يحدث ولا ينكسر شيء', () async {
      final cubit = BookingUserInTripCubit(repo);
      await cubit.openChatWithPassenger(userId: 15);
      expect(cubit.state, isA<BookingUserInTripInitial>());
      await cubit.close();
    });
  });
}
