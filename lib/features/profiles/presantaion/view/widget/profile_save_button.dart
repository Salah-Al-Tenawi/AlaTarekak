// import 'package:flutter/widgets.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:alatarekak/core/them/my_colors.dart';
// import 'package:alatarekak/core/utils/widgets/my_button.dart';
// import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
// import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';

// class ProfileSaveButton extends StatelessWidget {
//   final ProfileEntity? profileEntityWithEdit;
//   const ProfileSaveButton({super.key, this.profileEntityWithEdit});

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.topRight,
//       child: MyButton(
//           color: MyColors.accent,
//           borderRadius: true,
//           width: 80.w,
//           onPressed: () {
//             print(profileEntityWithEdit!.description);
//             context.read<ProfileCubit>().saveMyProfile(profileEntityWithEdit);
//           },
//           child: const Text(
//             "حفظ",
//             style: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.normal,
//                 color: MyColors.textSecondary),
//           )),
//     );
//   }
// }
