import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/support/data/data_source/support_remote_data_source.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';
import 'package:alatarekak/features/support/domain/entity/contact_request_entity.dart';
import 'package:alatarekak/features/support/domain/repo/support_repo.dart';

class SupportRepoIm extends SupportRepo {
  final SupportRemoteDataSourceIm remoteDataSource;

  SupportRepoIm({required this.remoteDataSource});

  @override
  Future<Either<Filuar, ComplaintEntity>> submitComplaint(
    String description,
    ComplaintType type,
    List<XFile> attachments,
  ) async {
    try {
      final result = await remoteDataSource.submitComplaint(
          description, type, attachments);
      return right(result);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, List<ComplaintEntity>>> getComplaints() async {
    try {
      final result = await remoteDataSource.getComplaints();
      return right(result);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, ContactRequestEntity>> requestContactSupport() async {
    try {
      final result = await remoteDataSource.requestContactSupport();
      return right(result);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
