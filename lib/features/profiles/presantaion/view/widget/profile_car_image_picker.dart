import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/features/profiles/presantaion/view/widget/get_profile_image.dart';

class ProfileCarImagePicker extends StatelessWidget {
  final String? carImage;
  final VoidCallback onPick;

  const ProfileCarImagePicker({
    super.key,
    required this.carImage,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: MyButton(
        onPressed: onPick,
        child: CircleAvatar(
          backgroundColor: MyColors.primary,
          maxRadius: 30,
          backgroundImage: getCarImage(context, carImage),
        ),
      ),
    );
  }
}
