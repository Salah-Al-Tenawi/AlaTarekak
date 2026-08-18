import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';

abstract class PolicyRepo {
  /// آخر نسخة مخزَّنة — تُعرض فوراً ريثما يردّ الخادم.
  PolicyContent? getCached();

  Future<Either<Filuar, PolicyContent>> getPolicies();
}
