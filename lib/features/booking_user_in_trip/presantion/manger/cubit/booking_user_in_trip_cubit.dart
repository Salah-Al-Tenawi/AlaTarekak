import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/repo/booking_users_in_trip_repo_imp.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'booking_user_in_trip_state.dart';

class BookingUserInTripCubit extends SafeCubit<BookingUserInTripState> {
  final BookingUsersInTripRepoImp repo;

  /// اختياري: بدونه يختفي زر مراسلة الراكب ويبقى الباقي يعمل.
  final ChatRepo? chatRepo;

  /// طلب فتح محادثة قيد التنفيذ — يمنع إنشاء محادثتين بضغطتين متتاليتين.
  bool _openingChat = false;

  BookingUserInTripCubit(this.repo, {this.chatRepo})
      : super(BookingUserInTripInitial());

  /// مراسلة الراكب — مسموحة فقط بعد تأكيد الحجز (الواجهة تفرض ذلك).
  ///
  /// الخادم يعيد المحادثة القائمة إن وُجدت بدل إنشاء ثانية، فضغط السائق
  /// والراكب معاً يوصلهما إلى المحادثة نفسها.
  Future<void> openChatWithPassenger({
    required int userId,
    String? name,
    String? avatar,
  }) async {
    if (chatRepo == null || _openingChat) return;
    _openingChat = true;

    final result = await chatRepo!.startConversation(userId: userId);
    _openingChat = false;
    if (isClosed) return;

    result.fold(
      (error) => emit(BookingUserInTripErorr(
          message: HandelErorrMessage.chat(error.message))),
      (conversationId) => emit(BookingUserInTripOpenConversation(
        conversationId: conversationId,
        title: name,
        avatar: avatar,
      )),
    );
  }

  Future<void> acceptPassanger(int bookingId) async {
    emit(BookingUserInTripLoading(bookingId: bookingId));

    final response = await repo.acceptPassanger(bookingId);
    response.fold(
      (error) => emit(BookingUserInTripErorr(
          message: HandelErorrMessage.acceptPassanger(error.message))),
      (succ) {
        emit(BookingUserInTripUpdated(
          bookingId: bookingId,
          statusRide: succ.statusRide,
        ));
      },
    );
  }

  Future<void> rejectPassanger(int bookingId) async {
    emit(BookingUserInTripLoading(bookingId: bookingId));

    final response = await repo.rejectPassanger(bookingId);
    response.fold(
      (error) => emit(BookingUserInTripErorr(
          message: HandelErorrMessage.rejectPassanger(error.message))),
      (raw) {
        // الرفض ينتج حالة "cancelled" — لا وجود لقيمة "rejected" في
        // enum الباك إند، وتلفيقها محلياً يجعل البطاقة تنقلب عند أول
        // مزامنة مع الخادم.
        emit(BookingUserInTripUpdated(
          bookingId: bookingId,
          statusRide: _statusFrom(raw, "cancelled"),
        ));
      },
    );
  }

  /// بلاغ السائق أن الراكب لم يحضر
  Future<void> passengerNoShow(int bookingId) async {
    emit(BookingUserInTripLoading(bookingId: bookingId));

    final response = await repo.passengerNoShow(bookingId);
    response.fold(
      (error) => emit(BookingUserInTripErorr(
          message: HandelErorrMessage.passengerNoShow(error.message))),
      // رد البلاغ لا يحمل كائن الحجز، والحالة الناتجة في الخادم هي
      // "no_show" وليست "passenger_no_show"
      (raw) => emit(BookingUserInTripUpdated(
        bookingId: bookingId,
        statusRide: _statusFrom(raw, "no_show"),
      )),
    );
  }

  /// حالة الحجز كما يعيدها الخادم داخل data.status. القيم الممكنة هي
  /// pending / confirmed / cancelled / no_show / completed — لا غيرها.
  String _statusFrom(dynamic response, String fallback) {
    if (response is Map) {
      final data = response['data'];
      if (data is Map) {
        final status = data['status'];
        if (status is String && status.isNotEmpty) return status;
      }
    }
    return fallback;
  }
}
