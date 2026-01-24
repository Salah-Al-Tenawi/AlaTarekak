import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/cutom_list_tile.dart';

class CarSmokingInfoTile extends StatelessWidget {
  final bool ?allowsSmoking;

  const CarSmokingInfoTile({super.key, required this.allowsSmoking});

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      title: "التدخين",
      titleTextStyle: font15BoldRamadi,
      iconleading: const Icon(Icons.smoking_rooms, size: 20, color: MyColors.primary),
      subtitle: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: allowsSmoking! ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allowsSmoking! ? Icons.check : Icons.close,
              size: 16,
              color: allowsSmoking! ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              allowsSmoking! ? "مسموح" : "ممنوع",
              style: TextStyle(
                color: allowsSmoking! ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
