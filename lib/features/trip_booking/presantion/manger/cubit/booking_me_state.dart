part of 'booking_me_cubit.dart';

sealed class BookingMeState extends Equatable {
  const BookingMeState();

  @override
  List<Object> get props => [];
}

final class BookingMeInitial extends BookingMeState {}

final class BookingMeListloading extends BookingMeState {}

final class BookingMeloading extends BookingMeState {}
final class BookingMeButtonloading extends BookingMeState {}

final class BookingMeErorr extends BookingMeState {
  final String message;

  const BookingMeErorr({required this.message});

  @override
  List<Object> get props => [message];
}

final class BookingMeListLoaded extends BookingMeState {
  final List<BookingMe> bookings;
  const BookingMeListLoaded({required this.bookings});

  @override
  List<Object> get props => [bookings];
}

/// أُلغيت مقاعد من الحجز — كلياً أو جزئياً.
///
/// [wasConfirmed] و[cashRide] يرافقان الردّ لأن `refund_policy` يصل
/// محسوباً حتى حين لا يُنفَّذ منه شيء — انظر [refundNotice].
final class BookingMeCanceled extends BookingMeState {
  final CancelBookingModel cancelModel;
  final bool wasConfirmed;
  final bool cashRide;

  const BookingMeCanceled({
    required this.cancelModel,
    this.wasConfirmed = true,
    this.cashRide = false,
  });

  /// أُلغي الحجز كلّه لا بعضه — يُقرأ من الردّ لا من نصّ رسالته.
  bool get isWholeBooking =>
      cancelModel.data.remainingSeats == 0 ||
      cancelModel.data.bookingStatus.trim().toLowerCase() == 'cancelled';

  @override
  List<Object> get props => [cancelModel, wasConfirmed, cashRide];
}

final class BookingMeWholeCanceled extends BookingMeState {
  final String message;

  const BookingMeWholeCanceled({required this.message});

  @override
  List<Object> get props => [message];
}

final class BookingMeDriverNoShowReported extends BookingMeState {
  final String message;

  /// ما آل إليه البلاغ — تُبنى عليه رسالة الشاشة: قبولٌ بمهلة اعتراض،
  /// أو تعارضٌ فُتحت به شكوى، أو بلاغ سبق تسجيله.
  final NoShowOutcome outcome;

  const BookingMeDriverNoShowReported({
    required this.message,
    this.outcome = NoShowOutcome.reported,
  });

  @override
  List<Object> get props => [message, outcome];
}

final class BookingMeFinish extends BookingMeState {
  final String message;

  const BookingMeFinish({required this.message});

  @override
  List<Object> get props => [message];
}

final class BookingMeRated extends BookingMeState {
  final double rate;

  const BookingMeRated({required this.rate});

  @override
  List<Object> get props => [rate];
}

/// الرحلة قُيّمت من قبل — ردّ الخادم 409 على تقييم ثانٍ.
///
/// منفصلة عن [BookingMeErorr] لأنها ليست عطلاً: تقييم الراكب الأول
/// قائم، وهذه محاولة ثانية تُردّ. فتُعرض بنبرة خبر لا بأحمر يوهم أن
/// التقييم ضاع فيعيد الكرّة.
final class BookingMeAlreadyRated extends BookingMeState {
  final String message;

  const BookingMeAlreadyRated({required this.message});

  @override
  List<Object> get props => [message];
}

final class BookingMeCommented extends BookingMeState {}

/// محادثة السائق جاهزة للفتح — الشاشة تنتقل إليها.
final class BookingMeOpenConversation extends BookingMeState {
  final int conversationId;
  final String? title;
  final String? avatar;

  const BookingMeOpenConversation({
    required this.conversationId,
    this.title,
    this.avatar,
  });

  @override
  List<Object> get props => [conversationId, title ?? '', avatar ?? ''];
}
