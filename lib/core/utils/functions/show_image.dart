import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/widgets/app_error_view.dart';

/// عارض صورة بملء الشاشة — صور الملف الشخصي والمركبات.
///
/// **`contain` لا `cover`:** كان العارض يقصّ الصورة لتملأ المربّع، فمن
/// يفتح صورته ليراها يرى وسطها فقط — وصورة الرخصة أو المركبة قد يضيع
/// طرفها كلّه. الغاية هنا الرؤية لا التزيين.
///
/// ويُتاح التكبير باللمس (`InteractiveViewer`) — رقم لوحة أو سطر في
/// وثيقة لا يُقرأ بحجم الشاشة وحده.
void openImage(String imageUrl) {
  Get.dialog(
    _ImageViewerDialog(imageUrl: imageUrl),
    barrierColor: Colors.black87,
  );
}

class _ImageViewerDialog extends StatelessWidget {
  final String imageUrl;

  const _ImageViewerDialog({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 24.h),
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: _image(context),
            ),
          ),
          // زرّ الإغلاق: كان الخروج بالضغط خارج الصورة وحده، وهو غير
          // ظاهر لمن لا يعرفه — ويستحيل حين تملأ الصورة الشاشة.
          PositionedDirectional(
            top: 4,
            start: 4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Get.back(),
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white, size: 22.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _image(BuildContext context) {
    final media = MediaQuery.of(context);

    // حدّ فكّ الترميز بعرض الشاشة: صورة الهاتف بأربعة آلاف بكسل تُفكّ
    // إلى نحو 48 ميغابايت في الذاكرة لتُعرض على شاشة عرضها ألف. الحدّ
    // لا يُنقص ما يراه المستخدم شيئاً ويقي أجهزة الذاكرة المحدودة.
    final decodeWidth =
        (media.size.width * media.devicePixelRatio).round().clamp(360, 2160);

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        cacheWidth: decodeWidth,
        errorBuilder: (context, error, stackTrace) => _errorCard(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _loading(progress);
        },
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.contain,
      cacheWidth: decodeWidth,
      errorBuilder: (context, error, stackTrace) => _errorCard(),
    );
  }

  Widget _loading(ImageChunkEvent progress) {
    final total = progress.expectedTotalBytes;
    return SizedBox(
      height: 200.h,
      child: Center(
        child: CircularProgressIndicator(
          color: MyColors.accent,
          strokeWidth: 3,
          value: total != null ? progress.cumulativeBytesLoaded / total : null,
        ),
      ),
    );
  }

  /// الخطأ يُعرض داخل بطاقة بلون سطح التطبيق — كان يُرسم على
  /// `Colors.grey[200]` بزرّ `Colors.red` خام، فبدا من تطبيق آخر.
  Widget _errorCard() {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: AppErrorView(
        icon: Icons.broken_image_outlined,
        title: 'تعذّر تحميل الصورة',
        message: 'قد يكون الاتصال منقطعاً أو الصورة لم تعد متاحة.',
        actionLabel: 'إغلاق',
        onAction: () => Get.back(),
      ),
    );
  }
}
