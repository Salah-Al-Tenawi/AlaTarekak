/// كلفة الإجراء — محسوبةً قبل وقوعه لا بعده.
///
/// **القاعدة كلها مبنيّة على `elapsed%`، وهي ليست ما بقي على الانطلاق**
/// بل ما انقضى من عمر الحجز نفسه:
///
/// ```
/// elapsed% = (الآن − وقت الإنشاء) ÷ (الانطلاق − وقت الإنشاء) × 100
/// ```
///
/// فحجزٌ أُنشئ قبل الانطلاق بساعة يبلغ 70% خلال اثنتين وأربعين دقيقة،
/// وحجزٌ أُنشئ قبل أسبوع يحتاج خمسة أيام ليبلغها. ولا مسار عند الخادم
/// يُرجع النسبة قبل التنفيذ — تُحسب هنا من `booked_at` و`departure_time`.
///
/// **والعتبات ليست واحدة**: الاسترداد أربع شرائح (30/50/70)، والنقاط
/// ثلاث (30/50). فبين الخمسين والسبعين يخسر الراكب نصف مبلغه وعشر نقاط
/// معاً — وهي الشريحة التي يظنّها الناس متدرّجة فيفاجئهم اجتماع
/// الخسارتين.
///
/// **دوالّ نقيّة** — لا واجهة فيها ولا شبكة، فتُختبر وحدها.
library;

import 'package:alatarekak/core/utils/class/arabic_plural.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';

/// نوع ما يقع: مال، أو نقاط ثقة، أو أثرٌ على أشخاص، أو خبر عام.
enum ConsequenceKind { money, points, people, info }

/// نبرة السطر: خبرٌ محايد، أو مكسب، أو تحذير، أو خسارة صريحة.
enum ConsequenceTone { neutral, good, warning, bad }

/// ما يقع للمستخدم إن أتمّ الإجراء — سطرٌ واحد بنبرته.
class Consequence {
  final ConsequenceKind kind;
  final ConsequenceTone tone;
  final String text;

  const Consequence(this.kind, this.tone, this.text);

  @override
  String toString() => text;
}

class CancelPolicy {
  CancelPolicy._();

  /// نسبة ما انقضى من عمر الحجز — `null` إن تعذّر حسابها.
  ///
  /// تتعذّر حين يغيب وقت الإنشاء، أو حين يسبق الانطلاقُ الإنشاءَ (بيانات
  /// مكسورة). و`null` تعني «لا نعرف» فتُعرض جملة عامّة بدل رقم مخترع —
  /// ووعدُ استردادٍ كامل مبنيٍّ على صفرٍ مفترض أسوأ من ألّا نَعِد بشيء.
  static double? elapsedPercent({
    required DateTime? createdAt,
    required DateTime departure,
    DateTime? now,
  }) {
    if (createdAt == null) return null;

    final window = departure.difference(createdAt);
    if (window.inSeconds <= 0) return null;

    final passed = (now ?? DateTime.now()).difference(createdAt);
    if (passed.isNegative) return 0;

    final percent = passed.inSeconds / window.inSeconds * 100;
    return percent > 100 ? 100 : percent;
  }

  /// نسبة ما يُعاد من قيمة المقاعد الملغاة: 100 / 70 / 50 / 0.
  static int refundPercent(double elapsed) {
    if (elapsed <= 30) return 100;
    if (elapsed <= 50) return 70;
    if (elapsed <= 70) return 50;
    return 0;
  }

  /// نقاط الثقة التي يخسرها الراكب بإلغائه — عدداً موجباً.
  ///
  /// **الدفع الإلكتروني لا يخصم نقاطاً إطلاقاً**: خسارة المبلغ هي
  /// العقوبة، فلا تُضاعَف بخصمٍ ثانٍ.
  static int passengerCancelPoints({
    required double elapsed,
    required bool cashRide,
  }) {
    if (!cashRide) return 0;
    if (elapsed <= 30) return 0;
    if (elapsed <= 50) return 5;
    return 10;
  }

  /// نقاط السائق بإلغائه رحلته — **في الطريقتين معاً**، خلافاً للراكب.
  static int driverCancelRidePoints(double elapsed) {
    if (elapsed <= 30) return 0;
    if (elapsed <= 50) return 7;
    return 12;
  }

  // **لا رسوم على السائق أصلاً.** كانت هنا `creationFeeRefunded` مأخوذة
  // عن جدول الباك إند («رسوم إنشاء الرحلة: تُسترد كاملة / تُحتجز»)، ثمّ
  // تبيّن أن لا وجود لها في المنتج: المال يدفعه الراكب، والتطبيق يأخذ
  // نسبته من الحجز لا من السائق. فعقوبة السائق نقاطُ ثقةٍ لا غير، ووعدُ
  // «تُعاد إليك رسومك» كان يَعِد بمالٍ لم يدفعه.

  // ── ما يُقال للمستخدم ────────────────────────────────────────────

  /// إلغاء الراكب حجزَه — أو بعض مقاعده.
  ///
  /// [amount] قيمة المقاعد الملغاة وحدها لا الحجز كلّه.
  static List<Consequence> passengerCancel({
    required double? elapsed,
    required int amount,
    required bool cashRide,
  }) {
    if (elapsed == null) {
      return const [
        Consequence(ConsequenceKind.info, ConsequenceTone.neutral,
            'يعتمد المبلغ المسترد على قربك من موعد الانطلاق.'),
      ];
    }

    final refund = refundPercent(elapsed);
    final points = passengerCancelPoints(elapsed: elapsed, cashRide: cashRide);
    final back = amount * refund ~/ 100;

    return [
      if (cashRide)
        const Consequence(ConsequenceKind.money, ConsequenceTone.neutral,
            'الدفع في هذه الرحلة نقديّ للسائق، فلا مبالغ مستردّة.')
      else if (refund == 100)
        Consequence(ConsequenceKind.money, ConsequenceTone.good,
            'يُعاد إليك كامل المبلغ (${Money.withCurrency(amount)}).')
      else if (refund == 0)
        Consequence(ConsequenceKind.money, ConsequenceTone.bad,
            'لا يُعاد شيء من المبلغ (${Money.withCurrency(amount)}).')
      else
        Consequence(
            ConsequenceKind.money,
            ConsequenceTone.warning,
            'يُعاد إليك $refund% من المبلغ (${Money.withCurrency(back)} '
                'من ${Money.withCurrency(amount)}).'),
      if (points == 0)
        const Consequence(ConsequenceKind.points, ConsequenceTone.good,
            'ولن تخسر أي نقاط من رصيد ثقتك.')
      else
        Consequence(ConsequenceKind.points, ConsequenceTone.bad,
            'وتُخصم ${_points(points)} من رصيد ثقتك.'),
    ];
  }

  /// إلغاء السائق رحلته.
  ///
  /// [passengers] عدد الركّاب أصحاب الحجوزات القائمة — يُستردّ لهم كامل
  /// مبالغهم مهما تأخّر الإلغاء، فالخصم على من ألغى لا على من انتظر.
  ///
  /// **وكلفة السائق نقاطٌ لا مال**: لا يدفع رسوماً على رحلته، والتطبيق
  /// يأخذ نسبته من حجز الراكب.
  static List<Consequence> driverCancelRide({
    required double? elapsed,
    required int passengers,
  }) {
    final lines = <Consequence>[
      if (passengers > 0)
        Consequence(ConsequenceKind.people, ConsequenceTone.warning,
            'يصل الإشعار إلى ${_riders(passengers)}، ويُستردّ لهم كامل '
                'المبلغ.')
      else
        const Consequence(ConsequenceKind.people, ConsequenceTone.good,
            'لا حجوزات على هذه الرحلة.'),
    ];

    if (elapsed == null) {
      lines.add(const Consequence(ConsequenceKind.info, ConsequenceTone.neutral,
          'وقد تُخصم نقاط من رصيد ثقتك حسب قربك من موعد الانطلاق.'));
      return lines;
    }

    final points = driverCancelRidePoints(elapsed);
    lines.add(points == 0
        ? const Consequence(ConsequenceKind.points, ConsequenceTone.good,
            'ولن تخسر أي نقاط من رصيد ثقتك.')
        : Consequence(ConsequenceKind.points, ConsequenceTone.bad,
            'وتُخصم ${_points(points)} من رصيد ثقتك.'));

    return lines;
  }

  /// بلاغ الغياب — **لا شيء يقع فوراً**، وهذا جوهر ما يجب أن يُقال.
  ///
  /// الضغط يفتح مهلة اعتراض لا أكثر، والنتيجة تُحسم بعدها. و[cashRide]
  /// يحدّد ما يُوعَد به السائق: تحويل 95% لا يقع إلا في الدفع الإلكتروني،
  /// إذ لا مبلغ محتجزاً في النقدي أصلاً.
  ///
  /// ولا تُذكر مدّة المهلة: ثابتها عند الخادم في وضع تجريب، ورسائله
  /// تقول غيره — فتُقال «مهلة» حتى يصل `expires_at`.
  static List<Consequence> noShowReport({
    required bool againstPassenger,
    required bool cashRide,
  }) {
    final other = againstPassenger ? 'الراكب' : 'السائق';

    return [
      Consequence(ConsequenceKind.info, ConsequenceTone.neutral,
          'لا يقع شيء الآن: يُمنح $other مهلة للاعتراض.'),
      if (againstPassenger)
        cashRide
            ? const Consequence(ConsequenceKind.points, ConsequenceTone.neutral,
                'إن لم يعترض: يُسجَّل غيابه وتُخصم منه 15 نقطة.')
            : const Consequence(ConsequenceKind.money, ConsequenceTone.good,
                'إن لم يعترض: يُسجَّل غيابه، ويُحوَّل إليك 95% من قيمة '
                    'المقعد.')
      else
        const Consequence(ConsequenceKind.money, ConsequenceTone.good,
            'إن لم يعترض: يُستردّ لك كامل مبلغك، وتُخصم منه 15 نقطة.'),
      const Consequence(ConsequenceKind.info, ConsequenceTone.warning,
          'وإن اعترض: تُفتح شكوى ويتدخّل فريق الدعم، بلا عقوبة تلقائية '
              'على أحد.'),
    ];
  }

  static String _points(int value) =>
      arabicCount(value, singular: 'نقطة', dual: 'نقطتين', plural: 'نقاط');

  static String _riders(int value) =>
      arabicCount(value, singular: 'راكب', dual: 'راكبين', plural: 'ركّاب');
}
