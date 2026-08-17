import 'package:alatarekak/core/utils/functions/json_parse.dart';

class BalanceModel {
  final String walletNumber;
  final String balance;

  BalanceModel({required this.walletNumber, required this.balance});

  /// كان الإسناد مباشراً (`json['balance']`) وهو تحويل ضمني إلى `String`:
  /// المستند يعرض `"balance": 150000` **رقماً**، فيرمي
  /// `type 'int' is not a subtype of type 'String'` عند كل فتح للمحفظة.
  /// [asString] تقبل النوعين وتُبقي العرض نصاً في الحالتين.
  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    return BalanceModel(
      walletNumber: asString(json['wallet_number']) ?? '',
      balance: asString(json['balance']) ?? '0',
    );
  }
}
