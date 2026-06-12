import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/features/support/data/model/complaint_model.dart';
import 'package:alatarekak/features/support/data/model/contact_request_model.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';

abstract class SupportRemoteDataSource {
  final DioConSumer api;
  SupportRemoteDataSource({required this.api});

  Future<ComplaintModel> submitComplaint(
    String description,
    ComplaintType type,
    List<XFile> attachments,
  );

  Future<List<ComplaintModel>> getComplaints();

  Future<ContactRequestModel> requestContactSupport();
}

class SupportRemoteDataSourceIm extends SupportRemoteDataSource {
  SupportRemoteDataSourceIm({required super.api});

  @override
  Future<ComplaintModel> submitComplaint(
    String description,
    ComplaintType type,
    List<XFile> attachments,
  ) async {
    // TODO: implement when API is ready
    throw UnimplementedError();
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    // mock data — remove when API is ready
    return [
      ComplaintModel(
        id: 1,
        description: 'السائق لم يصل في الوقت المحدد وتأخر أكثر من 30 دقيقة دون إبلاغي مسبقاً.',
        status: 'unread',
        createdAt: '2026-05-15',
        type: ComplaintType.driverBehavior,
      ),
      ComplaintModel(
        id: 2,
        description: 'تم خصم مبلغ من رصيدي مرتين لنفس الرحلة ولم يُسترجع حتى الآن.',
        status: 'pending',
        createdAt: '2026-05-10',
        type: ComplaintType.financial,
      ),
      ComplaintModel(
        id: 3,
        description: 'السائق كان يقود بسرعة عالية جداً وتجاهل إشارات الوقوف.',
        status: 'resolved',
        createdAt: '2026-05-05',
        type: ComplaintType.safety,
      ),
      ComplaintModel(
        id: 4,
        description: 'التطبيق لم يُوفّق في تحميل الخريطة وتعذّر علي إتمام الحجز.',
        status: 'rejected',
        createdAt: '2026-04-28',
        type: ComplaintType.technical,
      ),
      ComplaintModel(
        id: 5,
        description: 'تم تجميد حسابي دون سبب واضح ولا أستطيع الدخول منذ يومين.',
        status: 'unread',
        createdAt: '2026-05-14',
        type: ComplaintType.account,
      ),
    ];
  }

  @override
  Future<ContactRequestModel> requestContactSupport() async {
    // TODO: implement when API is ready
    throw UnimplementedError();
  }
}
