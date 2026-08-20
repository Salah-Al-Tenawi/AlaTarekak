import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:alatarekak/core/utils/class/arabic_plural.dart';
import 'package:alatarekak/core/utils/class/ride_time_rules.dart';

/// نصّ عدّاد بوابة الإبلاغ: «بعد دقيقتين».
///
/// **تقريب لأعلى بالثواني لا بالدقائق.** كان الحساب `inMinutes + 1`،
/// و`inMinutes` يقتطع الكسر — فدقيقة كاملة (٦٠ ثانية) تُقرأ `1` ثم يُزاد
/// عليها فتصير «دقيقتين». يَعِد العدّاد بضعف ما بقي فعلاً، ويظهر العيب
/// جليّاً حين تُقصَّر المهلة للتجريب.
String noShowCountdownLabel(Duration remaining) {
  final minutes = (remaining.inSeconds / 60).ceil();
  return 'بعد ${arabicMinutes(minutes < 1 ? 1 : minutes)}';
}

/// يبني ما يتبع بوابة الإبلاغ، **ويُعيد بناءه مع مرور الوقت**.
///
/// كان الزرّ يُبنى مرّة واحدة: يُقرأ ما بقي عند فتح الشاشة ثم يُجمَّد.
/// فمن انتظر أمام الشاشة حتى تُفتح البوابة لا يراها تُفتح — يبقى الزرّ
/// معطّلاً بعدّاده القديم حتى يغادر الشاشة ويعود إليها. ومع مهلة الساعة
/// يمرّ العيب لأن أحداً لا ينتظر ساعة أمام شاشة، ويظهر فوراً متى قُصّرت.
///
/// المؤقّت يدقّ كل ثانية ولا يُعيد البناء إلا حين يتغيّر المعروض — أي
/// مرّة في الدقيقة، ومرّة أخيرة حين تُفتح البوابة. ثم يتوقّف.
class NoShowGate extends StatefulWidget {
  final DateTime departure;

  /// [remaining] ما بقي حتى تُفتح البوابة، و`null` تعني أنها مفتوحة.
  final Widget Function(BuildContext context, Duration? remaining) builder;

  /// مصدر الوقت — `DateTime.now` في التطبيق.
  ///
  /// منفذٌ للاختبار: ساعة الاختبار الوهمية تُقدّم المؤقّتات ولا تُقدّم
  /// `DateTime.now()`، فبدونه يدقّ المؤقّت ولا يتغيّر ما يقرؤه. وهو
  /// المَنفذ نفسه الذي تتيحه [RideTimeRules] بوسيطها `now`.
  final DateTime Function() clock;

  const NoShowGate({
    super.key,
    required this.departure,
    required this.builder,
    this.clock = DateTime.now,
  });

  @override
  State<NoShowGate> createState() => _NoShowGateState();
}

class _NoShowGateState extends State<NoShowGate> {
  Timer? _ticker;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _read();
    if (_remaining != null) _startTicking();
  }

  Duration? _read() =>
      RideTimeRules.untilNoShowGate(widget.departure, now: widget.clock());

  @override
  void didUpdateWidget(NoShowGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.departure != widget.departure) {
      _remaining = _read();
      _ticker?.cancel();
      if (_remaining != null) _startTicking();
    }
  }

  void _startTicking() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _read();

      // البناء يُعاد حين يتغيّر ما يُعرض وحده: الرقم بالدقائق، أو انفتاح
      // البوابة. دقّةٌ في الثانية لا تعني إعادة بناء في الثانية.
      final changed = next == null ||
          _remaining == null ||
          (next.inSeconds / 60).ceil() != (_remaining!.inSeconds / 60).ceil();

      _remaining = next;
      if (next == null) _ticker?.cancel();
      if (changed && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _remaining);
}
