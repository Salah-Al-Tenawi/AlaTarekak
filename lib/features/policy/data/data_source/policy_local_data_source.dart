import 'dart:convert';

import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/policy/data/model/policy_content_model.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';

abstract class PolicyLocalDataSource {
  PolicyContent? get();
  Future<void> save(PolicyContent content);
}

class PolicyLocalDataSourceIm extends PolicyLocalDataSource {
  @override
  PolicyContent? get() {
    try {
      final raw = HiveBoxes.cacheBox.get(HiveKeys.policies);
      if (raw == null) return null;
      return PolicyContentModel.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // نسخة مخزَّنة بشكل قديم أو تالفة — تُتجاهل وتُستبدل بأول تحديث
      return null;
    }
  }

  @override
  Future<void> save(PolicyContent content) => HiveBoxes.cacheBox
      .put(HiveKeys.policies, jsonEncode(PolicyContentModel.toJson(content)));
}
