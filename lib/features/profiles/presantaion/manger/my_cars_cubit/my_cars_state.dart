part of 'my_cars_cubit.dart';

sealed class MyCarsState extends Equatable {
  const MyCarsState();
  @override
  List<Object?> get props => [];
}

final class MyCarsInitial extends MyCarsState {
  const MyCarsInitial();
}

final class MyCarsLoading extends MyCarsState {
  const MyCarsLoading();
}

final class MyCarsLoaded extends MyCarsState {
  final List<UserCarEntity> cars;
  const MyCarsLoaded(this.cars);
  @override
  List<Object?> get props => [cars];
}

final class MyCarsError extends MyCarsState {
  final String message;
  const MyCarsError(this.message);
  @override
  List<Object?> get props => [message];
}
