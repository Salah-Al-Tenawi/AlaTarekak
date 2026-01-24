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
      selector: (state) {
        return state.profileEntity?.verification ?? 'none';
      },
      builder: (context, verificationStatus) {
        switch (verificationStatus) {
          case "verified":
            return const Tooltip(
              message: "موثق",
              child: FaIcon(
                FontAwesomeIcons.circleCheck,
                color: MyColors.accent,
                size: 20,
              ),
            );
          case "pending":
            return const Tooltip(
              message: "قيد التوثيق",
              child: FaIcon(
                FontAwesomeIcons.clock,
                color: Colors.orange,
                size: 20,
              ),
            );
          case "none":
          default:
            return const Tooltip(
              message: "غير موثق",
              child: FaIcon(
                FontAwesomeIcons.circleExclamation,
                color: Colors.grey,
                size: 20,
              ),
            );
        }
      },
    );
  }
} 