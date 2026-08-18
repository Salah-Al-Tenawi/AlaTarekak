import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:flutter_test/flutter_test.dart';

/// مسارات توكن FCM.
///
/// كان التطبيق يستدعي `/push/register` و`/push/remove` — **ولا وجود
/// لهما**: أعاد الإنتاج 404 على كل محاولة تسجيل، فلم يُحفظ توكن واحد
/// لأي حساب. سجّلهما الباك إند في 2026-08-18 تحت `push-tokens` كمورد
/// واحد يتبدّل فعله بالطريقة.

void main() {
  test('المسار هو push-tokens لا push/register', () {
    expect(ApiEndPoint.pushTokens, endsWith('/push-tokens'));
    expect(ApiEndPoint.pushTokens, isNot(contains('/push/')));
  });

  test('التسجيل والإزالة على المسار نفسه', () {
    // الفرق بينهما الطريقة (POST مقابل DELETE) لا العنوان — ولو أرسلنا
    // الإزالة POST لسجّلنا التوكن من جديد بدل حذفه.
    expect(ApiEndPoint.pushTokens, isNot(contains('register')));
    expect(ApiEndPoint.pushTokens, isNot(contains('remove')));
  });

  test('مسار الإشعار التجريبي فرع من المورد نفسه', () {
    expect(ApiEndPoint.pushTokensTest, '${ApiEndPoint.pushTokens}/test');
  });

  test('المسار مطلق على خادم الإنتاج', () {
    expect(ApiEndPoint.pushTokens, startsWith('https://'));
    expect(ApiEndPoint.pushTokens, contains('/api/'));
  });
}
