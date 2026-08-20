import 'package:flutter/material.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/core/service/location_service.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';

/// «موقعي» — يضع نقطة الانطلاق أو الوجهة على موقع المستخدم الحالي.
///
/// كان على الراكب أن يجد بيته على الخريطة بإصبعه في كل بحث، وعلى السائق
/// كذلك في كل رحلة ينشئها. وهو أكثر ما يُكرَّر في التطبيق.
///
/// **الإذن يُطلب هنا لا عند الإقلاع**: الضغط على الزرّ يشرح الطلب من
/// نفسه، فيُقبل. والسؤال بلا سياق يُرفض، والرفض الدائم لا يُسأل بعده.
class MyLocationButton extends StatefulWidget {
  final ValueChanged<LatLng> onLocated;

  /// نصّ الزرّ — يختلف بين «انطلاقي» و«وجهتي» بحسب ما يُحدَّد.
  final String label;

  const MyLocationButton({
    super.key,
    required this.onLocated,
    this.label = 'موقعي الحالي',
  });

  @override
  State<MyLocationButton> createState() => _MyLocationButtonState();
}

class _MyLocationButtonState extends State<MyLocationButton> {
  bool _busy = false;

  Future<void> _locate() async {
    if (_busy) return;
    setState(() => _busy = true);

    final result = await LocationService.instance.currentPoint();
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case LocationSuccess(:final point):
        widget.onLocated(point);

      case LocationDenied denied:
        // لكل تعذّر تصرّفه: المرفوض دائماً يُفتح من الإعدادات، وغيره
        // يُشرح ويُترك للمستخدم
        final open = await showAppDialog(
          context,
          icon: denied.reason == LocationFailure.outsideSyria
              ? Icons.public_off_rounded
              : Icons.location_off_rounded,
          accentColor: MyColors.warning,
          title: 'تعذّر تحديد موقعك',
          message: denied.message,
          confirmLabel: denied.canOpenSettings ? 'فتح الإعدادات' : null,
          cancelLabel: 'حسناً',
        );

        if (open == true) await LocationService.instance.openSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MyColors.surface,
      borderRadius: BorderRadius.circular(14.r),
      elevation: 3,
      shadowColor: MyColors.shadowMedium,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: _busy ? null : _locate,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18.sp,
                height: 18.sp,
                child: _busy
                    ? AppLoader(size: 18, color: MyColors.primary)
                    : Icon(Icons.my_location_rounded,
                        size: 18.sp, color: MyColors.primary),
              ),
              SizedBox(width: 8.w),
              Text(
                _busy ? 'جارٍ التحديد…' : widget.label,
                style: AppTextStyles.labelMedium
                    .copyWith(color: MyColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
