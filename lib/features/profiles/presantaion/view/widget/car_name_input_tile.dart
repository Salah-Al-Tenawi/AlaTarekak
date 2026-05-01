import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/cutom_list_tile.dart';

class CarNameInputTile extends StatelessWidget {
  final TextEditingController controller;
 final void Function(String)? onChanged;

  const CarNameInputTile(
      {super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      title: "نوع السيارة",
      titleTextStyle: AppTextStyles.bodyMedium,
      iconleading:
          const Icon(Icons.directions_car, size: 20, color: MyColors.primary),
      subtitle: TextFormField(
        controller: controller,
        decoration: const InputDecoration(border: InputBorder.none),
        onChanged: onChanged,
      ),
    );
  }
}
