import 'package:flutter/material.dart';

import 'package:alatarekak/core/utils/widgets/app_loader.dart';

/// مؤشّر تحميل الشاشة الكاملة.
///
/// الشكل والحجم صارا في [AppLoader] — مصدر واحد لكل انتظار في التطبيق.
/// وهذا الاسم باقٍ لأنه مستعمل في عشرات المواضع، ولأن «مؤشّر الشاشة»
/// معنىً يستحقّ اسمه.
class LoadingWidgetSize150 extends StatelessWidget {
  const LoadingWidgetSize150({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: AppLoader(size: 150));
}
