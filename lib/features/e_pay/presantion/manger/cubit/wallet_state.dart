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

  /// كشف الحساب — يحمل الرصيد الأدقّ والرسوم المستحقّة وأحدث الحركات.
  /// يبقى null إن تعذّر جلبه، فالرصيد وحده يكفي لعرض الشاشة.
  final WalletStatement? statement;

  /// صفحات إضافية قيد الجلب في التمرير اللانهائي.
  final bool loadingMore;

  const WalletLoaded({
    required this.balance,
    this.statement,
    this.loadingMore = false,
  });

  double get debt => statement?.cashRideDebt ?? 0;
  bool get hasDebt => debt > 0;

  WalletLoaded copyWith({WalletStatement? statement, bool? loadingMore}) =>
      WalletLoaded(
        balance: balance,
        statement: statement ?? this.statement,
        loadingMore: loadingMore ?? this.loadingMore,
      );

  @override
  List<Object> get props => [
        balance.walletNumber,
        balance.balance,
        statement?.items.length ?? -1,
        statement?.cashRideDebt ?? -1,
        statement?.currentPage ?? -1,
        loadingMore,
      ];
}
