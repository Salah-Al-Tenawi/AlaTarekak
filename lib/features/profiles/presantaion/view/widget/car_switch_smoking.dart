import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/cutom_list_tile.dart';

class SmokingSwitchTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SmokingSwitchTile({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomListTile(
      title: "التدخين",
      titleTextStyle: AppTextStyles.bodyMedium,
      iconleading: const Icon(Icons.smoking_rooms, size: 20, color: MyColors.primary),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.green,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value ? "مسموح" : "ممنوع",
              style: TextStyle(
                fontSize: 12,
                color: value ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
