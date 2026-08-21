import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/service/wallet_provision_service.dart';
import 'package:alatarekak/features/e_pay/data/model/balance_model.dart';
import 'package:alatarekak/features/e_pay/data/repo/e_pay_repo_im.dart';
import 'package:alatarekak/features/e_pay/domain/entity/wallet_transaction.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'wallet_state.dart';

class WalletCubit extends SafeCubit<WalletState> {
  final EPayRepoIm _repo;
  WalletCubit(this._repo) : super(WalletInitial());

  Future<void> getBalance({bool allowProvisionRetry = true}) async {
    if (isClosed) return;
    emit(WalletLoading());
    final response = await _repo.getBalance();
    // شاشة المحفظة تُغلَق بمغادرتها (الانتقال إلى «مركباتي» مثلاً) بينما
    // الطلب ما زال في الطريق، فيعود الرد إلى كيوبت مُغلَق. بلا هذا الفحص
    // يُرفع StateError من داخل مسار غير متزامن لا يلتقطه أحد.
    if (isClosed) return;
    await response.fold((erorr) async {
      if (!_isWalletMissing(erorr.message)) {
        emit(WalletErorr(
            message: erorr.arabic(HandelErorrMessage.checkbalance)));
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
      // كشف الحساب يُجلب بعد عرض الرصيد لا قبله: هو مصدر الرسوم
      // المستحقّة وأحدث الحركات، لكن تعذّره يجب ألّا يمنع عرض المحفظة.
      await loadStatement();
    });
  }

  /// أول صفحة من كشف الحساب — تحمل معها الرصيد الأدقّ والدين.
  Future<void> loadStatement() async {
    final current = state;
    if (current is! WalletLoaded) return;

    final result = await _repo.getTransactions(page: 1);
    if (isClosed) return;
    result.fold((_) {}, (statement) {
      final s = state;
      if (s is WalletLoaded) emit(s.copyWith(statement: statement));
    });
  }

  /// الصفحة التالية عند بلوغ نهاية القائمة.
  Future<void> loadMoreTransactions() async {
    final current = state;
    if (current is! WalletLoaded) return;
    final st = current.statement;
    if (st == null || !st.hasMore || current.loadingMore) return;

    emit(current.copyWith(loadingMore: true));
    final result = await _repo.getTransactions(page: st.currentPage + 1);
    if (isClosed) return;

    result.fold((_) {
      final s = state;
      if (s is WalletLoaded) emit(s.copyWith(loadingMore: false));
    }, (next) {
      final s = state;
      if (s is! WalletLoaded) return;
      emit(s.copyWith(
        loadingMore: false,
        statement: WalletStatement(
          items: [...?s.statement?.items, ...next.items],
          balance: next.balance,
          cashRideDebt: next.cashRideDebt,
          currentPage: next.currentPage,
          lastPage: next.lastPage,
          total: next.total,
        ),
      ));
    });
  }

  /// إنشاء المحفظة يدوياً برقم الهاتف — لمن لم تُنشأ محفظته تلقائياً عند
  /// التسجيل (فشل عابر وقتها، أو حساب أُنشئ قبل هذه الميزة). خطوة واحدة
  /// بلا رمز تحقق.
  Future<void> activateWallet(String phoneNumber) async {
    if (isClosed) return;
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
      if (isClosed) return;
      emit(WalletActivationFailed(
          message: erorr.arabic(HandelErorrMessage.createWalletDirect)));
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
