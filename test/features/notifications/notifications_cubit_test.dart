import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/notifications/domain/entity/notification_entity.dart';
import 'package:alatarekak/features/notifications/domain/repo/notifications_repo.dart';
import 'package:alatarekak/features/notifications/presantion/manger/cubit/notifications_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationsRepo extends Mock implements NotificationsRepo {}

NotificationEntity _n(int id, {bool isRead = false}) => NotificationEntity(
      id: id,
      title: 'إشعار $id',
      message: 'نص الإشعار',
      category: 'ride',
      isRead: isRead,
    );

/// إشعار غياب بنوعه وكيانه — لاختبار إزالة التكرار.
NotificationEntity _noShow(
  int id,
  String type, {
  int? bookingId,
  int? rideId,
  bool isRead = false,
}) =>
    NotificationEntity(
      id: id,
      title: 'إشعار $id',
      message: 'نص الإشعار',
      category: 'ride',
      type: type,
      isRead: isRead,
      data: {
        if (bookingId != null) 'booking_id': bookingId,
        if (rideId != null) 'ride_id': rideId,
      },
    );

NotificationsPageEntity _page({
  List<NotificationEntity>? items,
  int unread = 1,
  int currentPage = 1,
  int lastPage = 1,
}) =>
    NotificationsPageEntity(
      items: items ?? [_n(1), _n(2, isRead: true)],
      currentPage: currentPage,
      lastPage: lastPage,
      total: items?.length ?? 2,
      unreadCount: unread,
    );

void main() {
  late MockNotificationsRepo repo;

  setUp(() {
    repo = MockNotificationsRepo();
    when(() => repo.cacheFirstPage(any(), any()))
        .thenAnswer((_) async {});
  });

  void stubNetwork(NotificationsPageEntity page) {
    when(() => repo.getNotifications(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
          category: any(named: 'category'),
          isRead: any(named: 'isRead'),
        )).thenAnswer((_) async => right(page));
  }

  group('NotificationsCubit — التحميل', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'بلا كاش: Loading ثم Loaded من الشبكة',
      build: () {
        when(() => repo.getCachedFirstPage()).thenReturn(null);
        stubNetwork(_page(unread: 1));
        return NotificationsCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.length, 'العدد', 2)
            .having((s) => s.unreadCount, 'غير المقروء', 1),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'مع كاش: يعرض الكاش فوراً ثم يحدّث من الشبكة (بلا شاشة تحميل)',
      build: () {
        when(() => repo.getCachedFirstPage()).thenReturn(_page(unread: 3));
        stubNetwork(_page(unread: 1));
        return NotificationsCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.unreadCount, 'من الكاش', 3),
        isA<NotificationsLoaded>()
            .having((s) => s.unreadCount, 'من الشبكة', 1),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'فشل الشبكة بلا كاش: NotificationsError برسالة معرّبة',
      build: () {
        when(() => repo.getCachedFirstPage()).thenReturn(null);
        when(() => repo.getNotifications(
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
              category: any(named: 'category'),
              isRead: any(named: 'isRead'),
            )).thenAnswer(
            (_) async => left(const Filuar(message: 'Server error')));
        return NotificationsCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsError>().having(
            (s) => s.message, 'message', HandelErorrMessage.errServer),
      ],
    );
  });

  group('NotificationsCubit — التحديث التفاؤلي', () {
    blocTest<NotificationsCubit, NotificationsState>(
      'markRead: يعلّم الإشعار مقروءاً وينقص العداد فوراً ثم يحفظ الكاش',
      build: () {
        when(() => repo.getCachedFirstPage()).thenReturn(null);
        stubNetwork(_page(unread: 1));
        when(() => repo.markRead(1)).thenAnswer((_) async => right(null));
        return NotificationsCubit(repo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.markRead(1);
      },
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsLoaded>().having((s) => s.unreadCount, 'قبل', 1),
        isA<NotificationsLoaded>()
            .having((s) => s.unreadCount, 'بعد', 0)
            .having((s) => s.notifications.first.isRead, 'مقروء', isTrue),
      ],
      verify: (_) {
        verify(() => repo.markRead(1)).called(1);
        verify(() => repo.cacheFirstPage(any(), any())).called(1);
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'deleteNotification: يحذف من القائمة فوراً ويحدّث الكاش',
      build: () {
        when(() => repo.getCachedFirstPage()).thenReturn(null);
        stubNetwork(_page(unread: 1));
        when(() => repo.deleteNotification(1))
            .thenAnswer((_) async => right(null));
        return NotificationsCubit(repo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.deleteNotification(1);
      },
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.length, 'قبل الحذف', 2),
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.length, 'بعد الحذف', 1)
            .having((s) => s.unreadCount, 'العداد', 0),
      ],
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'markAllRead: يعلّم الكل ويصفّر العداد من رد الخادم',
      build: () {
        when(() => repo.getCachedFirstPage()).thenReturn(null);
        stubNetwork(_page(unread: 1));
        when(() => repo.markAllRead()).thenAnswer((_) async => right(0));
        return NotificationsCubit(repo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.markAllRead();
      },
      expect: () => [
        isA<NotificationsLoading>(),
        isA<NotificationsLoaded>(),
        isA<NotificationsLoaded>()
            .having((s) => s.unreadCount, 'العداد', 0)
            .having((s) => s.notifications.every((n) => n.isRead),
                'الكل مقروء', isTrue),
      ],
    );
  });

  group('NotificationsCubit — تكرار إشعارات الغياب', () {
    // الخادم يرسل إشعارين لكل بلاغ: واحداً من الخدمة وآخر من الكونترولر،
    // برقمين مختلفين وعن الحدث نفسه.
    List<NotificationEntity> twinPair() => [
          _noShow(20, 'noshow_driver_reported_you', bookingId: 7),
          _noShow(21, 'no_show_recorded', bookingId: 7),
        ];

    blocTest<NotificationsCubit, NotificationsState>(
      'التوأمان يُعرضان واحداً',
      build: () {
        when(() => repo.getCachedFirstPage()).thenReturn(null);
        stubNetwork(_page(items: twinPair(), unread: 2));
        return NotificationsCubit(repo);
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        final state = cubit.state as NotificationsLoaded;
        expect(state.notifications.length, 1);
        expect(state.notifications.single.id, 20, reason: 'الأحدث يبقى');
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'بلاغان على حجزين مختلفين يبقيان اثنين',
      build: () {
        when(() => repo.getCachedFirstPage()).thenReturn(null);
        stubNetwork(_page(items: [
          _noShow(20, 'noshow_driver_reported_you', bookingId: 7),
          _noShow(21, 'noshow_driver_reported_you', bookingId: 8),
        ], unread: 2));
        return NotificationsCubit(repo);
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect((cubit.state as NotificationsLoaded).notifications.length, 2);
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'الإشعارات العادية لا تُمَسّ',
      build: () {
        when(() => repo.getCachedFirstPage()).thenReturn(null);
        stubNetwork(_page(items: [_n(1), _n(2), _n(3)], unread: 3));
        return NotificationsCubit(repo);
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect((cubit.state as NotificationsLoaded).notifications.length, 3);
      },
    );

    blocTest<NotificationsCubit, NotificationsState>(
      'قراءة الظاهر تُعلّم التوأم المخفيّ — وإلا علق العدّاد على رقم لا يُرى',
      build: () {
        when(() => repo.getCachedFirstPage()).thenReturn(null);
        stubNetwork(_page(items: twinPair(), unread: 2));
        when(() => repo.markRead(any())).thenAnswer((_) async => right(null));
        return NotificationsCubit(repo);
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.markRead(20);
      },
      verify: (cubit) {
        expect((cubit.state as NotificationsLoaded).unreadCount, 0);
        verify(() => repo.markRead(20)).called(1);
        verify(() => repo.markRead(21)).called(1);
      },
    );
  });
}
