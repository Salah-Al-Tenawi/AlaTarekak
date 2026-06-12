import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  const TripAddNumberPhone({
    super.key,
    this.tripFrom,
    this.onBack,
    this.isEmbedded = false,
    this.onNext,
  });

  final TripFrom? tripFrom;
  final VoidCallback? onBack;
  final void Function(TripFrom)? onNext;
  /// true when used inside TripCreateWizard (no Scaffold, no duplicate back button)
  final bool isEmbedded;

  @override
  State<TripAddNumberPhone> createState() => _TripAddNumberPhoneState();
}

class _TripAddNumberPhoneState extends State<TripAddNumberPhone> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late TripFrom _tripFrom;

  @override
  void initState() {
    super.initState();
    if (widget.tripFrom != null) {
      _tripFrom = widget.tripFrom!;
    } else {
      _tripFrom = Get.arguments as TripFrom;
    }

    if (_tripFrom.numberPhone != null) {
      _phoneController.text = _tripFrom.numberPhone!;
      context.read<PushRideCubit>().validatePhone(_tripFrom.numberPhone!);
    }

    _phoneController.addListener(
      () => context.read<PushRideCubit>().validatePhone(_phoneController.text),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _tripFrom.numberPhone = _phoneController.text;
    if (widget.onNext != null) {
      widget.onNext!(_tripFrom);
    } else {
      context.read<PushRideCubit>().pushRide(_tripFrom);
    }
  }

  void _goToVerify() =>
      Get.toNamed(RouteName.verfiyUser, arguments: "driver");

  void _goHome() => Get.offAllNamed(RouteName.home);

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    // Wizard mode: no Scaffold, no BlocListener (review page handles API)
    if (widget.onNext != null) return body;

    // Standalone mode: wrap with Scaffold + AppBar
    if (!widget.isEmbedded) {
      return BlocListener<PushRideCubit, PushRideState>(
        listener: _onState,
        child: Scaffold(
          backgroundColor: MyColors.background,
          appBar: AppBar(
            backgroundColor: MyColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  color: MyColors.primary, size: 20),
              onPressed: () => Get.back(),
            ),
            title:
                Text("إضافة رحلة جديدة", style: AppTextStyles.titleMedium),
            centerTitle: true,
          ),
          body: body,
        ),
      );
    }

    // Embedded (wizard) mode: no Scaffold, with BlocListener
    return BlocListener<PushRideCubit, PushRideState>(
      listener: _onState,
      child: body,
    );
  }

  void _onState(BuildContext context, PushRideState state) {
    if (state is PushRideSuccsess) {
      Get.offAllNamed(RouteName.tripDidYouBack, arguments: _tripFrom);
    } else if (state is PushRideErorr) {
      final message = HandelErorrMessage.createWithRoute(state.message);
      final needsVerification =
          state.message.contains("You must be verified as a driver") ||
              state.message.contains("Missing required verification");
      if (needsVerification) {
        myConfirmDilaogWithPolicy(
          context,
          message,
          title: "فشل إنشاء الرحلة",
          onConfirm: _goToVerify,
          onCancel: _goHome,
        );
      } else {
        showMySnackBar(context, state.message);
      }
    }
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 16.h),
                  Container(
                    width: 80.r,
                    height: 80.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MyColors.primary.withValues(alpha: 0.08),
                    ),
                    child: Icon(Icons.phone_android_rounded,
                        size: 40.sp, color: MyColors.primary),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "رقم التواصل",
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "سيُستخدم هذا الرقم للتواصل مع الركاب حول تفاصيل الرحلة",
                    style: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 28.h),
                  BlocBuilder<PushRideCubit, PushRideState>(
                    buildWhen: (_, curr) => curr is PushRideValidatePhoneState,
                    builder: (context, state) {
                      final isValid = state is PushRideValidatePhoneState
                          ? state.isValid
                          : false;
                      return TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: "رقم الهاتف",
                          hintText: "09XXXXXXXX",
                          prefixIcon: const Icon(Icons.phone_outlined,
                              color: MyColors.accent),
                          suffixIcon: Icon(
                            isValid
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isValid ? MyColors.success : MyColors.textHint,
                          ),
                          filled: true,
                          fillColor: MyColors.surface,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide:
                                  const BorderSide(color: MyColors.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide:
                                  const BorderSide(color: MyColors.border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: const BorderSide(
                                  color: MyColors.primary, width: 1.5)),
                        ),
                        validator: (v) => inputvaild(v!, "nubmerphone", 10, 10),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        _SubmitBar(
          onSubmit: _submit,
          onBack: widget.onBack,
          isWizardMode: widget.onNext != null,
        ),
      ],
    );
  }
}

// ─── Submit bar ───────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final VoidCallback onSubmit;
  final VoidCallback? onBack;
  final bool isWizardMode;
  const _SubmitBar({
    required this.onSubmit,
    this.onBack,
    this.isWizardMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isWizardMode) {
      return Container(
        color: MyColors.surface,
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        child: Row(
          children: [
            if (onBack != null) ...[
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MyColors.primary,
                    side: const BorderSide(color: MyColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                    minimumSize: Size(double.infinity, 52.h),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 18.sp),
                ),
              ),
              SizedBox(width: 10.w),
            ],
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                  minimumSize: Size(double.infinity, 52.h),
                  elevation: 0,
                ),
                icon: Icon(Icons.arrow_back_rounded, size: 20.sp),
                label: Text("التالي", style: AppTextStyles.buttonLarge),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: MyColors.surface,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: BlocBuilder<PushRideCubit, PushRideState>(
        buildWhen: (prev, curr) =>
            curr is PushRideLoading || curr is PushRideInitial,
        builder: (context, state) {
          final isLoading = state is PushRideLoading;
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                    minimumSize: Size(double.infinity, 52.h),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 24.r,
                          height: 24.r,
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text("حفظ ونشر الرحلة",
                          style: AppTextStyles.buttonLarge),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
