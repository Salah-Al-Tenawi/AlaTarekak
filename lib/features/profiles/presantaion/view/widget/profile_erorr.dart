import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';

class ProfileErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String errorMessage;

  const ProfileErrorWidget({
    super.key,
    required this.onRetry,
    this.errorMessage = 'حدث خطأ اثناء التحميل',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          MyButton(
            onPressed: onRetry,
            width: 150.w,
            height: 45.h,
            borderRadius: true,
            child: const Text("أعد المحاولة"),
          ),
        ],
      ),
    );
  }
}