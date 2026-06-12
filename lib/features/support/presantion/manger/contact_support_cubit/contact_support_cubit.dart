import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/support/domain/repo/support_repo.dart';

part 'contact_support_state.dart';

class ContactSupportCubit extends Cubit<ContactSupportState> {
  final SupportRepo _repo;

  ContactSupportCubit(this._repo) : super(const ContactSupportInitial());

  Future<void> requestAgent() async {
    emit(const ContactSupportRequesting());
    final result = await _repo.requestContactSupport();
    result.fold(
      (failure) => emit(ContactSupportFailure(failure.message)),
      (_) => emit(const ContactSupportAgentRequested()),
    );
  }
}
