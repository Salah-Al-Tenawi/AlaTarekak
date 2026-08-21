part of 'booking_user_in_trip_cubit.dart';

sealed class BookingUserInTripState extends Equatable {
  const BookingUserInTripState();

  @override
  List<Object> get props => [];
}

final class BookingUserInTripInitial extends BookingUserInTripState {}

/// إجراء قيد التنفيذ على حجز بعينه.
///
/// كانت الحالة بلا معرّف، فيستبدل مؤشّر التحميل أزرار **كل** بطاقات
/// الحجوزات لا بطاقة الحجز المعنيّ — فيبدو أن الشاشة كلها معطّلة.
final class BookingUserInTripLoading extends BookingUserInTripState {
  final int bookingId;

  const BookingUserInTripLoading({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

final class BookingUserInTripErorr extends BookingUserInTripState {
  final String message;

  const BookingUserInTripErorr({required this.message});

  @override
  List<Object> get props => [message];
}

final class BookingUserInTripUpdated extends BookingUserInTripState {
  final int bookingId;
  final String statusRide;

  const BookingUserInTripUpdated({
    required this.bookingId,
    required this.statusRide,
  });

  @override
  List<Object> get props => [bookingId, statusRide];
}

/// نتيجة بلاغ السائق عن غياب راكب.
///
/// منفصلة عن [BookingUserInTripUpdated] لأن للبلاغ رسالةً تُقال للسائق —
/// مهلة اعتراض، أو شكوى فُتحت عند التعارض — بينما التحديث يغيّر بطاقةً
/// بصمت. والحالة الناتجة `no_show` تصل مع إعادة الجلب.
final class BookingUserInTripNoShowReported extends BookingUserInTripState {
  final int bookingId;
  final String message;
  final NoShowOutcome outcome;

  const BookingUserInTripNoShowReported({
    required this.bookingId,
    required this.message,
    this.outcome = NoShowOutcome.reported,
  });

  @override
  List<Object> get props => [bookingId, message, outcome];
}

/// قيّم السائقُ راكبَه — ومعه تعليق اختياري إن كتبه.
final class BookingUserInTripRated extends BookingUserInTripState {
  final double averageRating;

  const BookingUserInTripRated({required this.averageRating});

  @override
  List<Object> get props => [averageRating];
}

/// الرحلة قُيّمت من قبل — ردّ الخادم 409 على تقييم ثانٍ.
///
/// منفصلة عن [BookingUserInTripErorr] لأنها ليست عطلاً: تقييم السائق
/// الأول قائم، وهذه محاولة ثانية تُردّ. فتُعرض بنبرة خبر لا بأحمر
/// يوهم أن التقييم ضاع.
final class BookingUserInTripAlreadyRated extends BookingUserInTripState {
  final String message;

  const BookingUserInTripAlreadyRated({required this.message});

  @override
  List<Object> get props => [message];
}

final class BookingUserInTripSucc extends BookingUserInTripState {}

/// جلب الرحلة وحجوزاتها جارٍ — يخصّ الشاشة كلها لا حجزاً بعينه.
final class BookingUserInTripFetching extends BookingUserInTripState {}

/// وصلت قائمة حجوزات الرحلة، ومعها موعد انطلاقها.
///
/// الموعد يحدّد متى يظهر بلاغ «لم يحضر»، وكان يُمرَّر من الشاشة السابقة
/// فيغيب متى فُتحت الشاشة من مسار آخر.
final class BookingUserInTripListLoaded extends BookingUserInTripState {
  final List<BookingModel> bookings;
  final DateTime departure;

  /// حالة الرحلة نفسها لا حالة الحجز — تصل في `data.status` من المسار
  /// ذاته. يُخفى بها بلاغ الغياب متى انتهت الرحلة أو أُلغيت: الخادم
  /// يردّ البلاغ حينها بـ«cannot report no-show for a ride with status».
  final String rideStatus;

  const BookingUserInTripListLoaded({
    required this.bookings,
    required this.departure,
    this.rideStatus = '',
  });

  @override
  List<Object> get props => [bookings, departure, rideStatus];
}

/// المحادثة مع الراكب جاهزة — الواجهة تنتقل إلى شاشة المحادثة.
final class BookingUserInTripOpenConversation extends BookingUserInTripState {
  final int conversationId;
  final String? title;
  final String? avatar;

  const BookingUserInTripOpenConversation({
    required this.conversationId,
    this.title,
    this.avatar,
  });

  @override
  List<Object> get props => [conversationId, title ?? '', avatar ?? ''];
}

