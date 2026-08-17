import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/features/chat/data/model/conversation_model.dart';
import 'package:alatarekak/features/chat/data/model/message_model.dart';
import 'package:alatarekak/features/support/domain/entity/support_conversation.dart';
import 'package:flutter_test/flutter_test.dart';

/// ردّا الشات كما رصدناهما من الخادم فعلاً.
///
/// المهم فيهما: محادثة الدعم تصل بلا `other_participant` وبلا `title`،
/// و`last_message.created_at` نصّ نسبي **إنجليزي** بينما `updated_at`
/// تاريخ ISO سليم للحظة نفسها.

/// GET /api/chat/conversations
Map<String, dynamic> _conversationsResponse() => {
      'success': true,
      'data': [
        {
          'id': 203,
          'type': 'support',
          'title': null,
          'other_participant': null,
          'last_message': {
            'content': '...',
            'sender_name': 'صلاح',
            'created_at': '9 minutes ago',
          },
          'updated_at': '2026-08-17T00:18:09+00:00',
        },
        {
          'id': 202,
          'type': 'support',
          'title': null,
          'other_participant': null,
          'last_message': {
            'content': 'السلام عليكم',
            'sender_name': 'صلاح',
            'created_at': '9 minutes ago',
          },
          'updated_at': '2026-08-17T00:17:21+00:00',
        },
      ],
    };

/// GET /api/chat/conversations/202/messages?page=1
Map<String, dynamic> _messagesResponse() => {
      'success': true,
      'data': [
        {
          'id': 1435,
          'sender': {
            'id': 1001,
            'name': 'صلاح التيناوي',
            'profile_photo': null,
          },
          'type': 'text',
          'content': 'السلام عليكم',
          'metadata': [],
          'created_at': '2026-08-17T00:17:21+00:00',
          'is_edited': false,
        },
      ],
    };

List<ConversationModel> _conversations() =>
    (_conversationsResponse()['data'] as List)
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();

void main() {
  group('ConversationModel — محادثة الدعم بحقول فارغة', () {
    test('other_participant = null لا يرمي', () {
      final conv = _conversations().first;
      expect(conv.otherParticipant.id, 0);
      expect(conv.otherParticipant.name, isEmpty);
      expect(conv.otherParticipant.avatar, isNull);
    });

    test('title = null يصير نصاً فارغاً', () {
      expect(_conversations().first.title, isEmpty);
    });

    test('type = support يُلتقط فيُعرض «الدعم الفني»', () {
      for (final conv in _conversations()) {
        expect(SupportConversation.matches(conv), isTrue);
      }
    });

    test('غياب unread_count يسقط إلى صفر', () {
      expect(_conversations().first.unreadCount, 0);
    });

    test('المحتوى والمعرّفات تصل', () {
      expect(_conversations().map((c) => c.id).toList(), [203, 202]);
      expect(_conversations().last.lastMessage?.content, 'السلام عليكم');
    });
  });

  group('MessageModel — رد الرسائل', () {
    MessageModel first() => MessageModel.fromJson(
        (_messagesResponse()['data'] as List).first as Map<String, dynamic>);

    test('التاريخ ISO فيُعرض وقت الرسالة', () {
      expect(DateTime.tryParse(first().createdAt), isNotNull,
          reason: 'مسار الرسائل يرسل ISO لا نصاً نسبياً');
    });

    test('المرسِل والمحتوى يصلان', () {
      expect(first().sender.name, 'صلاح التيناوي');
      expect(first().sender.avatar, isNull);
      expect(first().content, 'السلام عليكم');
      expect(first().isEdited, isFalse);
    });

    test('metadata مصفوفة فارغة لا تُسقط التفكيك', () {
      expect(() => first(), returnsNormally);
    });

    test('غياب conversation_id يسقط إلى صفر بلا استثناء', () {
      expect(first().conversationId, 0);
    });
  });

  group('وقت بطاقة المحادثة — لا نصّ إنجليزي', () {
    test('يُفضَّل updated_at الـ ISO على النصّ النسبي (الخطأ المُصلَح)', () {
      final label = DateTimeUtils.chatListTime(
          ['2026-08-17T00:18:09+00:00', '9 minutes ago']);
      expect(label, isNot(contains('minutes')));
      expect(label, isNot(contains('ago')));
    });

    test('تاريخ اليوم يُعرض ساعةً ودقيقة', () {
      final now = DateTime.now();
      final label = DateTimeUtils.chatListTime([now.toIso8601String()]);
      expect(label, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('تاريخ سابق يُعرض يوماً/شهراً', () {
      final old = DateTime.now().subtract(const Duration(days: 40));
      expect(DateTimeUtils.chatListTime([old.toIso8601String()]),
          '${old.day}/${old.month}');
    });

    test('اليوم نفسه من شهر آخر ليس «اليوم»', () {
      // المقارنة القديمة كانت على dt.day وحده، فيوم ١٧ من أي شهر يُعدّ اليوم
      final lastMonth = DateTime.now().subtract(const Duration(days: 31));
      expect(DateTimeUtils.chatListTime([lastMonth.toIso8601String()]),
          contains('/'));
    });

    test('لا تاريخ صالح إطلاقاً → يُترجَم النصّ النسبي', () {
      expect(DateTimeUtils.chatListTime([null, '9 minutes ago']),
          'قبل 9 دقائق');
    });

    test('قائمة فارغة لا ترمي', () {
      expect(DateTimeUtils.chatListTime([null, '']), '');
    });
  });

  group('ترجمة الصيغ النسبية إلى العربية', () {
    test('المفرد', () {
      expect(DateTimeUtils.arabicRelative('1 minute ago'), 'قبل دقيقة');
      expect(DateTimeUtils.arabicRelative('an hour ago'), 'قبل ساعة');
      expect(DateTimeUtils.arabicRelative('a day ago'), 'قبل يوم');
    });

    test('المثنّى', () {
      expect(DateTimeUtils.arabicRelative('2 minutes ago'), 'قبل دقيقتين');
      expect(DateTimeUtils.arabicRelative('2 days ago'), 'قبل يومين');
    });

    test('جمع القلّة ٣–١٠', () {
      expect(DateTimeUtils.arabicRelative('9 minutes ago'), 'قبل 9 دقائق');
      expect(DateTimeUtils.arabicRelative('5 hours ago'), 'قبل 5 ساعات');
    });

    test('جمع الكثرة ١١+', () {
      expect(DateTimeUtils.arabicRelative('15 minutes ago'), 'قبل 15 دقيقة');
      expect(DateTimeUtils.arabicRelative('30 days ago'), 'قبل 30 يوماً');
    });

    test('كل الوحدات مغطّاة', () {
      for (final unit in const [
        'second',
        'minute',
        'hour',
        'day',
        'week',
        'month',
        'year',
      ]) {
        final out = DateTimeUtils.arabicRelative('4 ${unit}s ago');
        expect(out, startsWith('قبل '));
        expect(out, isNot(contains(unit)),
            reason: 'الوحدة «$unit» لم تُترجَم');
      }
    });

    test('«just now» تصير «الآن»', () {
      expect(DateTimeUtils.arabicRelative('just now'), 'الآن');
      expect(DateTimeUtils.arabicRelative('Just Now'), 'الآن');
    });

    test('about تُتجاهَل كبادئة', () {
      expect(DateTimeUtils.arabicRelative('about 3 hours ago'), 'قبل 3 ساعات');
    });

    test('صيغة مجهولة تُترك كما هي بلا ترجمة مخترَعة', () {
      expect(DateTimeUtils.arabicRelative('yesterday at noon'),
          'yesterday at noon');
    });
  });
}
