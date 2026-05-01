import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/cutom_list_tile.dart';

class CarColorInputTile extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onChanged;

  const CarColorInputTile(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      title: "لون",
      titleTextStyle: AppTextStyles.bodyMedium,
      iconleading:
          const Icon(Icons.color_lens, size: 20, color: MyColors.primary),
      subtitle: TextFormField(
        controller: controller,
        decoration: const InputDecoration(border: InputBorder.none),
        onChanged: onChanged,
      ),
    );
  }
}
