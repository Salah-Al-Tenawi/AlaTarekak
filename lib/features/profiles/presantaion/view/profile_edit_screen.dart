import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/constant/address.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/features/profiles/data/model/enum/image_mode.dart';
import 'package:alatarekak/features/profiles/data/model/enum/profile_mode.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/presantaion/manger/profile_cubit.dart';

class ProfileEditScreen extends StatefulWidget {
  final ProfileEntity profile;
  const ProfileEditScreen({super.key, required this.profile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _descCtrl;

  // Gender: API يقبل 'M' أو 'F' فقط
  String _gender = 'M';

  // Address: اختيار من قائمة المحافظات
  String? _selectedAddress;

  XFile? _userPhoto;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.profile.description);

    // نعيد إلى uppercase لضمان التوافق مع الـ API
    final g = widget.profile.gender.toUpperCase();
    _gender = (g == 'M' || g == 'F') ? g : 'M';

    // نحدد المحافظة المحفوظة إذا كانت ضمن القائمة
    final saved = widget.profile.address;
    _selectedAddress =
        syrianProvinces.contains(saved) ? saved : null;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) setState(() => _userPhoto = picked);
  }

  void _openAddressPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddressSheet(
        selected: _selectedAddress,
        onSelect: (v) => setState(() => _selectedAddress = v),
      ),
    );
  }

  void _save() {
    final cubit = context.read<ProfileCubit>();
    if (_userPhoto != null) {
      cubit.pickImage(_userPhoto!, ProfileImagePicMode.user);
    }
    cubit.applyEdit(
      description: _descCtrl.text.trim(),
      address: _selectedAddress ?? widget.profile.address,
      gender: _gender, // 'M' أو 'F'
    );
    cubit.saveMyProfile();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoadedState &&
            state.mode == ProfileMode.myView) {
          Get.back(result: true);
          AppSnackBar.success('تم حفظ التغييرات بنجاح');
        } else if (state is ProfileErrorState) {
          AppSnackBar.error(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is ProfileLoadingState;

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
            title: Text('تعديل المعلومات الشخصية',
                style: AppTextStyles.titleMedium),
            centerTitle: true,
            actions: [
              if (!isLoading)
                TextButton(
                  onPressed: _save,
                  child: Text('حفظ',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: MyColors.primary)),
                ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 20.h),
                child: Column(
                  children: [
                    // ━━ صورة الملف الشخصي ━━
                    _PhotoPicker(
                      xFile: _userPhoto,
                      existingUrl: widget.profile.profilePhoto,
                      onTap: _pickPhoto,
                    ),

                    SizedBox(height: 24.h),

                    // ━━ المعلومات ━━
                    _SectionCard(children: [
                      // نبذة عني
                      _FieldLabel(
                          label: 'نبذة عني',
                          icon: Icons.info_outline_rounded),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            14.w, 0, 14.w, 14.h),
                        child: TextField(
                          controller: _descCtrl,
                          maxLines: 3,
                          textDirection: TextDirection.rtl,
                          style: AppTextStyles.bodyMedium,
                          decoration: _inputDec(
                              'أكتب شيئاً عن نفسك...'),
                        ),
                      ),

                      _divider(),

                      // العنوان — اختيار من قائمة
                      _FieldLabel(
                          label: 'العنوان',
                          icon: Icons.location_on_outlined),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            14.w, 0, 14.w, 14.h),
                        child: GestureDetector(
                          onTap: _openAddressPicker,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 13.h),
                            decoration: BoxDecoration(
                              color: MyColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedAddress ??
                                        (widget.profile.address
                                                .isNotEmpty
                                            ? widget.profile.address
                                            : 'اختر المحافظة'),
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(
                                      color: _selectedAddress != null ||
                                              widget.profile.address
                                                  .isNotEmpty
                                          ? MyColors.textPrimary
                                          : MyColors.textHint,
                                    ),
                                  ),
                                ),
                                const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: MyColors.textHint,
                                    size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),

                      _divider(),

                      // الجنس
                      _GenderPicker(
                        selected: _gender,
                        onChanged: (v) =>
                            setState(() => _gender = v),
                      ),
                    ]),

                    SizedBox(height: 24.h),

                    _SaveButton(onTap: _save),

                    SizedBox(height: 32.h),
                  ],
                ),
              ),

              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: LoadingWidgetSize150()),
                ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium
            .copyWith(color: MyColors.textHint),
        filled: true,
        fillColor: MyColors.background,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      );

  Widget _divider() =>
      const Divider(height: 0, thickness: 0.5, indent: 16, endIndent: 16);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Address Bottom Sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _AddressSheet extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _AddressSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
                color: MyColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: MyColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_outlined,
                    color: MyColors.primary, size: 17),
              ),
              SizedBox(width: 10.w),
              Text('اختر المحافظة',
                  style: AppTextStyles.titleMedium),
            ],
          ),
          SizedBox(height: 16.h),
          const Divider(height: 0, thickness: 0.5),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: syrianProvinces.length,
              separatorBuilder: (_, _) => const Divider(
                  height: 0, thickness: 0.5, indent: 16, endIndent: 16),
              itemBuilder: (ctx, i) {
                final province = syrianProvinces[i];
                final isSelected = province == selected;
                return ListTile(
                  title: Text(province,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected
                            ? MyColors.primary
                            : MyColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: MyColors.primary, size: 20)
                      : null,
                  onTap: () {
                    onSelect(province);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Photo Picker
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _PhotoPicker extends StatelessWidget {
  final XFile? xFile;
  final String? existingUrl;
  final VoidCallback onTap;
  const _PhotoPicker(
      {required this.xFile,
      required this.existingUrl,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: MyColors.primary.withValues(alpha: 0.2),
                    width: 3),
              ),
              child: CircleAvatar(
                radius: 52.r,
                backgroundColor: MyColors.background,
                backgroundImage: _image(),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: MyColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: MyColors.surface, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 15, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _image() {
    if (xFile != null) return FileImage(File(xFile!.path));
    if (existingUrl != null) return NetworkImage(existingUrl!);
    return const AssetImage(ImagesUrl.profileImage);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Section Card
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: children,
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Field Label
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FieldLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 6.h),
      child: Row(
        children: [
          Icon(icon, size: 14, color: MyColors.textSecondary),
          SizedBox(width: 5.w),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary)),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Gender Picker
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _GenderPicker extends StatelessWidget {
  final String selected; // 'M' أو 'F'
  final ValueChanged<String> onChanged;
  const _GenderPicker(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wc_rounded,
                  size: 14, color: MyColors.textSecondary),
              SizedBox(width: 5.w),
              Text('الجنس',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.textSecondary)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _GenderChip(
                label: 'ذكر',
                icon: Icons.male_rounded,
                isSelected: selected == 'M',
                onTap: () => onChanged('M'),
              ),
              SizedBox(width: 10.w),
              _GenderChip(
                label: 'أنثى',
                icon: Icons.female_rounded,
                isSelected: selected == 'F',
                onTap: () => onChanged('F'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _GenderChip(
      {required this.label,
      required this.icon,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? MyColors.primary.withValues(alpha: 0.1)
              : MyColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? MyColors.primary : MyColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 17,
                color: isSelected
                    ? MyColors.primary
                    : MyColors.textSecondary),
            SizedBox(width: 6.w),
            Text(label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? MyColors.primary
                      : MyColors.textSecondary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Save Button
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
          color: MyColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MyColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8.w),
            Text('حفظ التغييرات',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}