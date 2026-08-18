import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/core/utils/functions/uuid_v4.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_details/data/model/booking_model.dart';
import 'package:alatarekak/features/trip_details/data/model/trip_details_mode.dart';
import 'package:alatarekak/features/trip_details/data/repo/trip_details_repo.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'tripdetails_state.dart';

class TripDetailsCubit extends SafeCubit<TripDetailsState> {
  final TripDetailsRepoIM tripDetailsRepoIM;

  /// اختياري: بدونه يبقى الحجز يعمل بلا فتح محادثة تلقائية.
  final ChatRepo? chatRepo;

  TripDetailsCubit({required this.tripDetailsRepoIM, this.chatRepo})
      : super(TripDetailsInitial());

  /// مفتاح الحماية من التكرار لكل رحلة — يُولَّد مرة واحدة ويبقى ثابتاً عبر
  /// كل إعادات المحاولة (ضغط مزدوج، انقطاع شبكة، رفض مؤقت من الخادم) حتى
  /// تصل استجابة فعلية. بدون هذا الثبات تفقد الحماية معناها ويُنشأ حجز مكرر.
  final Map<int, String> _bookingKeys = {};

  /// طلب فتح محادثة قيد التنفيذ — يمنع إنشاء محادثتين بضغطتين متتاليتين.
  bool _openingChat = false;

  Future<void> booking(int seats, int tripId, String communicationNumber) async {
    emit(TripDetailsLoading());
    final idempotencyKey = _bookingKeys.putIfAbsent(tripId, uuidV4);

    final response = await tripDetailsRepoIM.booking(
        seats, tripId, communicationNumber, idempotencyKey);
    // fold مُنتظَر: فرع النجاح غير متزامن (يفتح المحادثة) وبدون await
    // تعود الدالة قبل إصدار الحالة النهائية
    if (isClosed) return;

    await response.fold((error) async {
      // الرسالة الخام تُترجم هنا — الواجهة تعرضها كما هي
      emit(TripDetailsError(
          message: HandelErorrMessage.bookAset(error.message)));
    }, (booking) async {
      // وصلت استجابة نهائية — المحاولة انتهت، وأي حجز لاحق على الرحلة
      // نفسها (بعد إلغاء مثلاً) يحتاج مفتاحاً جديداً وإلا أعاد الخادم
      // الحجز القديم خلال 24 ساعة.
      _bookingKeys.remove(tripId);

      final data = booking.data;
      final conversationId = await _startChatWithDriver(data);
      if (isClosed) return;

      emit(TripDetailsRequestBooking(
        booking: booking,
        conversationId: conversationId,
        driverName: data?.driverName,
        driverAvatar: data?.driverAvatar,
      ));
    });
  }

  /// يفتح محادثة مع السائق (بلا إرسال — الرسالة الافتتاحية تُكتب في حقل
  /// الإدخال عند فتح الشاشة والقرار للراكب).
  ///
  /// يقتصر على الحجز المؤكَّد (رحلات direct): في رحلات request الحجز ما
  /// زال بانتظار موافقة السائق، ولا يجوز فتح محادثة قبل قيام حجز فعلي.
  ///
  /// لا يُفشل الحجز مهما حدث — الحجز نجح فعلاً، وتعذّر المحادثة تفصيل
  /// ثانوي يمكن للمستخدم تجاوزه بفتحها يدوياً من بطاقة السائق.
  Future<int?> _startChatWithDriver(BookingData? data) async {
    if (chatRepo == null || data == null) return null;
    if (!data.isConfirmed || data.driverId <= 0) return null;

    final conversation =
        await chatRepo!.startConversation(userId: data.driverId);
    final conversationId = conversation.fold((_) => null, (id) => id);
    if (conversationId == null || conversationId <= 0) return null;
    return conversationId;
  }

  /// [asDriver] يُمرَّر من «رحلاتي» حيث كل رحلة للمستخدم بالتعريف.
  ///
  /// **مسار مختلف لا وسيط إضافي:** `GET /rides/{id}` لا يرسل الحجوزات
  /// عمداً — لا يصحّ أن يطّلع أحد على حجوزات رحلة ليست له — بينما
  /// `GET /rides/{id}/passangers` يرسلها لسائقها. وكانت الشاشة تجلب
  /// الأول دائماً، فيفتح السائق رحلته فيجدها بلا حجوزات.
  ///
  /// والقرار عند المستدعي لا بعد الجلب: معرفة أن الرحلة لي تأتي من
  /// الشاشة التي فتحتها، ولا يمكن استنتاجها قبل أن يصل الرد.
  Future<void> fetchTrip(int tripId, {bool asDriver = false}) async {
    emit(TripDetailsLoading());
    final response = asDriver
        ? await tripDetailsRepoIM.featchTripWithBookings(tripId)
        : await tripDetailsRepoIM.featchTrip(tripId);

    // شاشة التفاصيل تُغلَق بمغادرتها — والخروج السريع من نتائج البحث
    // شائع — بينما الطلب ما زال في الطريق، فيعود الردّ إلى كيوبت
    // مُغلَق. بلا هذا الفحص يُرفع StateError من مسار غير متزامن لا
    // يلتقطه أحد: «Cannot emit new states after calling close».
    if (isClosed) return;

    response.fold((error) {
      emit(TripDetailsError(
          message: HandelErorrMessage.showOneRide(error.message)));
    }, (trip) {
      if (trip.driver.id == myid()) {
        emit(TripDetailsLoaded(trip: trip, mode: TripDetailsMode.myView));
      } else {
        emit(TripDetailsLoaded(trip: trip, mode: TripDetailsMode.otherView));
      }
    });
  }

  Future<void> fetchProfile(int userId) async {
    emit(TripDetailsGoToProfile(userId: userId));
  }

  void gotoChatWithDriver(int userId, {String? name, String? avatar}) {
    emit(TripDetailsGoToChat(
        driverId: userId, driverName: name, driverAvatar: avatar));
  }

  /// يفتح محادثة مع مستخدم (أو يعيد القائمة إن وُجدت) بلا إرسال أي رسالة —
  /// للضغط اليدوي على زر المراسلة.
  ///
  /// الحارس يمنع طلبين متزامنين من ضغطتين متتاليتين على الزر.
  Future<void> openChatWith({
    required int userId,
    String? name,
    String? avatar,
  }) async {
    if (chatRepo == null || _openingChat) return;
    _openingChat = true;
    emit(TripDetailsLoading());

    final result = await chatRepo!.startConversation(userId: userId);
    _openingChat = false;
    if (isClosed) return;

    result.fold(
      (error) => emit(TripDetailsError(
          message: HandelErorrMessage.chat(error.message))),
      (conversationId) => emit(TripDetailsOpenConversation(
        conversationId: conversationId,
        title: name,
        avatar: avatar,
      )),
    );
  }

  /// إنهاء الرحلة من السائق — POST /rides/{id}/finish حصراً.
  /// لا نستدعي /driver-confirm بعده: الخادم يؤكّد السائق تلقائياً داخل
  /// finish، وأي استدعاء لاحق يعود بـ 400 "already confirmed".
  Future<void> finishRide(int tripId) async {
    emit(TripDetailsLoading());
    final response = await tripDetailsRepoIM.finishTrip(tripId);
    if (isClosed) return;

    await response.fold((erorr) async {
      // رحلة بلا ركّاب: الخادم أنهاها فعلاً ثم رمى 400 كاذباً — نتحقق
      // من الحالة الحقيقية قبل إزعاج السائق برسالة خطأ.
      if (HandelErorrMessage.isRideNotAwaitingConfirmation(erorr.message) &&
          await _isRideFinished(tripId)) {
        if (isClosed) return; // طلب ثانٍ انتظرناه — قد تُغلق الشاشة خلاله
        emit(TripDetailsFinishTrip());
        return;
      }
      if (isClosed) return;
      emit(TripDetailsError(
          message: HandelErorrMessage.finishRide(erorr.message)));
    }, (response) async {
      emit(TripDetailsFinishTrip());
    });
  }

  /// إعادة جلب الرحلة للتحقق من انتهائها فعلاً (لا تُصدر أي حالة).
  Future<bool> _isRideFinished(int tripId) async {
    final response = await tripDetailsRepoIM.featchTrip(tripId);
    return response.fold((_) => false, (trip) => trip.status == "finished");
  }
}
