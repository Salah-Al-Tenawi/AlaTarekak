import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/cutom_list_tile.dart';

class CarSeatsInputTile extends StatelessWidget {
  final TextEditingController controller;
   final void Function(String)? onChanged;

  const CarSeatsInputTile({super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      title: "عدد الكراسي",
      titleTextStyle: AppTextStyles.bodyMedium,
      iconleading: const Icon(Icons.chair, size: 20, color: MyColors.primary),
      subtitle: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: InputBorder.none),
        onChanged: onChanged,
      ),
    );
  }
}
