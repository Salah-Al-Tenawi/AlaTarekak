import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';

class ProfileVerificationIcon extends StatelessWidget {
  const ProfileVerificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfileCubit, ProfileState, String>(
      selector: (state) => state.profileEntity?.verification ?? 'none',
      builder: (context, status) {
        switch (status) {
          case 'approved':
            return const Tooltip(
              message: 'موثَّق',
              child: FaIcon(FontAwesomeIcons.circleCheck,
                  color: MyColors.success, size: 20),
            );
          case 'pending':
            return const Tooltip(
              message: 'قيد المراجعة',
              child: FaIcon(FontAwesomeIcons.clock,
                  color: MyColors.warning, size: 20),
            );
          case 'rejected':
            return const Tooltip(
              message: 'مرفوض',
              child: FaIcon(FontAwesomeIcons.circleXmark,
                  color: MyColors.error, size: 20),
            );
          default:
            return const Tooltip(
              message: 'غير موثَّق',
              child: FaIcon(FontAwesomeIcons.circleExclamation,
                  color: MyColors.textHint, size: 20),
            );
        }
      },
    );
  }
}