import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

class TripTextNote extends StatelessWidget {
  const TripTextNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 50.h),
      child: RichText(
        text: TextSpan(
          style: font11NormalGrey,
          children: [
            const TextSpan(
              text: "يُحدد هذا الخيار طريقة حجز المقاعد في رحلتك:\n\n",
            ),
            const TextSpan(
              text: "• ",
            ),
            const TextSpan(
              text: "أي شخص",
              style: TextStyle(
                color: MyColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(
              text: ": يُمكن للركاب الحجز فورًا دون انتظار الموافقة\n",
            ),
            const TextSpan(
              text: "• ",
            ),
            TextSpan(
              text: "بعد الموافقة",
              style: TextStyle(
                color: Colors.green.shade600, // لون مميز للخيار الثاني
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(
              text: ": يتطلب كل حجز موافقتك المسبقة قبل التأكيد",
            ),
          ],
        ),
      ),
    );
  }
}
