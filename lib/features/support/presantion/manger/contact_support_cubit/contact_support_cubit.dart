import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/support/domain/repo/support_repo.dart';

part 'contact_support_state.dart';

class ContactSupportCubit extends Cubit<ContactSupportState> {
  final SupportRepo _repo;

  ContactSupportCubit(this._repo) : super(const ContactSupportInitial());

  /// POST /api/contact — يعمل حتى أثناء الحظر (قناة الاعتراض المصممة).
  /// 200 و201 يعاملان بنفس الطريقة: افتح الشات بـ conversationId.
  Future<void> openSupportChat() async {
    emit(const ContactSupportRequesting());
    final result = await _repo.openSupportChat();
    if (isClosed) return;

    result.fold(
      (failure) => emit(ContactSupportFailure(
          HandelErorrMessage.contactSupport(failure.message))),
      (chat) => emit(ContactSupportReady(
        conversationId: chat.conversationId,
        agentName: chat.agentName,
      )),
    );
  }
}
