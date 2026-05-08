import 'package:alatarekak/features/auth/presentation/view/verfiy_email_Singin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/features/auth/presentation/manger/singin_cubit/singin_cubit.dart';

class ButtonSingin extends StatelessWidget {
  const ButtonSingin({
    super.key,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.password,
    required this.passwordConfirm,
    required this.formKey,
  });

  final TextEditingController firstname;
  final TextEditingController lastname;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController passwordConfirm;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<SinginCubit>();

    return BlocConsumer<SinginCubit, SinginState>(
      listener: (context, state) {
        if (state is SingInGotoVerfiyOtp) {
          Get.to(
            () => BlocProvider.value(
              value: context.read<SinginCubit>(),
              child: const VerfiyEmailSingin(),
            ),
            arguments: state.email,
          );
        } else if (state is SinginErorre) {
          showMySnackBar(context, state.message);
        }
      },
      builder: (context, state) {
  return SizedBox(
    width: double.infinity,
    height: 52.h,
    child: ElevatedButton.icon(
      onPressed: state is SinginLoading
          ? null
          : () {
              final fname = firstname.text.trim();
              final lname = lastname.text.trim();
              final mail = email.text.trim();
              final pass = password.text.trim();
              final confirm = passwordConfirm.text.trim();
              final gender = cubit.gender;
              final address = cubit.address;

              if (formKey.currentState!.validate()) {
                context.read<SinginCubit>().signIn(
                      fname,
                      lname,
                      gender,
                      mail,
                      address ?? "دمشق",
                      pass,
                      confirm,
                    );
              }
            },

      icon: state is SinginLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),

      label: const Text("إنشاء حساب"),
    ),
  );
},
    );
  }
}
