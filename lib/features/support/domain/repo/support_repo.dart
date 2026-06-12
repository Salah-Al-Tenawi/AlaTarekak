import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';
import 'package:alatarekak/features/support/domain/entity/contact_request_entity.dart';

abstract class SupportRepo {
  /// آخر قائمة شكاوى مخزنة محلياً (للعرض الفوري) — null إن لم تُخزن
  List<ComplaintEntity>? getCachedComplaints();

  /// إرسال شكوى (multipart عند وجود مرفقات، حتى 3 ملفات)
  Future<Either<Filuar, ComplaintEntity>> submitComplaint({
    required String title,
    required String description,
    required ComplaintType type,
    List<XFile> attachments,
  });

  /// كل شكاوى المستخدم (بلا pagination)
  Future<Either<Filuar, List<ComplaintEntity>>> getComplaints();

  /// تفاصيل شكوى — شكوى الغير ترجع 404 (وليس 403) بالتصميم
  Future<Either<Filuar, ComplaintEntity>> getComplaint(int id);

  /// فتح/إيجاد محادثة الدعم — النقطة الوحيدة المسموحة أثناء الحظر
  Future<Either<Filuar, SupportChatEntity>> openSupportChat();
}
