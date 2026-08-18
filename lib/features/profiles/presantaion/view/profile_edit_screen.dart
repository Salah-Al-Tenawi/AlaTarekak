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
import 'package:alatarekak/core/utils/functions/input_valid.dart';
import 'package:alatarekak/core/utils/widgets/loading_widget_size_150.dart';
import 'package:alatarekak/core/utils/widgets/province_picker.dart';
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

  /// الاسم الكامل — يُعرض القديم في الحقل ليُعدَّل لا ليُكتب من جديد.
  late final TextEditingController _nameCtrl;

  /// خطأ الاسم يُعرض تحت حقله لا في شريط منبثق يختفي.
  String? _nameError;

  // Address: اختيار من قائمة المحافظات
  String? _selectedAddress;

  XFile? _userPhoto;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.profile.description);
    _nameCtrl = TextEditingController(text: widget.profile.fullname);

    // نحدد المحافظة المحفوظة إذا كانت ضمن القائمة
    final saved = widget.profile.address;
    _selectedAddress =
        syrianProvinces.contains(saved) ? saved : null;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) setState(() => _userPhoto = picked);
  }

  Future<void> _openAddressPicker() async {
    final picked =
        await showProvincePicker(context, selected: _selectedAddress);
    if (picked != null) setState(() => _selectedAddress = picked);
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final error = validateFullName(name);
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    setState(() => _nameError = null);

    final cubit = context.read<ProfileCubit>();
    if (_userPhoto != null) {
      cubit.pickImage(_userPhoto!, ProfileImagePicMode.user);
    }
    cubit.applyEdit(
      description: _descCtrl.text.trim(),
      address: _selectedAddress ?? widget.profile.address,
      // الجنس لم يعد يُعدَّل — يُمرَّر كما هو فلا يُمحى من الملف
      gender: widget.profile.gender,
      fullName: name,
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
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_forward_ios_rounded,
                  size: 20),
              onPressed: () => Get.back(),
            ),
            title: Text('تعديل المعلومات الشخصية',
                style: AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
            centerTitle: true,
            actions: [
              if (!isLoading)
                TextButton(
                  onPressed: _save,
                  child: Text('حفظ',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: MyColors.textOnDark)),
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
                      // الاسم
                      _FieldLabel(
                          label: 'الاسم',
                          icon: Icons.badge_outlined),
                      Padding(
                        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _nameCtrl,
                              textDirection: TextDirection.rtl,
                              textInputAction: TextInputAction.next,
                              style: AppTextStyles.bodyMedium,
                              decoration: _inputDec('الاسم الأول واسم العائلة'),
                              onChanged: (_) {
                                if (_nameError != null) {
                                  setState(() => _nameError = null);
                                }
                              },
                            ),
                            if (_nameError != null)
                              Padding(
                                padding: EdgeInsets.only(top: 6.h, right: 4.w),
                                child: Text(
                                  _nameError!,
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: MyColors.error),
                                ),
                              ),
                          ],
                        ),
                      ),

                      _divider(),

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
                                Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: MyColors.textHint,
                                    size: 20),
                              ],
                            ),
                          ),
                        ),
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
  _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
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
