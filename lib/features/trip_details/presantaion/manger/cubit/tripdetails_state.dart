part of 'tripdetails_cubit.dart';

sealed class TripDetailsState extends Equatable {
  const TripDetailsState();

  @override
  List<Object?> get props => [];
}

final class TripDetailsInitial extends TripDetailsState {}

final class TripDetailsLoading extends TripDetailsState {}

final class TripDetailsError extends TripDetailsState {
  final String message;
  const TripDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class TripDetailsLoaded extends TripDetailsState {
  final TripModel trip;
  final TripDetailsMode mode;
  const TripDetailsLoaded({required this.trip, required this.mode});

  @override
  List<Object?> get props => [trip, mode];
}

final class TripDetailsCancel extends TripDetailsState {
  final String message;
  const TripDetailsCancel({required this.message});

  @override
  List<Object?> get props => [message];
}

final class TripDetailsBooking extends TripDetailsState {}

  final class TripDetailsRequestBooking extends TripDetailsState {
    final BookingResponse booking;

    /// معرّف المحادثة التي فُتحت مع السائق وأُرسلت فيها رسالة الراكب
    /// الأولى. يبقى null إذا كان الحجز بانتظار موافقة السائق (pending)
    /// أو تعذّر فتح المحادثة — والحجز ناجح في الحالتين.
    final int? conversationId;

    /// اسم السائق وصورته لعنوان شاشة المحادثة عند فتحها.
    final String? driverName;
    final String? driverAvatar;

    const TripDetailsRequestBooking({
      required this.booking,
      this.conversationId,
      this.driverName,
      this.driverAvatar,
    });

    @override
    List<Object?> get props =>
        [booking, conversationId, driverName, driverAvatar];
  }

final class TripDetailsGoToProfile extends TripDetailsState {
  final int userId;
  const TripDetailsGoToProfile({required this.userId});

  @override
  List<Object?> get props => [userId];
}

final class TripDetailsGoToChat extends TripDetailsState {
  final int driverId;
  final String? driverName;
  final String? driverAvatar;

  const TripDetailsGoToChat({
    required this.driverId,
    this.driverName,
    this.driverAvatar,
  });

  @override
  List<Object?> get props => [driverId, driverName, driverAvatar];
}

/// المحادثة جاهزة — الواجهة تنتقل إلى شاشة المحادثة بهذا المعرّف.
final class TripDetailsOpenConversation extends TripDetailsState {
  final int conversationId;
  final String? title;
  final String? avatar;

  const TripDetailsOpenConversation({
    required this.conversationId,
    this.title,
    this.avatar,
  });

  @override
  List<Object?> get props => [conversationId, title, avatar];
}

class TripDetailsButtonLoading extends TripDetailsState {}
class TripDetailsFinishTrip extends TripDetailsState {}

class TripDetailsBookingSuccess extends TripDetailsState {
  final String message;

  const TripDetailsBookingSuccess({required this.message});
}

class TripDetailsBookingFailure extends TripDetailsState {
  final String message;

  const TripDetailsBookingFailure({required this.message});
}