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

final class BookingUserInTripSucc extends BookingUserInTripState {}

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

