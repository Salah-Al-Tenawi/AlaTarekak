import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/service/locator_ser.dart';
import 'package:alatarekak/features/e_pay/data/data_source/e_pay_remote_data_source.dart';
import 'package:alatarekak/features/e_pay/data/repo/e_pay_repo_im.dart';

/// إنشاء محفظة المستخدم تلقائياً على الرقم الذي أدخله عند التسجيل.
///
/// المستخدم لا يرى المحفظة كخطوة منفصلة إطلاقاً: يُدخل رقمه ضمن نموذج
/// إنشاء الحساب، وعند تأكيد بريده تُنشأ المحفظة في الخلفية فيجدها جاهزة
/// عند أول دخول.
///
/// الرقم يُحفظ عند إرسال نموذج التسجيل ويُقرأ بعد تأكيد البريد — لأن
/// `POST /wallet/create-direct` يتطلب JWT، وهو لا يصل إلا بعد التأكيد.
/// الحفظ في Hive (لا في ذاكرة الكيوبت) حتى ينجو من إغلاق التطبيق بين
/// الخطوتين.
class WalletProvisionService {
  WalletProvisionService._();
  static final WalletProvisionService instance = WalletProvisionService._();

  static const String _pendingPhoneKey = 'pending_wallet_phone';

  EPayRepoIm get _repo => EPayRepoIm(
        remoteDataSource:
            EPayRemoteDataSource(api: getit.get<DioConSumer>()),
      );

  /// الصندوق قد يكون غير مفتوح (إقلاع مبكر، أو اختبار لا يهيّئ Hive) —
  /// تعذّر الوصول إليه يجب ألّا يُسقط تدفّق التسجيل أو المحفظة.
  Box<String>? get _box {
    try {
      return Hive.isBoxOpen(HiveBoxes.cacheBoxName) ? HiveBoxes.cacheBox : null;
    } catch (_) {
      return null;
    }
  }

  /// يُستدعى لحظة إرسال نموذج التسجيل (قبل توفّر التوكن).
  Future<void> rememberPhone(String phoneNumber) async =>
      _box?.put(_pendingPhoneKey, phoneNumber);

  String? get pendingPhone => _box?.get(_pendingPhoneKey);

  Future<void> forgetPhone() async => _box?.delete(_pendingPhoneKey);

  /// يُستدعى بعد حفظ جلسة المستخدم مباشرة (تأكيد البريد).
  ///
  /// لا يرمي ولا يُفشل التسجيل مهما حدث: الحساب أُنشئ فعلاً، وفشل المحفظة
  /// يجب ألّا يمنع المستخدم من الدخول. يبقى الرقم محفوظاً عند الفشل
  /// لإعادة المحاولة لاحقاً، ويُمسح عند النجاح أو عند وجود محفظة أصلاً.
  Future<void> provisionAfterSignup() async {
    final phone = pendingPhone;
    if (phone == null || phone.isEmpty) return;

    final result = await _repo.createWalletDirect(phone);

    await result.fold(
      (failure) async {
        final message = failure.message.toLowerCase();
        // 409: للمستخدم محفظة بالفعل — الهدف متحقق، لا داعي لإعادة المحاولة
        if (message.contains('already have a wallet')) {
          await forgetPhone();
          return;
        }
        // 422: الرقم مرتبط بمحفظة أخرى — إعادة المحاولة بالرقم نفسه عبثية
        if (message.contains('already linked')) {
          await forgetPhone();
          debugPrint('[Wallet] الرقم مرتبط بمحفظة أخرى — لم تُنشأ المحفظة');
          return;
        }
        // عطل شبكة أو خادم: نُبقي الرقم لإعادة المحاولة عند فتح المحفظة
        debugPrint('[Wallet] تأجيل إنشاء المحفظة: ${failure.message}');
      },
      (_) async {
        await forgetPhone();
        debugPrint('[Wallet] أُنشئت المحفظة تلقائياً بعد إنشاء الحساب');
      },
    );
  }

  /// إعادة محاولة صامتة لمن فشل إنشاء محفظته لعطل عابر — تُستدعى عند فتح
  /// شاشة المحفظة قبل عرض تدفّق الإنشاء اليدوي.
  Future<void> retryIfPending() async {
    if ((pendingPhone ?? '').isEmpty) return;
    await provisionAfterSignup();
  }
}
