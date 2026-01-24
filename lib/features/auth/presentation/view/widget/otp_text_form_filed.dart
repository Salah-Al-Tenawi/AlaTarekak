// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:alatarekak/core/them/my_colors.dart';
// import 'package:alatarekak/features/auth/presentation/manger/singin_cubit/singin_cubit.dart';

// // ignore: must_be_immutable
// class OtpTextform extends StatelessWidget {
//   const OtpTextform({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return OtpTextField(
//       numberOfFields: 4,
//       borderColor: MyColors.blueColor,

//       //set to true to show as box or false to show as dash
//       showFieldAsBox: true,
//       filled: true,

//       borderRadius: BorderRadius.circular(20),
//       margin: EdgeInsets.symmetric(vertical: 30.h),
//       fieldWidth: 50.w,
//       fieldHeight: 80.h,

//       //runs when every textfield is filled
//       onSubmit: (String verificationCode) {
//         showDialog(
//             context: context,
//             builder: (context) {
//               return AlertDialog(
//                 title: const Text(" تـأكـيد"),
//                 content: Text('رمز التحقق الذي أدخلته $verificationCode'),
//               );
//             });
//         context.read<SinginCubit>().checkOTp(verificationCode, otp)
//       },
//     );
//   }
// }
