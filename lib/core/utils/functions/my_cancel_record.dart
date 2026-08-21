import 'package:alatarekak/core/utils/class/cancel_policy.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/features/profiles/data/date_source/profile_local_data_source.dart';

/// هل صاحب الجهاز مُلغٍ متكرّر؟ — يُقرأ من ملفه المخزَّن محلياً.
///
/// عدد الإلغاءات ونسبتها يصلان في كتلة `score` من `GET /profile/{id}`،
/// وهي محفوظة في الكاش بعد كل جلب. فالقراءة منه **متزامنة** — وحوارُ
/// الإلغاء لا يحتمل نداءَ شبكةٍ قبل أن يُعرض.
///
/// **وحين لا نعرف، لا ندّعي.** كاشٌ فارغ أو صندوقٌ غير مفتوح يُعيد
/// `false`، فتُعرض العقوبة المتدرّجة المعتادة. أي أن الخطأ الممكن هو أن
/// نُظهر عقوبةً أخفّ مما سيقع — لا أن نتّهم مستخدماً بتكرارٍ لم يقع.
///
/// وقد يتأخّر الرقم إلغاءً واحداً عن الخادم، وهو تقدير لا حكم: الخادم
/// وحده يطبّق العقوبة.
bool amIRepeatCanceller({required bool asDriver}) {
  try {
    final id = myid();
    if (id == null) return false;

    final profile = ProfileLocalDataSourceIm().getProfile(id);
    if (profile == null) return false;

    return CancelPolicy.isRepeatCanceller(
      cancellations: profile.data.totalCancellations,
      cancelRate: profile.data.cancelRate,
      asDriver: asDriver,
    );
  } catch (_) {
    // صندوق غير مفتوح أو كاش تالف — لا ندّعي ما لا نعرف
    return false;
  }
}
