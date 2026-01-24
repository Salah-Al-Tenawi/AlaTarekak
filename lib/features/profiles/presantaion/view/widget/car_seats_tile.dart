import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/cutom_list_tile.dart';

class CarSeatsTile extends StatelessWidget {
  final int ?seats;

  const CarSeatsTile({super.key, required this.seats});

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      title: "عدد الكراسي",
      titleTextStyle: font15BoldRamadi,
      iconleading: const Icon(Icons.chair, size: 20, color: MyColors.primary),
      subtitle: Text(
        "$seats",
        style: fontdefualtGreyText,
      ),
    );
  }
}
