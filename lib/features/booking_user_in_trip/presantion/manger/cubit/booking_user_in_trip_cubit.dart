import 'package:alatarekak/features/trip_create/data/model/booking_model.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/repo/booking_users_in_trip_repo_imp.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/core/service/no_show_report_store.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';
import 'package:alatarekak/core/utils/class/no_show_report.dart';

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
          message: error.arabic(HandelErorrMessage.chat))),
      (conversationId) => emit(BookingUserInTripOpenConversation(
        conversationId: conversationId,
        title: name,
        avatar: avatar,
      )),
    );
  }

  /// جلب الرحلة وحجوزاتها من المسار الموضوع لذلك.
  ///
  /// [silent] لإعادة الجلب بعد قبول أو رفض بلا وميض مؤشّر تحميل فوق
  /// قائمة معروضة أصلاً.
  Future<void> loadBookings(int rideId, {bool silent = false}) async {
    if (!silent) emit(BookingUserInTripFetching());

    final response = await repo.tripPassengers(rideId);
    response.fold(
      (error) {
        // فشل التحديث الصامت لا يمحو قائمة معروضة
        if (silent) return;
        // مُطابِق الرحلة لا الملف الشخصي: كان `showProfile` هنا، فلا
        // يُطابَق شيء ويسقط كل خطأ إلى «حدث خطأ غير متوقع» العامّة.
        emit(BookingUserInTripErorr(
            message: error.arabic(HandelErorrMessage.showOneRide)));
      },
      (trip) => emit(BookingUserInTripListLoaded(
        bookings: trip.booking,
        departure: trip.departure,
        rideStatus: trip.status,
      )),
    );
  }

  Future<void> acceptPassanger(int bookingId) async {
    emit(BookingUserInTripLoading(bookingId: bookingId));

    final response = await repo.acceptPassanger(bookingId);
    response.fold(
      (error) => emit(BookingUserInTripErorr(
          message: error.arabic(HandelErorrMessage.acceptPassanger))),
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
          message: error.arabic(HandelErorrMessage.rejectPassanger))),
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

  /// بلاغ السائق أن الراكب لم يحضر — **لكل حجز على حدة**، فلكل راكب حجزه.
  ///
  /// ثلاث نهايات لا واحدة، والخادم لا يميّزها بحقل: التعارض يصل **200
  /// كالنجاح** بنصّ مختلف، و«سبق الإبلاغ» يصل **422 كالخطأ** وهو في
  /// المعنى نجاح متأخّر — انظر [NoShowReport].
  Future<void> passengerNoShow(int bookingId) async {
    emit(BookingUserInTripLoading(bookingId: bookingId));

    final response = await repo.passengerNoShow(bookingId);
    if (isClosed) return;

    await response.fold((error) async {
      // الحالة المحلية تضيع بإعادة التثبيت أو الخروج، فيعود الزرّ ظاهراً
      // ويردّ الخادم «already submitted». ذلك ليس خطأً يُعرض بالأحمر.
      if (NoShowReport.isAlreadyReported(error.message)) {
        await NoShowReportStore.remember(
            NoShowReportStore.bookingKey(bookingId));
        if (isClosed) return;
        emit(BookingUserInTripNoShowReported(
          bookingId: bookingId,
          message: "سبق أن أبلغت عن هذا الراكب",
          outcome: NoShowOutcome.alreadyReported,
        ));
        return;
      }
      emit(BookingUserInTripErorr(
          message: error.arabic(HandelErorrMessage.passengerNoShow)));
    }, (raw) async {
      await NoShowReportStore.remember(
          NoShowReportStore.bookingKey(bookingId));
      if (isClosed) return;

      final conflict = NoShowReport.isConflict(raw);
      emit(BookingUserInTripNoShowReported(
        bookingId: bookingId,
        message: conflict
            ? "أبلغ الطرفان كلٌّ عن الآخر، فلا عقوبة تلقائية. فُتحت شكوى "
                "وسيتواصل معك فريق الدعم."
            : "تم تسجيل البلاغ. للراكب ساعتان للاعتراض، ثم يُحسم تلقائياً.",
        outcome: conflict ? NoShowOutcome.conflict : NoShowOutcome.reported,
      ));
    });
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

  /// تقييم الراكب، ومعه تعليق اختياري.
  ///
  /// **مساران لا واحد** — الخادم يفصل `rate` عن `comments`. وفشل التعليق
  /// لا يُفشل التقييم: النجوم وصلت فعلاً، وإظهار خطأ بعدها يوهم السائق
  /// أن شيئاً لم يقع فيعيد الكرّة — فيُقيَّم الراكب مرتين.
  Future<void> ratePassenger(
    double rating,
    int userId, {
    String? comment,
  }) async {
    emit(BookingUserInTripLoading(bookingId: userId));

    final response = await repo.rateUser(rating, userId);
    if (isClosed) return;

    await response.fold((error) async {
      // 409 «سبق أن قيّمت هذه الرحلة» خبرٌ لا عطل — انظر
      // [BookingUserInTripAlreadyRated]
      if (HandelErorrMessage.isAlreadyRated(error.message)) {
        emit(const BookingUserInTripAlreadyRated(
            message: HandelErorrMessage.alreadyRatedRide));
        return;
      }
      emit(BookingUserInTripErorr(
          message: error.arabic(HandelErorrMessage.rateUser)));
    }, (rate) async {
      final text = comment?.trim();
      if (text != null && text.isNotEmpty) {
        await repo.addcommit(text, userId);
        if (isClosed) return;
      }
      emit(BookingUserInTripRated(averageRating: rate.averageRating));
    });
  }
}
