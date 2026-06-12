import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/api/api_envelope.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/support/data/model/complaint_model.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';
import 'package:alatarekak/features/support/domain/entity/contact_request_entity.dart';

abstract class SupportRemoteDataSource {
  Future<ComplaintModel> submitComplaint({
    required String title,
    required String description,
    required ComplaintType type,
    List<XFile> attachments,
  });

  Future<List<ComplaintModel>> getComplaints();

  Future<ComplaintModel> getComplaint(int id);

  Future<SupportChatEntity> openSupportChat();
}

class SupportRemoteDataSourceIm extends SupportRemoteDataSource {
  final DioConSumer api;

  SupportRemoteDataSourceIm({required this.api});

  Never _throwFrom(dynamic json) {
    throw ServerExpcptions(
      error: json is Map<String, dynamic>
          ? Filuar.fromJson(json)
          : const Filuar(message: 'حدث خطأ غير متوقع'),
    );
  }

  @override
  Future<ComplaintModel> submitComplaint({
    required String title,
    required String description,
    required ComplaintType type,
    List<XFile> attachments = const [],
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'type': type.apiValue,
    };
    // مفاتيح الملفات attachments[0..2] — الباك إند يتحقق منها كـ attachments.N
    for (var i = 0; i < attachments.length; i++) {
      data['attachments[$i]'] = await MultipartFile.fromFile(
        attachments[i].path,
        filename: attachments[i].name,
      );
    }

    final json = await api.post(
      ApiEndPoint.complaints,
      data: data,
      isFomrData: attachments.isNotEmpty,
    );
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);

    // استجابة 201 تضع الكائن تحت complaint (مفرد) وليس data
    return ComplaintModel.fromJson(
        (json as Map<String, dynamic>)['complaint'] as Map<String, dynamic>);
  }

  @override
  Future<List<ComplaintModel>> getComplaints() async {
    final json = await api.get(ApiEndPoint.complaints);
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);

    final rawItems = (json as Map<String, dynamic>)['data'] as List? ?? [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(ComplaintModel.fromJson)
        .toList();
  }

  @override
  Future<ComplaintModel> getComplaint(int id) async {
    final json = await api.get("${ApiEndPoint.complaints}/$id");
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);

    return ComplaintModel.fromJson(
        (json as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  @override
  Future<SupportChatEntity> openSupportChat() async {
    // 200 (محادثة موجودة) و201 (جديدة) يعاملان بنفس الطريقة
    final json = await api.post(ApiEndPoint.contact);
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);

    final map = json as Map<String, dynamic>;
    final agent = map['agent'];
    return SupportChatEntity(
      conversationId: (map['conversation_id'] as num).toInt(),
      agentName:
          agent is Map<String, dynamic> ? agent['name']?.toString() : null,
    );
  }
}
