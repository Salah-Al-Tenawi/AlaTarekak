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

final class BookingMeCanceled extends BookingMeState {
  final CancelBookingModel cancelModel;

  const BookingMeCanceled({required this.cancelModel});

  @override
  List<Object> get props => [cancelModel];
}

final class BookingMeWholeCanceled extends BookingMeState {
  final String message;

  const BookingMeWholeCanceled({required this.message});

  @override
  List<Object> get props => [message];
}

final class BookingMeDriverNoShowReported extends BookingMeState {
  final String message;

  const BookingMeDriverNoShowReported({required this.message});

  @override
  List<Object> get props => [message];
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
