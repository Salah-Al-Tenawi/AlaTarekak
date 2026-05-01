import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/core/utils/functions/input_valid.dart';
import 'package:alatarekak/core/utils/widgets/custom_text_form.dart';
import 'package:alatarekak/core/utils/widgets/cutom_list_tile.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';

// ignore: must_be_immutable
class ProfileHintline extends StatelessWidget {
  final String hintLine;
  final TextEditingController? controllerAboutme;
  final ProfileMode mode;
  final void Function(String)? onDescriptionChanged;

  const ProfileHintline({
    super.key,
    required this.hintLine,
    required this.controllerAboutme,
    required this.mode,
    this.onDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == ProfileMode.myEdit) {
      return SizedBox(
        height: 150.h,
        child: CustomTextformfild(
          title: "نبذة عني",
          validator: (val) => inputvaild(val!, "descrption", null, null),
          controller: controllerAboutme,
          onChanged: onDescriptionChanged,
          maxLines: null,
          minLines: 3,
          expands: false,
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.multiline,
        ),
      );
    }

    return CustomListTile(
      title: "نبذة عني",
      margin: EdgeInsets.symmetric(vertical: 20.h),
      isThreeLine: true,
      titleTextStyle: AppTextStyles.bodyLarge,
      subtitle: Text(
        hintLine.isEmpty ? "لا يوجد نبذة بعد" : hintLine,
        style: const TextStyle(color: MyColors.textHint),
      ),
    );
  }
}
