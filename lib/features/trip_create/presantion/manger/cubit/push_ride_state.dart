part of 'push_ride_cubit.dart';

sealed class PushRideState extends Equatable {
  const PushRideState();

  @override
  List<Object> get props => [];
}

final class PushRideInitial extends PushRideState {}

final class PushRideLoading extends PushRideState {}

/// **الرسالة خام إنجليزية** — الواجهة تفحصها لتُميّز نقص التوثيق فتنقل
/// السائق إلى شاشته، فالتعريب يقع هناك. و[statusCode] يرافقها ليُذيَّل به
/// النصّ المعروض — انظر [HandelErorrMessage.withStatus].
final class PushRideErorr extends PushRideState {
  final String message;
  final int? statusCode;

  const PushRideErorr({required this.message, this.statusCode});
}

class PushRideValidatePhoneState extends PushRideState {
  final bool isValid;

  const PushRideValidatePhoneState(this.isValid);

  @override
  List<Object> get props => [isValid];
}

final class PushRideSuccsess extends PushRideState {
  final TripModel tripModel;

  const PushRideSuccsess({required this.tripModel});
}
