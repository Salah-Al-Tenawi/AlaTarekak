import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/support/data/data_source/support_local_data_source.dart';
import 'package:alatarekak/features/support/data/data_source/support_remote_data_source.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';
import 'package:alatarekak/features/support/domain/entity/contact_request_entity.dart';
import 'package:alatarekak/features/support/domain/repo/support_repo.dart';

class SupportRepoIm extends SupportRepo {
  final SupportRemoteDataSource remoteDataSource;
  final SupportLocalDataSource localDataSource;

  SupportRepoIm({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<Either<Filuar, T>> _guard<T>(Future<T> Function() task) async {
    try {
      return right(await task());
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  List<ComplaintEntity>? getCachedComplaints() =>
      localDataSource.getComplaints();

  @override
  Future<Either<Filuar, ComplaintEntity>> submitComplaint({
    required String title,
    required String description,
    required ComplaintType type,
    List<XFile> attachments = const [],
  }) =>
      _guard(() async {
        final complaint = await remoteDataSource.submitComplaint(
          title: title,
          description: description,
          type: type,
          attachments: attachments,
        );
        // الشكوى الجديدة تظهر في القائمة فوراً حتى بلا اتصال لاحق
        await localDataSource.prependComplaint(complaint);
        return complaint;
      });

  @override
  Future<Either<Filuar, List<ComplaintEntity>>> getComplaints() async {
    try {
      final list = await remoteDataSource.getComplaints();
      await localDataSource.saveComplaints(list);
      return right(list);
    } on ServerExpcptions catch (e) {
      final cached = localDataSource.getComplaints();
      if (cached != null) return right(cached);
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, ComplaintEntity>> getComplaint(int id) =>
      _guard(() => remoteDataSource.getComplaint(id));

  @override
  Future<Either<Filuar, SupportChatEntity>> openSupportChat() =>
      _guard(remoteDataSource.openSupportChat);
}
