import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/chat/domain/entity/conversation_entity.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/features/chat/presentation/manager/conversation_cubit/conversation_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepo extends Mock implements ChatRepo {}

/// شاشة المحادثات تعرض `state.message` في بطاقة الخطأ، وكان الكيوبت
/// يبثّها كما وصلت من الخادم — «Conversation not found» إنجليزية على شاشة
/// عربية بالكامل، رغم أن `HandelErorrMessage.chat` مكتوبة منذ البداية.

void main() {
  late MockChatRepo repo;

  setUp(() {
    repo = MockChatRepo();
  });

  group('ConversationCubit — قائمة المحادثات', () {
    blocTest<ConversationCubit, ConversationState>(
      'محادثة غير موجودة: رسالة عربية',
      build: () {
        when(() => repo.getConversations()).thenAnswer(
            (_) async => left(const Filuar(message: 'Conversation not found')));
        return ConversationCubit(chatRepo: repo);
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        isA<ConversationLoading>(),
        isA<ConversationError>()
            .having((s) => s.message, 'message', 'المحادثة غير موجودة')
            .having((s) => s.message, 'بلا إنجليزية',
                isNot(contains('Conversation'))),
      ],
    );

    blocTest<ConversationCubit, ConversationState>(
      'جلسة منتهية تُقال صراحةً',
      build: () {
        when(() => repo.getConversations()).thenAnswer(
            (_) async => left(const Filuar(message: 'Unauthenticated.')));
        return ConversationCubit(chatRepo: repo);
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        isA<ConversationLoading>(),
        isA<ConversationError>().having(
            (s) => s.message, 'message', HandelErorrMessage.errSession),
      ],
    );

    blocTest<ConversationCubit, ConversationState>(
      'نجاح: لا حالة خطأ أصلاً',
      build: () {
        when(() => repo.getConversations())
            .thenAnswer((_) async => right(<ConversationEntity>[]));
        return ConversationCubit(chatRepo: repo);
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        isA<ConversationLoading>(),
        isA<ConversationLoaded>(),
      ],
    );
  });

  group('ConversationCubit — فتح محادثة', () {
    blocTest<ConversationCubit, ConversationState>(
      'رفض الإرسال لغير مشارك: رسالة عربية',
      build: () {
        when(() => repo.startConversation(userId: any(named: 'userId')))
            .thenAnswer((_) async => left(const Filuar(
                message: 'You are not a participant in this conversation')));
        return ConversationCubit(chatRepo: repo);
      },
      act: (cubit) => cubit.startConversation(userId: 7),
      expect: () => [
        isA<ConversationLoading>(),
        isA<ConversationError>().having((s) => s.message, 'message',
            'لا يمكنك إرسال رسائل في هذه المحادثة'),
      ],
    );
  });
}
