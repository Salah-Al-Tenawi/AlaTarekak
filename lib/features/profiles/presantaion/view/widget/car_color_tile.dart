
import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/cutom_list_tile.dart';

class CarColorTile extends StatelessWidget {
  final String ?color;

  const CarColorTile({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      title: "لون",
      titleTextStyle: AppTextStyles.bodyMedium,
      iconleading: const Icon(Icons.color_lens, size: 20, color: MyColors.primary),
      subtitle: Text(
        color??"",
        style: const TextStyle(color: MyColors.textPrimary),
      ),
    );
  }
}
