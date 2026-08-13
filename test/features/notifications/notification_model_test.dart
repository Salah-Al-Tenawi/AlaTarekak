import 'package:alatarekak/features/notifications/data/model/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// صف user_notification كما يرسله الخادم فعلاً: المحتوى متداخل تحت
/// notification، وحالة القراءة في read_at على الصف الخارجي — ولا وجود
/// لحقل is_read إطلاقاً.
Map<String, dynamic> _row({String? readAt}) => {
      'id': 101,
      'user_id': 5,
      'notification_id': 88,
      'read_at': readAt,
      'created_at': '2026-08-13T10:00:00.000000Z',
      'notification': {
        'id': 88,
        'title': 'Booking Accepted',
        'message': 'accepted your request for 2 seat(s).',
        'type': 'booking_accepted',
        'data': {'booking_id': 42, 'ride_id': 7},
      },
    };

void main() {
  group('NotificationModel — حالة القراءة (read_at)', () {
    test('read_at غير فارغ → مقروء', () {
      final n = NotificationModel.fromJson(
          _row(readAt: '2026-08-13T11:00:00.000000Z'));
      expect(n.isRead, isTrue);
    });

    test('read_at = null → غير مقروء', () {
      expect(NotificationModel.fromJson(_row()).isRead, isFalse);
    });

    test('غياب is_read لا يجعل المقروء يبدو غير مقروء', () {
      final row = _row(readAt: '2026-08-13T11:00:00.000000Z');
      expect(row.containsKey('is_read'), isFalse,
          reason: 'الخادم لا يرسل is_read — الاختبار يحرس هذا الافتراض');
      expect(NotificationModel.fromJson(row).isRead, isTrue);
    });

    test('كاش Hive المحلي (is_read) ما زال مقروءاً بعد رحلة toJson/fromJson',
        () {
      final original = NotificationModel.fromJson(
          _row(readAt: '2026-08-13T11:00:00.000000Z'));
      final restored = NotificationModel.fromJson(original.toJson());
      expect(restored.isRead, isTrue);
      expect(restored.id, 101);
    });
  });

  group('NotificationModel — المعرّفات والمحتوى المتداخل', () {
    test('المعرّف هو id لا notification_id', () {
      final n = NotificationModel.fromJson(_row());
      expect(n.id, 101);
    });

    test('العنوان والنوع يُقرآن من الكائن المتداخل', () {
      final n = NotificationModel.fromJson(_row());
      expect(n.type, 'booking_accepted');
      expect(n.message, contains('2 seat(s)'));
      expect(n.displayTitle, 'تم قبول حجزك');
    });

    test('حمولة الربط العميق تُفكَّك', () {
      final n = NotificationModel.fromJson(_row());
      expect(n.bookingId, 42);
      expect(n.rideId, 7);
    });
  });

  group('NotificationsPageModel — الترقيم المتداخل', () {
    test('العناصر تُقرأ من data.data لا من data', () {
      final page = NotificationsPageModel.fromJson({
        'success': true,
        'unread_count': 7,
        'data': {
          'current_page': 1,
          'last_page': 3,
          'total': 42,
          'data': [_row(), _row(readAt: '2026-08-13T11:00:00.000000Z')],
        },
      });

      expect(page.items, hasLength(2));
      expect(page.unreadCount, 7);
      expect(page.hasMore, isTrue);
      expect(page.items.first.isRead, isFalse);
      expect(page.items.last.isRead, isTrue);
    });
  });
}
