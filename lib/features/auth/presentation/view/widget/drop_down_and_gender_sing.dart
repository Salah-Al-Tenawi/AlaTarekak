import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/core/constant/address.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/auth/presentation/manger/singin_cubit/singin_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class DropDownAndGenderSing extends StatelessWidget {
  const DropDownAndGenderSing({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SinginCubit, SinginState>(
      builder: (context, state) {
        final cubit = context.read<SinginCubit>();

        return Column(
          children: [
            /// المحافظة
            DropdownButtonFormField<String>(
              value: (cubit.address == null || cubit.address!.isEmpty)
    ? null
    : cubit.address,
              decoration: InputDecoration(
                hintText: "المحافظة",
                suffixIcon: Icon(
                  Icons.keyboard_arrow_down,
                  color: MyColors.textHint,
                ),
              ),
              items: syrianProvinces.map((province) {
                return DropdownMenuItem(
                  value: province,
                  child: Text(province),
                );
              }).toList(),
              validator: (val) =>
                  val == null || val.isEmpty
                      ? "الرجاء اختيار المحافظة"
                      : null,
              onChanged: (val) {
                cubit.changAddress(val!);
              },
            ),

            SizedBox(height: 14.h),

            /// الجنس
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: MyColors.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () {
                        cubit.emitChangeGender("M");
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          color: cubit.gender == "M"
                              ? MyColors.primary.withOpacity(.08)
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.male,
                              color: cubit.gender == "M"
                                  ? MyColors.primary
                                  : MyColors.textHint,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              "ذكر",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cubit.gender == "M"
                                    ? MyColors.primary
                                    : MyColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () {
                        cubit.emitChangeGender("F");
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          color: cubit.gender == "F"
                              ? MyColors.primary.withOpacity(.08)
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.female,
                              color: cubit.gender == "F"
                                  ? MyColors.primary
                                  : MyColors.textHint,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              "أنثى",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cubit.gender == "F"
                                    ? MyColors.primary
                                    : MyColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}