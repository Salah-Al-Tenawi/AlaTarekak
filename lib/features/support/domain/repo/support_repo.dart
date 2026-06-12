import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';
import 'package:alatarekak/features/support/domain/entity/contact_request_entity.dart';

abstract class SupportRepo {
  Future<Either<Filuar, ComplaintEntity>> submitComplaint(
    String description,
    ComplaintType type,
    List<XFile> attachments,
  );

  Future<Either<Filuar, List<ComplaintEntity>>> getComplaints();

  Future<Either<Filuar, ContactRequestEntity>> requestContactSupport();
}
