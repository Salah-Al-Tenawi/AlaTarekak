import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:flutter_test/flutter_test.dart';

/// رسالة الاستثناء في السجلّ.
///
/// كان `debugPrint('[Push] فشل تسجيل التوكن: $e')` يطبع
/// `Instance of 'ServerExpcptions'` — سطر لا يقول شيئاً عن سبب الفشل،
/// فصار تشخيص عطل 404 على `/push/register` تخميناً بدل قراءة.

void main() {
  test('الرسالة تظهر في السجلّ بدل اسم الصنف', () {
    final e = ServerExpcptions(
      error: const Filuar(
          message: 'The route api/push/register could not be found.'),
    );

    expect('$e', contains('api/push/register'));
    expect('$e', isNot("Instance of 'ServerExpcptions'"));
  });

  test('الكود البرمجي يُذكر معها حين يرسله الخادم', () {
    final e = ServerExpcptions(
      error: const Filuar(
          message: 'Your email address is not verified.',
          code: 'EMAIL_NOT_VERIFIED'),
    );

    expect('$e', contains('EMAIL_NOT_VERIFIED'));
    expect('$e', contains('not verified'));
  });

  test('بلا كود لا يُطبع قوسان فارغان', () {
    final e = ServerExpcptions(error: const Filuar(message: 'خطأ'));
    expect('$e', 'ServerExpcptions: خطأ');
  });
}
