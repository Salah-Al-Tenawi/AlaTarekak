import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/functions/show_image.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/profiles/domain/entity/car_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';

class ProfileMyCarsScreen extends StatelessWidget {
  const ProfileMyCarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileErrorState) {
          AppSnackBar.error(state.message);
        }
      },
      builder: (context, state) {
        if (state is ProfileLoadingState) {
          return const Scaffold(
            body: Center(child: LoadingWidgetSize150()),
          );
        }

        final profile = state.profileEntity;
        final car = profile?.car;

        return Scaffold(
          backgroundColor: MyColors.background,
          appBar: AppBar(
            backgroundColor: MyColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  color: MyColors.primary, size: 20),
              onPressed: () => Get.back(result: true),
            ),
            title: Text('مركباتي', style: AppTextStyles.titleMedium),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              children: [
                if (car != null)
                  // ━━ بطاقة السيارة الحالية ━━
                  _CarDisplayCard(
                    car: car,
                    onEdit: () => _openCarForm(context, car),
                  )
                else
                  // ━━ حالة فارغة ━━
                  _EmptyCarState(
                    onAdd: () => _openCarForm(context, null),
                  ),

                SizedBox(height: 20.h),

                // ━━ زر إضافة/تعديل ━━
                _ActionButton(
                  hasCar: car != null,
                  onTap: () => _openCarForm(context, car),
                ),

                SizedBox(height: 20.h),

                _WhySection(),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCarForm(BuildContext context, CarEntity? current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ProfileCubit>(),
        child: _CarFormSheet(currentCar: current),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Car Display Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _CarDisplayCard extends StatelessWidget {
  final CarEntity car;
  final VoidCallback onEdit;
  const _CarDisplayCard({required this.car, required this.onEdit});

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
              offset: Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ━━ صورة السيارة ━━
          GestureDetector(
            onTap: () => openImage(car.image ?? ImagesUrl.defualtCar),
            child: car.image != null
                ? Image.network(
                    car.image!,
                    height: 180.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),

          // ━━ تفاصيل السيارة ━━
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // النوع واللون
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (car.type != null && car.type!.isNotEmpty)
                            Text(car.type!,
                                style: AppTextStyles.titleMedium),
                          if (car.color != null && car.color!.isNotEmpty)
                            Text(car.color!,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: MyColors.textSecondary)),
                        ],
                      ),
                    ),
                    // زر التعديل
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color:
                              MyColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined,
                                size: 16, color: MyColors.primary),
                            SizedBox(width: 4.w),
                            Text('تعديل',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: MyColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),
                const Divider(height: 0, thickness: 0.5),
                SizedBox(height: 10.h),

                // المواصفات
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    if (car.seats != null)
                      _SpecChip(
                        icon: Icons.event_seat_rounded,
                        label: '${car.seats} مقاعد',
                      ),
                    _SpecChip(
                      icon: Icons.radio_rounded,
                      label: car.hasRadio ? 'راديو' : 'بدون راديو',
                      active: car.hasRadio,
                    ),
                    _SpecChip(
                      icon: Icons.smoking_rooms_rounded,
                      label: car.allowsSmoking
                          ? 'تدخين مسموح'
                          : 'بدون تدخين',
                      active: car.allowsSmoking,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180.h,
      width: double.infinity,
      color: MyColors.surfaceAlt,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 52, color: MyColors.textHint),
          SizedBox(height: 8.h),
          Text('لا توجد صورة',
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textHint)),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Empty State
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _EmptyCarState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCarState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: MyColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car_outlined,
                size: 36, color: MyColors.primary),
          ),
          SizedBox(height: 14.h),
          Text('لم تُضف مركبة بعد',
              style: AppTextStyles.titleMedium
                  .copyWith(color: MyColors.textPrimary)),
          SizedBox(height: 6.h),
          Text('أضف مركبتك لتتمكن من نشر الرحلات',
              style: AppTextStyles.bodySmall
                  .copyWith(color: MyColors.textSecondary)),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Action Button
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _ActionButton extends StatelessWidget {
  final bool hasCar;
  final VoidCallback onTap;
  const _ActionButton({required this.hasCar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: hasCar ? MyColors.surface : MyColors.primary,
          borderRadius: BorderRadius.circular(14),
          border: hasCar
              ? Border.all(
                  color: MyColors.primary.withValues(alpha: 0.4),
                  width: 1.5)
              : null,
          boxShadow: hasCar
              ? null
              : [
                  BoxShadow(
                    color: MyColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasCar ? Icons.edit_outlined : Icons.add_circle_outline_rounded,
              color: hasCar ? MyColors.primary : Colors.white,
              size: 20,
            ),
            SizedBox(width: 8.w),
            Text(
              hasCar ? 'تعديل معلومات المركبة' : 'إضافة مركبة جديدة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: hasCar ? MyColors.primary : Colors.white,
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
// Spec Chip
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _SpecChip(
      {required this.icon, required this.label, this.active = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
          color: active
              ? MyColors.primary.withValues(alpha: 0.07)
              : MyColors.background,
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: active ? MyColors.primary : MyColors.textHint),
          SizedBox(width: 5.w),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                  color: active
                      ? MyColors.textPrimary
                      : MyColors.textHint)),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Car Form Bottom Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _CarFormSheet extends StatefulWidget {
  final CarEntity? currentCar;
  const _CarFormSheet({this.currentCar});

  @override
  State<_CarFormSheet> createState() => _CarFormSheetState();
}

class _CarFormSheetState extends State<_CarFormSheet> {
  late final TextEditingController _typeCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _seatsCtrl;

  bool _hasRadio = false;
  bool _allowsSmoking = false;
  XFile? _carPhoto;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final car = widget.currentCar;
    _typeCtrl = TextEditingController(text: car?.type ?? '');
    _colorCtrl = TextEditingController(text: car?.color ?? '');
    _seatsCtrl =
        TextEditingController(text: car?.seats?.toString() ?? '');
    _hasRadio = car?.hasRadio ?? false;
    _allowsSmoking = car?.allowsSmoking ?? false;
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _colorCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) setState(() => _carPhoto = picked);
  }

  void _save() {
    final type = _typeCtrl.text.trim();
    final color = _colorCtrl.text.trim();
    final seats = int.tryParse(_seatsCtrl.text.trim());

    setState(() => _isSaving = true);

    context.read<ProfileCubit>().saveCar(
          CarEntity(
            type: type.isEmpty ? null : type,
            color: color.isEmpty ? null : color,
            seats: seats,
            hasRadio: _hasRadio,
            allowsSmoking: _allowsSmoking,
            image: widget.currentCar?.image,
          ),
          _carPhoto,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (!_isSaving) return;
        if (state is ProfileLoadedState) {
          setState(() => _isSaving = false);
          Navigator.pop(context);
          AppSnackBar.success('تم حفظ معلومات المركبة بنجاح');
        } else if (state is ProfileErrorState) {
          setState(() => _isSaving = false);
          AppSnackBar.error(state.message);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: MyColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding:
              EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: MyColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              SizedBox(height: 18.h),

              // Title
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: MyColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_car_outlined,
                        color: MyColors.primary, size: 18),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    widget.currentCar != null
                        ? 'تعديل المركبة'
                        : 'إضافة مركبة',
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // ━━ صورة السيارة ━━
              _PhotoPickerRow(
                xFile: _carPhoto,
                existingUrl: widget.currentCar?.image,
                onTap: _pickPhoto,
              ),

              SizedBox(height: 16.h),

              // ━━ الحقول ━━
              _FormField(
                label: 'نوع السيارة',
                hint: 'مثال: Toyota Camry',
                icon: Icons.directions_car_rounded,
                controller: _typeCtrl,
              ),
              SizedBox(height: 12.h),
              _FormField(
                label: 'اللون',
                hint: 'مثال: أبيض',
                icon: Icons.color_lens_outlined,
                controller: _colorCtrl,
              ),
              SizedBox(height: 12.h),
              _FormField(
                label: 'عدد المقاعد',
                hint: '4',
                icon: Icons.event_seat_rounded,
                controller: _seatsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
              ),

              SizedBox(height: 8.h),

              // ━━ Switches ━━
              _SwitchRow(
                icon: Icons.radio_rounded,
                label: 'يوجد راديو',
                value: _hasRadio,
                onChanged: (v) => setState(() => _hasRadio = v),
              ),
              _SwitchRow(
                icon: Icons.smoking_rooms_rounded,
                label: 'السماح بالتدخين',
                value: _allowsSmoking,
                onChanged: (v) => setState(() => _allowsSmoking = v),
              ),

              SizedBox(height: 20.h),

              // ━━ زر الحفظ ━━
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.primary,
                    disabledBackgroundColor:
                        MyColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'حفظ المركبة',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Photo Picker Row
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _PhotoPickerRow extends StatelessWidget {
  final XFile? xFile;
  final String? existingUrl;
  final VoidCallback onTap;
  const _PhotoPickerRow(
      {required this.xFile,
      required this.existingUrl,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: MyColors.background,
          border: Border.all(
              color: MyColors.border.withValues(alpha: 0.8), width: 1.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (xFile != null) {
      return Image.file(File(xFile!.path),
          fit: BoxFit.cover, width: double.infinity);
    }
    if (existingUrl != null) {
      return Image.network(existingUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, _, _) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 28, color: MyColors.textHint),
        SizedBox(width: 8),
        Text('صورة السيارة (اختياري)',
            style: AppTextStyles.labelSmall
                .copyWith(color: MyColors.textHint)),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Form Field
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;

  const _FormField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: MyColors.textSecondary),
            SizedBox(width: 5),
            Text(label,
                style: AppTextStyles.labelSmall
                    .copyWith(color: MyColors.textSecondary)),
          ],
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium
                .copyWith(color: MyColors.textHint),
            filled: true,
            fillColor: MyColors.background,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Switch Row
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: MyColors.primary,
          activeTrackColor: MyColors.primary.withValues(alpha: 0.35),
        ),
        SizedBox(width: 6.w),
        Icon(icon, size: 17, color: MyColors.textSecondary),
        SizedBox(width: 6.w),
        Text(label, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Why Section
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _WhySection extends StatelessWidget {
  const _WhySection();

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
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: MyColors.accentLight,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.info_outline_rounded,
                    color: MyColors.accent, size: 18),
              ),
              SizedBox(width: 10.w),
              Text('لماذا تُضيف مركبة؟',
                  style: AppTextStyles.labelLarge),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(height: 0, thickness: 0.5),
          SizedBox(height: 12.h),
          _Point(
            icon: Icons.people_outline_rounded,
            text: 'يزيد من ثقة الركاب بك كسائق',
          ),
          SizedBox(height: 8.h),
          _Point(
            icon: Icons.directions_car_rounded,
            text: 'تتمكن من نشر رحلات بتفاصيل واضحة',
          ),
          SizedBox(height: 8.h),
          _Point(
            icon: Icons.star_outline_rounded,
            text: 'يرفع ترتيبك في نتائج البحث',
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Point({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: MyColors.primary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodySmall
                  .copyWith(color: MyColors.textSecondary)),
        ),
      ],
    );
  }
}