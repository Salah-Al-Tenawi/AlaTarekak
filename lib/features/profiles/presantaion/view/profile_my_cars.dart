import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/profiles/domain/entity/user_car_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/my_cars_cubit/my_cars_cubit.dart';

class ProfileMyCarsScreen extends StatefulWidget {
  const ProfileMyCarsScreen({super.key});

  @override
  State<ProfileMyCarsScreen> createState() => _ProfileMyCarsScreenState();
}

class _ProfileMyCarsScreenState extends State<ProfileMyCarsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MyCarsScreenCubit>().getMyCars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded,
              color: MyColors.primary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text("مركباتي المسجلة", style: AppTextStyles.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: MyColors.primary, size: 22),
            onPressed: () =>
                context.read<MyCarsScreenCubit>().getMyCars(),
          ),
        ],
      ),
      body: BlocConsumer<MyCarsScreenCubit, MyCarsState>(
        listener: (context, state) {
          if (state is MyCarsError) {
            AppSnackBar.error(state.message);
          }
        },
        builder: (context, state) {
          if (state is MyCarsLoading) {
            return const Center(child: LoadingWidgetSize150());
          }

          final cars =
              state is MyCarsLoaded ? state.cars : <UserCarEntity>[];

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ━━ زر إضافة مركبة ━━
                _AddCarButton(),

                SizedBox(height: 20.h),

                // ━━ قائمة المركبات ━━
                if (cars.isEmpty)
                  _EmptyState()
                else
                  ...cars.map((car) => Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: _CarCard(car: car),
                      )),

                SizedBox(height: 8.h),

                // ━━ لماذا التحقق ━━
                _WhyVerifySection(),

                SizedBox(height: 24.h),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Add Car Button
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _AddCarButton extends StatelessWidget {
  const _AddCarButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: navigate to add car screen
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: MyColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MyColors.accent, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: MyColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10.w),
            Text(
              "إضافة مركبة جديدة",
              style: AppTextStyles.bodyMedium.copyWith(
                color: MyColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Car Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _CarCard extends StatelessWidget {
  final UserCarEntity car;
  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ━━ صورة السيارة ━━
          _CarImage(imageUrl: car.image),

          // ━━ تفاصيل السيارة ━━
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ━━ الاسم ورقم اللوحة ━━
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        car.name,
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: MyColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: MyColors.border, width: 1),
                      ),
                      child: Text(
                        car.plateNumber,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: MyColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                // ━━ المواصفات ━━
                Row(
                  children: [
                    if (car.fuelType != null) ...[
                      _SpecChip(
                        icon: Icons.local_gas_station_outlined,
                        label: car.fuelType!,
                      ),
                      SizedBox(width: 8.w),
                    ],
                    if (car.engineSize != null)
                      _SpecChip(
                        icon: Icons.settings_outlined,
                        label: "${car.engineSize!} L",
                      ),
                    const Spacer(),
                    // ━━ حالة التحقق ━━
                    _VerificationBadge(isVerified: car.isVerified),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Car Image
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _CarImage extends StatelessWidget {
  final String? imageUrl;
  const _CarImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        height: 160.h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: 160.h,
      width: double.infinity,
      color: MyColors.surfaceAlt,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 48, color: MyColors.textHint),
          SizedBox(height: 6.h),
          Text(
            "لا توجد صورة",
            style: AppTextStyles.labelSmall
                .copyWith(color: MyColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Spec Chip
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: MyColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: MyColors.textSecondary),
          SizedBox(width: 4.w),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary)),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Verification Badge
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _VerificationBadge extends StatelessWidget {
  final bool isVerified;
  const _VerificationBadge({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    if (isVerified) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: MyColors.successLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded,
                size: 14, color: MyColors.success),
            SizedBox(width: 4.w),
            Text(
              "موثقة",
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.success),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // TODO: navigate to verification screen
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: MyColors.accentLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined,
                size: 14, color: MyColors.accent),
            SizedBox(width: 4.w),
            Text(
              "تحقق الآن",
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Empty State
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          Icon(Icons.directions_car_outlined,
              size: 64, color: MyColors.textHint),
          SizedBox(height: 12.h),
          Text(
            "لا توجد مركبات مسجلة",
            style: AppTextStyles.bodyMedium
                .copyWith(color: MyColors.textSecondary),
          ),
          SizedBox(height: 6.h),
          Text(
            "أضف مركبتك للبدء بنشر الرحلات",
            style: AppTextStyles.bodySmall
                .copyWith(color: MyColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Why Verify Section
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _WhyVerifySection extends StatelessWidget {
  const _WhyVerifySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: MyColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ━━ عنوان ━━
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: MyColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: MyColors.accent, size: 20),
              ),
              SizedBox(width: 10.w),
              Text(
                "لماذا التحقق من المركبة؟",
                style: AppTextStyles.labelLarge,
              ),
            ],
          ),

          SizedBox(height: 12.h),

          const Divider(height: 0, thickness: 0.5),

          SizedBox(height: 12.h),

          // ━━ النقاط ━━
          _VerifyPoint(
            icon: Icons.people_outline_rounded,
            text: "يزيد من ثقة الركاب بك كسائق موثوق",
          ),
          SizedBox(height: 8.h),
          _VerifyPoint(
            icon: Icons.star_outline_rounded,
            text: "يرفع ترتيبك في نتائج البحث",
          ),
          SizedBox(height: 8.h),
          _VerifyPoint(
            icon: Icons.security_outlined,
            text: "يضمن بيئة تنقل آمنة للجميع",
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Verify Point
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _VerifyPoint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _VerifyPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: MyColors.primary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall
                .copyWith(color: MyColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
