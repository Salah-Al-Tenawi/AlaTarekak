import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';
import 'package:alatarekak/features/support/domain/repo/support_repo.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'complaint_state.dart';

class ComplaintCubit extends SafeCubit<ComplaintState> {
  final SupportRepo _repo;

  ComplaintCubit(this._repo) : super(const ComplaintInitial());

  static const maxAttachments = 3;
  static const maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const allowedExtensions = {'jpeg', 'jpg', 'png', 'pdf'};

  /// نصوص أخطاء 422 الحقلية (جدول §1 من مواصفة الوحدة)
  static const _fieldErrors = <String, String>{
    'title': 'يرجى إدخال عنوان الشكوى (بحد أقصى 255 حرفاً)',
    'description': 'يرجى كتابة وصف الشكوى (بحد أقصى 2000 حرف)',
    'type': 'يرجى اختيار نوع الشكوى',
    'attachments': 'يمكن إرفاق 3 ملفات كحد أقصى',
  };
  static const _attachmentFileError =
      'يجب أن يكون المرفق صورة (JPG/PNG) أو ملف PDF بحجم لا يتجاوز 5 ميغابايت';

  /// تحقق محلي قبل الرفع (توفير رفع multipart بلا فائدة).
  /// يرجع رسالة الخطأ أو null إذا سليم.
  Future<String?> validateAttachments(List<XFile> attachments) async {
    if (attachments.length > maxAttachments) {
      return _fieldErrors['attachments'];
    }
    for (final file in attachments) {
      final ext = file.name.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(ext)) return _attachmentFileError;
      if (await File(file.path).length() > maxFileSizeBytes) {
        return _attachmentFileError;
      }
    }
    return null;
  }

  Future<void> submitComplaint({
    required String title,
    required String description,
    required ComplaintType type,
    List<XFile> attachments = const [],
  }) async {
    // تحقق محلي أولاً
    if (title.trim().isEmpty) {
      emit(ComplaintFailure(_fieldErrors['title']!));
      return;
    }
    if (description.trim().isEmpty) {
      emit(ComplaintFailure(_fieldErrors['description']!));
      return;
    }
    final attachmentError = await validateAttachments(attachments);
    if (attachmentError != null) {
      emit(ComplaintFailure(attachmentError));
      return;
    }

    emit(const ComplaintSubmitting());

    final result = await _repo.submitComplaint(
      title: title.trim(),
      description: description.trim(),
      type: type,
      attachments: attachments,
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(ComplaintFailure(_translate(failure))),
      (complaint) => emit(ComplaintSuccess(complaint)),
    );
  }

  /// 422 يأتي بلا message — فقط errors بمفاتيح حقول
  /// (مفاتيح الملفات تصل كـ attachments.0, attachments.1 ...)
  String _translate(Filuar failure) {
    if (failure.isValidation) {
      final field = failure.errors!.keys.first;
      if (field.startsWith('attachments.')) return _attachmentFileError;
      return _fieldErrors[field] ?? HandelErorrMessage.errValidation;
    }
    return HandelErorrMessage.complaint(failure.message);
  }
}
