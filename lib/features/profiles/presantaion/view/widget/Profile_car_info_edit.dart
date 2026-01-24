import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/features/profiles/data/model/enum/image_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/car_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// استورد الويدجتات الفرعية الخاصة بك (CarNameInputTile, CarColorInputTile, ...)
import 'package:alatarekak/features/profiles/presantaion/view/widget/car_color_input_tile.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/car_name_input_tile.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/car_seats_input_tile.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/car_switch_smoking.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/profile_car_image_picker.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/radio_switch_tile.dart';

class ProfileCarInfoEdit extends StatefulWidget {
  final CarEntity? carWithEdit;
  final ValueChanged<CarEntity>? onCarChanged; // callback

  const ProfileCarInfoEdit({
    super.key,
    required this.carWithEdit,
    this.onCarChanged,
  });

  @override
  State<ProfileCarInfoEdit> createState() => _ProfileCarInfoEditState();
}

class _ProfileCarInfoEditState extends State<ProfileCarInfoEdit> {
  late TextEditingController carName;
  late TextEditingController colorCar;
  late TextEditingController seatsCar;
  late bool hasRadio;
  late bool allowsSmoking;
  String? carImage;

  late CarEntity currentCar; // immutable current snapshot

  @override
  void initState() {
    super.initState();
    currentCar = widget.carWithEdit ?? const CarEntity();
    carName = TextEditingController(text: currentCar.type ?? "");
    colorCar = TextEditingController(text: currentCar.color ?? "");
    seatsCar = TextEditingController(text: currentCar.seats?.toString() ?? "");
    hasRadio = currentCar.hasRadio;
    allowsSmoking = currentCar.allowsSmoking;
    carImage = currentCar.image;
  }

  @override
  void didUpdateWidget(covariant ProfileCarInfoEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.carWithEdit != widget.carWithEdit) {
      currentCar = widget.carWithEdit ?? const CarEntity();
      carName.text = currentCar.type ?? "";
      colorCar.text = currentCar.color ?? "";
      seatsCar.text = currentCar.seats?.toString() ?? "";
      setState(() {
        hasRadio = currentCar.hasRadio;
        allowsSmoking = currentCar.allowsSmoking;
        carImage = currentCar.image;
      });
    }
  }

  @override
  void dispose() {
    carName.dispose();
    colorCar.dispose();
    seatsCar.dispose();
    super.dispose();
  }

  void _emitChanged(CarEntity newCar) {
    currentCar = newCar;
    widget.onCarChanged?.call(newCar);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileCarImagePicker(
          carImage: carImage,
          onPick: () => _onPickImage(context),
        ),
        CarNameInputTile(
          controller: carName,
          onChanged: (val) {
            final updated = currentCar.copyWith(type: val);
            _emitChanged(updated);
            // no need to setState for text field itself; controller updates the UI
          },
        ),
        Row(
          children: [
            Expanded(
              child: CarColorInputTile(
                controller: colorCar,
                onChanged: (val) {
                  final updated = currentCar.copyWith(color: val);
                  _emitChanged(updated);
                },
              ),
            ),
            Expanded(
              child: CarSeatsInputTile(
                controller: seatsCar,
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null) {
                    final updated = currentCar.copyWith(seats: parsed);
                    _emitChanged(updated);
                  }
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: RadioSwitchTile(
                value: hasRadio,
                onChanged: (val) => setState(() {
                  hasRadio = val;
                  final updated = currentCar.copyWith(hasRadio: val);
                  _emitChanged(updated);
                }),
              ),
            ),
            Expanded(
              child: SmokingSwitchTile(
                value: allowsSmoking,
                onChanged: (val) => setState(() {
                  allowsSmoking = val;
                  final updated = currentCar.copyWith(allowsSmoking: val);
                  _emitChanged(updated);
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onPickImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (!context.mounted) return;

    if (pickedFile != null) {
      // إذا عندك منطق رفع للصورة في Cubit احتفظ به
      context.read<ProfileCubit>().pickImage(pickedFile, ProfileImagePicMode.car);

      setState(() {
        carImage = pickedFile.path;
      });
      final updated = currentCar.copyWith(image: pickedFile.path);
      _emitChanged(updated);
    }
  }
}
