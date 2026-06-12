import 'dart:convert';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/support/data/model/complaint_model.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';

abstract class SupportLocalDataSource {
  List<ComplaintModel>? getComplaints();
  Future<void> saveComplaints(List<ComplaintEntity> complaints);

  /// إدراج شكوى جديدة في مقدمة الكاش (بعد نجاح الإرسال)
  Future<void> prependComplaint(ComplaintEntity complaint);
  Future<void> clear();
}

class SupportLocalDataSourceIm extends SupportLocalDataSource {
  @override
  List<ComplaintModel>? getComplaints() {
    final raw = HiveBoxes.cacheBox.get(HiveKeys.complaints);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(ComplaintModel.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveComplaints(List<ComplaintEntity> complaints) {
    final json = complaints
        .map((c) => ComplaintModel.fromEntity(c).toJson())
        .toList();
    return HiveBoxes.cacheBox.put(HiveKeys.complaints, jsonEncode(json));
  }

  @override
  Future<void> prependComplaint(ComplaintEntity complaint) {
    final current = getComplaints() ?? <ComplaintModel>[];
    return saveComplaints([complaint, ...current]);
  }

  @override
  Future<void> clear() => HiveBoxes.cacheBox.delete(HiveKeys.complaints);
}
