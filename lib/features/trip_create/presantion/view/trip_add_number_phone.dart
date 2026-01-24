import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/functions/input_valid.dart';
import 'package:alatarekak/core/utils/functions/my_dilaog.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/presantion/manger/cubit/push_ride_cubit.dart';

class TripAddNumberPhone extends StatefulWidget {
  const TripAddNumberPhone({super.key});

  @override
  State<TripAddNumberPhone> createState() => _TripAddNumberPhoneState();
}

class _TripAddNumberPhoneState extends State<TripAddNumberPhone> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TripFrom tripFrom;

  @override
  void initState() {
    super.initState();
    tripFrom = Get.arguments as TripFrom;
    if (tripFrom.numberPhone != null) {
      _phoneController.text = tripFrom.numberPhone!;

      context.read<PushRideCubit>().validatePhone(tripFrom.numberPhone!);
    }

    _phoneController.addListener(() {
      context.read<PushRideCubit>().validatePhone(_phoneController.text);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<PushRideCubit, PushRideState>(
        listener: (context, state) {
          if (state is PushRideSuccsess) {
            Get.offAllNamed(RouteName.tripDidYouBack, arguments: tripFrom);
          } else if (state is PushRideErorr) {
            String message = HandelErorrMessage.createWithRoute(state.message);

            if (state.message.contains(
                    "You must be verified as a driver to create rides") ||
                state.message
                    .contains("Missing required verification documents")) {
              myConfirmDilaogWithPolicy(context, message,
                  title: "فشل انشاء رحلة",
                  onConfirm: gotoVerfiyUser,
                  onCancel: gotoHome);
            }
            showMySnackBar(context, state.message);
          }
        },
        child: Padding(
          padding: EdgeInsets.only(top: 180.h, left: 20.w, right: 20.w),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.mobileScreen,
                      size: 50,
                      color: MyColors.accent,
                    ),
                    SizedBox(height: 50.h),
                    const Text("رقم الهاتف للتواصل", style: font18boldramdi),
                    const SizedBox(height: 20),
                    const Text(
                      "سيستخدم هذا الرقم للتواصل مع الزبائن حول تفاصيل الرحلة",
                      style: font13normaldgrey,
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<PushRideCubit, PushRideState>(
                      builder: (context, state) {
                        final isValid = state is PushRideValidatePhoneState
                            ? state.isValid
                            : false;

                        return TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "أدخل رقم الهاتف",
                            suffixIcon: Icon(
                              Icons.check_circle,
                              color: isValid
                                  ? MyColors.primaryText
                                  : MyColors.accent,
                            ),
                            prefixIcon:
                                const Icon(Icons.phone, color: MyColors.accent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            hintText: "مثال: 091234567",
                          ),
                          validator: (value) =>
                              inputvaild(value!, "nubmerphone", 10, 10),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    BlocBuilder<PushRideCubit, PushRideState>(
                      builder: (context, state) {
                        final isLoading = state is PushRideLoading;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      tripFrom.numberPhone =
                                          _phoneController.text;
                                      context
                                          .read<PushRideCubit>()
                                          .pushRide(tripFrom);
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "حفظ والمتابعة",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void gotoVerfiyUser() {
    Get.toNamed(RouteName.verfiyUser, arguments: "driver");
  }

  void gotoHome() {
    Get.offAllNamed(RouteName.home);
  }
}
