import 'package:get/get.dart';

import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';

/// أين يذهب المستخدم بعد أن تُنشأ رحلته.
///
/// **الرئيسية تبقى تحت شاشة العودة.**
///
/// كان الانتقال `Get.offAllNamed(tripDidYouBack)` — يمسح المكدّس كلّه ثم
/// يضع شاشة «هل ترغب بإنشاء رحلة للعودة؟» وحدها فيه. فمن ضغط «رجوع»
/// عليها، أو على أي شاشة من معالج رحلة العودة فوقها، لم يجد تحتها شيئاً
/// **فخرج من التطبيق**.
///
/// المكدّس الآن [الرئيسية، شاشة العودة]: الرجوع يعود إلى الرئيسية كما
/// يتوقّع المستخدم، ومعالج العودة يُدفع فوقهما فيرجع إليهما بالترتيب.
///
/// ومسح المكدّس نفسه مقصود: معالج الإنشاء وراءنا وقد تمّ عمله، ولا يصحّ
/// أن يعود إليه الرجوع فيُنشئ الرحلة مرّتين.
void goToReturnTripPrompt(TripFrom trip) {
  Get.offAllNamed(RouteName.home);
  Get.toNamed(RouteName.tripDidYouBack, arguments: trip);
}
