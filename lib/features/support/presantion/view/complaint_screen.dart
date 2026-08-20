import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';
import 'package:alatarekak/features/support/presantion/manger/complaint_cubit/complaint_cubit.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<XFile> _attachments = [];
  ComplaintType? _selectedType;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_attachments.length >= 3) {
      AppSnackBar.error('الحد الأقصى 3 ملفات مرفقة');
      return;
    }
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file != null) setState(() => _attachments.add(file));
  }

  void _removeAttachment(int index) =>
      setState(() => _attachments.removeAt(index));

  void _submit(BuildContext context) {
    if (_selectedType == null) {
      AppSnackBar.error('يرجى اختيار نوع الشكوى');
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.error('يرجى إدخال عنوان الشكوى (بحد أقصى 255 حرفاً)');
      return;
    }
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      AppSnackBar.error('يرجى كتابة وصف الشكوى (بحد أقصى 2000 حرف)');
      return;
    }
    context.read<ComplaintCubit>().submitComplaint(
          title: title,
          description: desc,
          type: _selectedType!,
          attachments: _attachments,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ComplaintCubit, ComplaintState>(
      listener: (context, state) {
        if (state is ComplaintSuccess) {
          // الرجوع أولاً ثم الإشعار: Get.snackbar يدفع مساراً على
          // المتصفّح، فاستدعاء Get.back() بعده يُغلق الإشعار نفسه بدل
          // الشاشة فلا يرى المستخدم أي تأكيد.
          Get.back();
          AppSnackBar.success(
              'تم إرسال شكواك بنجاح، سيقوم فريق الدعم بمراجعتها قريباً');
        } else if (state is ComplaintFailure) {
          AppSnackBar.error(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: MyColors.background,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_ios_rounded,
                size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text('تقديم شكوى', style: AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ━━ نوع الشكوى ━━
              Text('نوع الشكوى', style: AppTextStyles.labelLarge),
              SizedBox(height: 10.h),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 8.h,
                childAspectRatio: 0.82,
                // القابل للإرسال وحده: «تعارض تقارير الغياب» يصنعه
                // النظام، ويرفضه `POST /complaints` بـ 422.
                children: ComplaintType.userSubmittable
                    .map((type) => _TypeCell(
                          type: type,
                          selected: _selectedType == type,
                          onTap: () =>
                              setState(() => _selectedType = type),
                        ))
                    .toList(),
              ),

              // تنبيه الأمان
              if (_selectedType == ComplaintType.tripSafety) ...[
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: MyColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: MyColors.error, size: 18),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'شكاوى الأمان تُعالَج بأولوية قصوى.',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: MyColors.error, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 20.h),

              // ━━ عنوان الشكوى ━━
              Text('عنوان الشكوى', style: AppTextStyles.labelLarge),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: MyColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MyColors.border),
                ),
                child: TextField(
                  controller: _titleController,
                  maxLength: 255,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'مثال: السائق تأخر عن الموعد',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textHint),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.all(14.w),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // ━━ وصف المشكلة ━━
              Text('وصف المشكلة', style: AppTextStyles.labelLarge),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: MyColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MyColors.border),
                ),
                child: TextField(
                  controller: _descController,
                  maxLines: 5,
                  minLines: 4,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'اشرح المشكلة بالتفصيل...',
                    hintStyle: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textHint),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14.w),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // ━━ المرفقات ━━
              Row(
                children: [
                  Text('المرفقات (اختياري)',
                      style: AppTextStyles.labelLarge),
                  SizedBox(width: 6.w),
                  Text('بحد أقصى 3',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: MyColors.textHint)),
                ],
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: [
                  ..._attachments.asMap().entries.map(
                        (e) => _AttachmentThumb(
                          file: e.value,
                          onRemove: () => _removeAttachment(e.key),
                        ),
                      ),
                  if (_attachments.length < 3)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 72.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          color: MyColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: MyColors.border),
                        ),
                        child: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: MyColors.textHint,
                            size: 28),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 32.h),

              // ━━ زر الإرسال ━━
              BlocBuilder<ComplaintCubit, ComplaintState>(
                builder: (context, state) {
                  final isLoading = state is ComplaintSubmitting;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          isLoading ? null : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(
                              'إرسال الشكوى',
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Type Cell
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _TypeCell extends StatelessWidget {
  final ComplaintType type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCell(
      {required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? type.color : MyColors.textHint;
    final bg = selected ? type.bgColor : MyColors.surface;
    final border = selected
        ? Border.all(color: type.color, width: 1.5)
        : Border.all(color: MyColors.border);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon, color: color, size: 22),
            SizedBox(height: 6.h),
            Text(
              type.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontSize: 9.5.sp,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Attachment Thumb
// ━━━━━━━━━━━━━━━━━━━━━━━━
class _AttachmentThumb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const _AttachmentThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(file.path),
            width: 72.w,
            height: 72.w,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: MyColors.error, shape: BoxShape.circle),
              child:
                  const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}
