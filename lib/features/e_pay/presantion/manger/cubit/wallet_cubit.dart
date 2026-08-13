import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/service/wallet_provision_service.dart';
import 'package:alatarekak/features/e_pay/data/model/balance_model.dart';
import 'package:alatarekak/features/e_pay/data/repo/e_pay_repo_im.dart';

part 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  final EPayRepoIm _repo;
  WalletCubit(this._repo) : super(WalletInitial());

  Future<void> getBalance({bool allowProvisionRetry = true}) async {
    emit(WalletLoading());
    final response = await _repo.getBalance();
    await response.fold((erorr) async {
      if (!_isWalletMissing(erorr.message)) {
        emit(WalletErorr(
            message: HandelErorrMessage.checkbalance(erorr.message)));
        return;
      }

      // لا محفظة: قد يكون إنشاؤها التلقائي بعد التسجيل فشل لعطل عابر —
      // نعيد المحاولة مرة واحدة بالرقم المحفوظ قبل أن نطلب من المستخدم
      // إنشاءها يدوياً.
      if (allowProvisionRetry &&
          (WalletProvisionService.instance.pendingPhone ?? '').isNotEmpty) {
        await WalletProvisionService.instance.retryIfPending();
        if (isClosed) return;
        return getBalance(allowProvisionRetry: false);
      }

      // لم يفعّل المستخدم محفظته بعد — ليس خطأً فعلياً
      emit(WalletNotActivated());
    }, (balance) async {
      emit(WalletLoaded(balance: balance));
    });
  }

  /// إنشاء المحفظة يدوياً برقم الهاتف — لمن لم تُنشأ محفظته تلقائياً عند
  /// التسجيل (فشل عابر وقتها، أو حساب أُنشئ قبل هذه الميزة). خطوة واحدة
  /// بلا رمز تحقق.
  Future<void> activateWallet(String phoneNumber) async {
    emit(WalletActivating());
    final response = await _repo.createWalletDirect(phoneNumber);
    if (isClosed) return;

    await response.fold((erorr) async {
      // محفظة موجودة أصلاً: الهدف متحقق — نعرض الرصيد بدل رسالة خطأ
      if (HandelErorrMessage.isWalletAlreadyExists(erorr.message)) {
        await WalletProvisionService.instance.forgetPhone();
        if (isClosed) return;
        return getBalance(allowProvisionRetry: false);
      }
      emit(WalletActivationFailed(
          message: HandelErorrMessage.createWalletDirect(erorr.message)));
    }, (_) async {
      // لا داعي لإعادة محاولة تلقائية بعد اليوم
      await WalletProvisionService.instance.forgetPhone();
      if (isClosed) return;
      return getBalance(allowProvisionRetry: false);
    });
  }

  /// الرقم الذي أدخله المستخدم عند التسجيل وفشل إنشاء محفظته عليه —
  /// نُرشّح به حقل التفعيل بدل أن يكتبه من جديد.
  String? get suggestedPhone => WalletProvisionService.instance.pendingPhone;

  /// الخادم يصوغ غياب المحفظة بعبارتين مختلفتين حسب المسار
  /// ("No wallet found for this account." و "Wallet not found").
  bool _isWalletMissing(String message) {
    final m = message.toLowerCase();
    return m.contains('wallet not found') || m.contains('no wallet found');
  }
}
