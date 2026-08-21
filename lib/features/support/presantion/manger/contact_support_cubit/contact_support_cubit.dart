import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/support/domain/entity/support_conversation.dart';
import 'package:alatarekak/features/support/domain/repo/support_repo.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'contact_support_state.dart';

class ContactSupportCubit extends SafeCubit<ContactSupportState> {
  final SupportRepo _repo;

  ContactSupportCubit(this._repo) : super(const ContactSupportInitial());

  /// POST /api/contact — يعمل حتى أثناء الحظر (قناة الاعتراض المصممة).
  /// 200 و201 يعاملان بنفس الطريقة: افتح الشات بـ conversationId.
  Future<void> openSupportChat() async {
    emit(const ContactSupportRequesting());
    final result = await _repo.openSupportChat();
    if (isClosed) return;

    await result.fold(
      (failure) async => emit(ContactSupportFailure(
          failure.arabic(HandelErorrMessage.contactSupport))),
      (chat) async {
        // نحفظ المعرّف لتمييزها في قائمة المحادثات لاحقاً
        await SupportConversation.remember(chat.conversationId);
        if (isClosed) return;
        emit(ContactSupportReady(
          conversationId: chat.conversationId,
          agentName: chat.agentName,
        ));
      },
    );
  }
}
