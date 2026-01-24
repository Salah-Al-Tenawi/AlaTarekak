class BalanceModel {
  final String walletNumber;
  final String balance;

  BalanceModel({required this.walletNumber, required this.balance});

  factory BalanceModel.fromJson(Map<String, dynamic> json) {
    return BalanceModel(
        walletNumber: json['wallet_number'], balance: json['balance']);
  }
}
