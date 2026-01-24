// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:alatarekak/core/route/route_name.dart';
// import 'package:alatarekak/core/them/my_colors.dart';
// import 'package:alatarekak/core/utils/widgets/my_button.dart';
// import 'package:alatarekak/features/auth/presentation/manger/singin_cubit/singin_cubit.dart';
// import 'package:alatarekak/features/auth/presentation/view/widget/otp_text_form_filed.dart';

// class VerfiyEmailSingin extends StatefulWidget {
//   const VerfiyEmailSingin({super.key});

//   @override
//   State<VerfiyEmailSingin> createState() => _VerfiyEmailSinginState();
// }

// class _VerfiyEmailSinginState extends State<VerfiyEmailSingin> {
//   late final String numberPhone;

//   @override
//   void initState() {
//     numberPhone = Get.arguments as String;
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<SinginCubit, SinginState>(
//       listener: (context, state) {
//         if (state is SinginSuccess) {
//           Get.toNamed(RouteName.home);
//         }
//       },
//       builder: (context, state) {
//         return Scaffold(
//             body: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 30.w),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       "  لقد قمنا بإرسال رمز التحقق على الرقم \n $numberPhone",
//                       textAlign: TextAlign.center,
//                     ),
//                     const OtpTextform(),
//                     const Text(". . ."),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text(
//                           "قم بإعادة الإرسال",
//                           style: TextStyle(color: MyColors.greyTextColor),
//                         ),
//                         SizedBox(
//                           width: 50.h,
//                         ),
//                         MyButton(
//                             onPressed: () {
//                               context.read<SinginCubit>().sendOtpAgain();
//                             },
//                             child: const Icon(Icons.refresh))
//                       ],
//                     ),
//                     SizedBox(
//                       height: 80.h,
//                     ),
                   
//                   ],
//                 )));
//       },
//     );
//   }
// }
