import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/cutom_list_tile.dart';

class CarRadioInfoTile extends StatelessWidget {
  final bool ?hasRadio;

  const CarRadioInfoTile({super.key, required this.hasRadio});

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      title: "الراديو",
      titleTextStyle: AppTextStyles.bodyMedium,
      iconleading: const Icon(Icons.radio, size: 20, color: MyColors.primary),
      subtitle: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: hasRadio! ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasRadio! ? Icons.check : Icons.close,
              size: 16,
              color: hasRadio! ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              hasRadio! ? "متاح" : "غير متاح",
              style: TextStyle(
                color: hasRadio! ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
