import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/core/constant/address.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/My_dropDown.dart';
import 'package:alatarekak/features/auth/presentation/manger/singin_cubit/singin_cubit.dart';

class DropDownAndGenderSing extends StatelessWidget {
  const DropDownAndGenderSing({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MyDropdown(
          title: "المحافظة",
          selectedValue: context.read<SinginCubit>().address,
          options: syrianProvinces,
          validator: (val) =>
              val == null || val.isEmpty ? "الرجاء اختيار المحافظة" : null,
          icon: const Icon(
            Icons.location_city_outlined,
            color: MyColors.accent,
          ),
          onChanged: (val) {
            context.read<SinginCubit>().changAddress(val!);
          },
        ),
        BlocBuilder<SinginCubit, SinginState>(
          builder: (context, state) {
            return Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: "M",
                    groupValue: context.read<SinginCubit>().gender,
                    onChanged: (value) {
                      context.read<SinginCubit>().emitChangeGender(value!);
                    },
                    title: const Text("ذكر"),
                    secondary: const Icon(Icons.male, color: Colors.black),
                    activeColor: MyColors.primary,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: "F",
                    groupValue: context.read<SinginCubit>().gender,
                    onChanged: (value) {
                      context.read<SinginCubit>().emitChangeGender(value!);
                    },
                    title: const Text("أنثى"),
                    secondary: const Icon(Icons.female, color: Colors.black),
                    activeColor: MyColors.primary,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
