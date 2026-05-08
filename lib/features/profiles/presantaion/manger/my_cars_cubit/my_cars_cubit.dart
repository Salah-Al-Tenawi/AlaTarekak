import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/profiles/domain/entity/user_car_entity.dart';

part 'my_cars_state.dart';

class MyCarsScreenCubit extends Cubit<MyCarsState> {
  MyCarsScreenCubit() : super(const MyCarsInitial());

  Future<void> getMyCars() async {
    emit(const MyCarsLoading());
    // TODO: استبدال ببيانات API عند جاهزيته
    await Future.delayed(const Duration(milliseconds: 300));
    emit(const MyCarsLoaded([]));
  }

  Future<void> deleteCar(int carId) async {
    // TODO: API call
  }
}
