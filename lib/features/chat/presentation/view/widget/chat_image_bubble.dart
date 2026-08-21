import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/functions/show_image.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';

/// صورة داخل فقاعة محادثة.
///
/// **كانت بلا حدٍّ لارتفاعها**: `Image.network` بعرضٍ وحده يُبقي نسبة
/// الصورة كما هي، فصورةٌ طولية من كاميرا الهاتف تصير فقاعةً أطول من
/// الشاشة — يمرّرها المستخدم ليصل إلى الرسالة التي بعدها. الآن لها سقف،
/// وما زاد يُقصّ (`cover`).
///
/// **ولم تكن تُفتح**: لا شيء يستجيب للمسها، ومن أراد قراءة رقمٍ في صورة
/// لوحة أو عنوانٍ في لقطة شاشة لم يجد سبيلاً. الضغط يفتح [openImage] —
/// العارض نفسه بملء الشاشة وبالتكبير باللمس.
class ChatImageBubble extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  final bool isMe;

  /// ما يقع عند اللمس — [openImage] افتراضاً. منفذٌ للاختبار وحده.
  final void Function(String url)? onOpen;

  const ChatImageBubble({
    super.key,
    required this.imageUrl,
    required this.isMe,
    this.caption,
    this.onOpen,
  });

  /// أقصى ارتفاع للفقاعة — سقفٌ يمنع الصورة الطولية من ابتلاع الشاشة،
  /// ويترك للصورة العرضية مساحةً كافية لتُقرأ.
  static const double maxHeightFactor = 0.34;

  @override
  Widget build(BuildContext context) {
    final width = 0.6.sw;
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // الحدّ الأدنى معه: صورة بالغة الصغر أو بطيئة التحميل تُبقي
          // الفقاعة شريطاً رفيعاً لا يُلمس
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              minHeight: 120.h,
              maxWidth: width,
            ),
            child: GestureDetector(
              onTap: () => (onOpen ?? openImage)(imageUrl),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Image.network(
                    imageUrl,
                    width: width,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Container(
                                width: width,
                                color: MyColors.surfaceAlt,
                                child: const Center(
                                    child: AppLoader(size: 28)),
                              ),
                    errorBuilder: (context, error, stack) => Container(
                      width: width,
                      color: MyColors.surfaceAlt,
                      child: Icon(Icons.broken_image_outlined,
                          color: MyColors.textHint),
                    ),
                  ),
                  // دلالةٌ على أنها تُفتح — الصورة الساكنة لا تُنبئ بأنها
                  // تُلمس، وقد بقيت كذلك حتى الآن
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.zoom_out_map_rounded,
                          size: 14.sp, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (caption != null && caption!.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 8.h),
              child: Text(
                caption!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isMe ? Colors.white : MyColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
