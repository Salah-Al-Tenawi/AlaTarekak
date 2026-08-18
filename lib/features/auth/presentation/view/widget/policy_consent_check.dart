import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';

/// عنوانا الوثيقتين كما يردان في نصّ الموافقة، ورقم تبويب كلٍّ منهما.
const List<(String, int)> kConsentLinks = [
  ('سياسة الخصوصية', 0),
  ('سياسة الإلغاء', 1),
];

/// يحوّل سطر الموافقة إلى نصّ فيه رابطان قابلان للضغط.
///
/// السطر صار يُكتب من لوحة الأدمن، وهو نصّ عادي بلا روابط. لكن الموافقة
/// بلا سبيل لقراءة ما يُوافَق عليه لا تصحّ — فنبحث في النصّ عن عنواني
/// الوثيقتين ونجعلهما رابطين حيثما وردا. وإن لم يردا (صاغ الأدمن السطر
/// بكلمات أخرى) أُلحق الرابطان في آخره بدل أن يضيعا.
List<InlineSpan> buildConsentSpans({
  required String label,
  required TextStyle linkStyle,
  required GestureRecognizer? Function(int tab) recognizerFor,
}) {
  final hits = <(int, String, int)>[]; // (الموضع، النصّ، التبويب)
  for (final (text, tab) in kConsentLinks) {
    final at = label.indexOf(text);
    if (at >= 0) hits.add((at, text, tab));
  }
  hits.sort((a, b) => a.$1.compareTo(b.$1));

  if (hits.isEmpty) {
    return [
      TextSpan(text: '$label '),
      for (var i = 0; i < kConsentLinks.length; i++) ...[
        if (i > 0) const TextSpan(text: ' و'),
        TextSpan(
          text: kConsentLinks[i].$1,
          style: linkStyle,
          recognizer: recognizerFor(kConsentLinks[i].$2),
        ),
      ],
    ];
  }

  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final (at, text, tab) in hits) {
    if (at > cursor) spans.add(TextSpan(text: label.substring(cursor, at)));
    spans.add(TextSpan(
      text: text,
      style: linkStyle,
      recognizer: recognizerFor(tab),
    ));
    cursor = at + text.length;
  }
  if (cursor < label.length) spans.add(TextSpan(text: label.substring(cursor)));
  return spans;
}

/// موافقة صريحة على السياسات قبل إنشاء الحساب.
///
/// غير مؤشَّر افتراضياً ويُعطّل زرّ الإنشاء حتى يؤشّره المستخدم: الموافقة
/// الضمنية لا تكفي هنا لأن التسجيل يفتح محفظة مالية على رقم هاتفه.
///
/// [consentLabel] نصّ السطر كما يكتبه الأدمن (`GET /policies`). تركه
/// فارغاً يعرض النسخة المدمجة: المكوّن **لا يقرأ الكيوبت بنفسه** حتى لا
/// يشترط مزوّداً فوقه — سطر الموافقة أهون من أن تتعطّل لأجله شاشة إنشاء
/// الحساب كلها إن نُسي المزوّد في مسار ما.
class PolicyConsentCheck extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  final String? consentLabel;

  /// يظهر تنبيه أحمر بعد محاولة إنشاء حساب بلا موافقة.
  final bool showError;

  const PolicyConsentCheck({
    super.key,
    required this.value,
    required this.onChanged,
    this.consentLabel,
    this.showError = false,
  });

  @override
  State<PolicyConsentCheck> createState() => _PolicyConsentCheckState();
}

class _PolicyConsentCheckState extends State<PolicyConsentCheck> {
  /// مُتعرِّف لكل تبويب، يُنشأ مرة ويُتلَف مع الشاشة. إنشاؤه داخل build
  /// يسرّب مُتعرِّفاً عند كل إعادة بناء — والشاشة تُعاد بناؤها مع كل حرف
  /// يكتبه المستخدم في النموذج.
  late final Map<int, TapGestureRecognizer> _recognizers = {
    for (final (_, tab) in kConsentLinks)
      tab: TapGestureRecognizer()
        ..onTap = () => Get.toNamed(RouteName.policy, arguments: tab),
  };

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: MyColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: Checkbox(
                value: widget.value,
                onChanged: (v) => widget.onChanged(v ?? false),
                activeColor: MyColors.primary,
                side: BorderSide(
                  color: widget.showError ? MyColors.error : MyColors.textHint,
                  width: 1.6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.r),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.bodySmall.copyWith(
                        color: MyColors.textSecondary, height: 1.6),
                    children: buildConsentSpans(
                      label: widget.consentLabel?.trim().isNotEmpty == true
                          ? widget.consentLabel!
                          : PolicyContent.builtIn.settings.consentLabel,
                      linkStyle: linkStyle,
                      recognizerFor: (tab) => _recognizers[tab],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.showError)
          Padding(
            padding: EdgeInsets.only(top: 6.h, right: 34.w),
            child: Text(
              'يجب الموافقة على السياسات لإنشاء الحساب',
              style: AppTextStyles.labelSmall.copyWith(color: MyColors.error),
            ),
          ),
      ],
    );
  }
}
