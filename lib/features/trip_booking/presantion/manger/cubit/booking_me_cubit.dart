import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/data/model/cancel_booking_model.dart';
import 'package:alatarekak/features/trip_booking/data/repo/booking_me_repo.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/core/service/no_show_report_store.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';
import 'package:alatarekak/core/utils/class/no_show_report.dart';

part 'booking_me_state.dart';

class BookingMeCubit extends SafeCubit<BookingMeState> {
  final BookingMeRepo _repo;

  /// اختياري: بدونه تختفي أيقونة مراسلة السائق ويبقى الباقي يعمل.
  final ChatRepo? chatRepo;

  /// طلب فتح محادثة قيد التنفيذ — يمنع إنشاء محادثتين بضغطتين متتاليتين.
  bool _openingChat = false;

  BookingMeCubit(this._repo, {this.chatRepo}) : super(BookingMeInitial());

  /// مراسلة السائق — مسموحة بوجود حجز فعّال وحده (الواجهة تفرض ذلك).
  ///
  /// سياسة التطبيق: لا محادثة بلا حجز. والراكب كان الطرف الوحيد بلا
  /// طريق إليها من قائمة حجوزاته، بينما للسائق زرّ مراسلة في شاشة
  /// حجوزات رحلته.
  ///
  /// الخادم يعيد المحادثة القائمة إن وُجدت بدل إنشاء ثانية، فضغط الطرفين
  /// معاً يوصلهما إلى المحادثة نفسها.
  Future<void> openChatWithDriver({
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
      (error) => emit(
          BookingMeErorr(message: error.arabic(HandelErorrMessage.chat))),
      (conversationId) => emit(BookingMeOpenConversation(
        conversationId: conversationId,
        title: name,
        avatar: avatar,
      )),
    );
  }

  Future getMyBooking() async {
    emit(BookingMeListloading());

    final response = await _repo.getMeBooking();

    response.fold(
      (error) => emit(
          BookingMeErorr(message: error.arabic(HandelErorrMessage.bookingMe))),
      (listBooking) => emit(BookingMeListLoaded(bookings: listBooking)),
    );
  }

  /// إلغاء مقاعد من الحجز — **كلّها أو بعضها بالمسار نفسه**.
  ///
  /// `POST /bookings/{id}/cancel-seats` وحده يردّ كتلة `refund_policy`؛
  /// و`/cancel` يُنهي الحجز صامتاً بلا رقم. فكان الراكب الذي يلغي حجزه
  /// كاملاً لا يعرف كم أُعيد إليه.
  ///
  /// [wasConfirmed] و[cashRide] من حال الحجز لا من الردّ — انظر
  /// [refundNotice].
  Future<void> cancelBooking(
    int bookingId,
    int seats, {
    bool wasConfirmed = true,
    bool cashRide = false,
  }) async {
    emit(BookingMeloading());
    final response = await _repo.cancelBooking(bookingId, seats);
    response.fold((erorr) {
      emit(BookingMeErorr(
          message: erorr.arabic(HandelErorrMessage.cancelBooking)));
    }, (cancel) {
      emit(BookingMeCanceled(
        cancelModel: cancel,
        wasConfirmed: wasConfirmed,
        cashRide: cashRide,
      ));
    });
  }

  /// إلغاء الحجز بالكامل (كل المقاعد دفعة واحدة)
  Future<void> cancelWholeBooking(int bookingId) async {
    emit(BookingMeloading());
    final response = await _repo.cancelWholeBooking(bookingId);
    response.fold((erorr) {
      emit(BookingMeErorr(
          message: erorr.arabic(HandelErorrMessage.cancelBooking)));
    }, (_) {
      emit(const BookingMeWholeCanceled(message: "تم إلغاء الحجز بالكامل"));
    });
  }

  /// بلاغ الراكب أن السائق لم يحضر.
  ///
  /// ثلاث نهايات لا واحدة، والخادم لا يميّزها بحقل: التعارض يصل **200
  /// كالنجاح** بنصّ مختلف، و«سبق الإبلاغ» يصل **422 كالخطأ** وهو في
  /// المعنى نجاح متأخّر — انظر [NoShowReport].
  Future<void> reportDriverNoShow(int rideId) async {
    emit(BookingMeButtonloading());
    final response = await _repo.driverNoShow(rideId);
    if (isClosed) return;

    await response.fold((erorr) async {
      // الحالة المحلية تضيع بإعادة التثبيت أو الخروج، فيعود الزرّ ظاهراً
      // ويردّ الخادم «already submitted». ذلك ليس خطأً يُعرض بالأحمر:
      // البلاغ قائم فعلاً — يُقفل الزرّ ويُذكَّر المستخدم.
      if (NoShowReport.isAlreadyReported(erorr.message)) {
        await NoShowReportStore.remember(NoShowReportStore.rideKey(rideId));
        if (isClosed) return;
        emit(const BookingMeDriverNoShowReported(
          message: "سبق أن أبلغت عن هذه الرحلة",
          outcome: NoShowOutcome.alreadyReported,
        ));
        return;
      }
      emit(BookingMeErorr(
          message: erorr.arabic(HandelErorrMessage.driverNoShow)));
    }, (response) async {
      await NoShowReportStore.remember(NoShowReportStore.rideKey(rideId));
      if (isClosed) return;

      final conflict = NoShowReport.isConflict(response);
      emit(BookingMeDriverNoShowReported(
        message: conflict
            ? "أبلغ الطرفان كلٌّ عن الآخر، فلا عقوبة تلقائية. فُتحت شكوى "
                "وسيتواصل معك فريق الدعم."
            : "تم تسجيل البلاغ. للسائق مهلة للاعتراض، ثم يُحسم تلقائياً.",
        outcome: conflict ? NoShowOutcome.conflict : NoShowOutcome.reported,
      ));
    });
  }

  /// تأكيد الراكب لاكتمال الرحلة. الخادم يرجع أخطاء منطق العمل هنا بحالة
  /// 500 لا 4xx، لذا نطابق على النص. والتأكيد المكرر (ضغط مزدوج على الزر)
  /// حالة طبيعية تُعامل كنجاح لا كخطأ.
  Future<void> finishTrip(int bookingId) async {
    emit(BookingMeButtonloading());
    final response = await _repo.finshTrip(bookingId);
    response.fold((erorr) {
      if (HandelErorrMessage.isAlreadyConfirmed(erorr.message)) {
        emit(const BookingMeFinish(message: "تم التأكيد"));
        return;
      }
      emit(BookingMeErorr(
          message: erorr.arabic(HandelErorrMessage.passangerConfirm)));
    }, (sucess) {
      emit(const BookingMeFinish(message: "تم التأكيد"));
    });
  }

  /// تقييم السائق، ومعه تعليق اختياري.
  ///
  /// **مساران لا واحد** — الخادم يفصل `POST /profile/{id}/rate` عن
  /// `POST /profile/{id}/comments`. والترتيب مقصود: التقييم أولاً لأنه
  /// جوهر الإجراء، ثم التعليق.
  ///
  /// وفشل التعليق **لا يُفشل التقييم**: النجوم وصلت الخادم فعلاً، وإظهار
  /// خطأ أحمر بعدها يوهم المستخدم أن شيئاً لم يقع فيعيد الكرّة — فيُقيَّم
  /// السائق مرتين. التعليق تفصيل ثانوي يُسقَط بصمت.
  Future<void> reateUser(
    double rating,
    int userId,
    int rideId, {
    String? comment,
  }) async {
    emit(BookingMeButtonloading());
    final response = await _repo.rateUser(rating, userId, rideId);
    if (isClosed) return;

    await response.fold((erorr) async {
      // 409 «سبق أن قيّمت هذه الرحلة» خبرٌ لا عطل — انظر
      // [BookingMeAlreadyRated]
      if (HandelErorrMessage.isAlreadyRated(erorr.message)) {
        emit(const BookingMeAlreadyRated(
            message: HandelErorrMessage.alreadyRatedRide));
        return;
      }
      // كانت «فشل التقيم» لكل شيء — رسالة الخادم تُعرَّب كما في بقية
      // المسارات بدل نصّ واحد لا يقول للمستخدم ما العمل
      emit(BookingMeErorr(
          message: erorr.arabic(HandelErorrMessage.rateUser)));
    }, (rate) async {
      final text = comment?.trim();
      if (text != null && text.isNotEmpty) {
        await _repo.addcommit(text, userId, rideId);
        if (isClosed) return;
      }
      emit(BookingMeRated(rate: rate.averageRating));
    });
  }

  Future<void> addComment(String comment, int userid, int rideId) async {
    emit(BookingMeButtonloading());
    final response = await _repo.addcommit(comment, userid, rideId);
    response.fold((erorr) {
      emit(BookingMeErorr(message: erorr.arabic(HandelErorrMessage.commet)));
    }, (succ) {
      emit(BookingMeCommented());
    });
  }
}
