part of 'wallet_cubit.dart';

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object> get props => [];
}

final class WalletInitial extends WalletState {}

final class WalletLoading extends WalletState {}

/// المستخدم لا يملك محفظة بعد — يُعرض حقل التفعيل بدل الرصيد.
final class WalletNotActivated extends WalletState {}

/// جارٍ إنشاء المحفظة برقم الهاتف.
final class WalletActivating extends WalletState {}

/// فشل الإنشاء اليدوي — يبقى حقل الرقم ظاهراً مع الرسالة.
final class WalletActivationFailed extends WalletState {
  final String message;

  const WalletActivationFailed({required this.message});

  @override
  List<Object> get props => [message];
}

final class WalletErorr extends WalletState {
  final String message;

  const WalletErorr({required this.message});

  @override
  List<Object> get props => [message];
}

final class WalletLoaded extends WalletState {
  final BalanceModel balance;

  const WalletLoaded({required this.balance});

  @override
  List<Object> get props => [balance.walletNumber, balance.balance];
}
