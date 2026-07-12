import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// نظام الأنيميشن الموحد للتطبيق — NFR-19/20: دخول خفيف لمرة واحدة،
/// لا حركات لانهائية تستهلك البطارية.
///
/// نفس روح واجهة البحث (fade + slide-up) لكن بويدجتات جاهزة قابلة
/// لإعادة الاستخدام في أي شاشة.
class AppAnim {
  AppAnim._();

  static const Duration entrance = Duration(milliseconds: 320);
  static const Duration stagger = Duration(milliseconds: 60);
  static const Curve curve = Curves.easeOutCubic;

  /// أقصى عدد عناصر تتدرج في القائمة — ما بعده يظهر فوراً حتى لا
  /// ينتظر مستخدم القوائم الطويلة.
  static const int maxStaggered = 8;
}

/// دخول عنصر واحد: ظهور تدريجي مع انزلاق خفيف للأعلى.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;

  /// مقدار الانزلاق كنسبة من ارتفاع العنصر (موجب = يصعد من الأسفل).
  final double slideFrom;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slideFrom = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppAnim.entrance, curve: AppAnim.curve)
        .slideY(
          begin: slideFrom,
          end: 0,
          duration: AppAnim.entrance,
          curve: AppAnim.curve,
        );
  }
}

/// عنصر قائمة متدرج الدخول — يُغلف itemBuilder:
/// `StaggeredItem(index: i, child: BookingItem(...))`
class StaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggeredItem({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final capped = index.clamp(0, AppAnim.maxStaggered);
    return FadeSlideIn(delay: AppAnim.stagger * capped, child: child);
  }
}

/// تبديل ناعم بين حالات الشاشة (تحميل ← محتوى ← خطأ) بدل القفز الحاد.
/// يُغلف جسم الـ BlocBuilder: `StateSwitcher(child: _buildByState(state))`
/// مع إعطاء كل حالة `key` مميزاً.
class StateSwitcher extends StatelessWidget {
  final Widget child;

  const StateSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }
}
