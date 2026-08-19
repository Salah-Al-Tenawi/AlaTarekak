import 'package:flutter/material.dart';

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';

/// تصنيف حجوزات «حجوزاتي» إلى مجموعات يفهمها الراكب.
///
/// الخادم يرسل تسع حالات (`pending`, `accepted`, `confirmed`,
/// `awaiting_confirmation`, `ongoing`, `completed`, `finished`,
/// `cancelled`, `rejected`, `no_show`) — وعرضها تبويباً لكل واحدة يُغرق
/// الشاشة بتفريق لا يعني الراكب: «مقبول» و«مؤكّد» عنده حالة واحدة،
/// و«مرفوض» و«ملغى» نهاية واحدة. فجُمعت في أربع مجموعات ومجموعة جامعة.
///
/// **منطق نقيّ بلا واجهة** — عدا اللون والأيقونة اللذين يقرأهما شريط
/// الرقاقات — ليُختبر التصنيف وحده.
enum BookingStatusFilter {
  /// كل الحجوزات — الافتراضي، وملجأ ما لا نعرف حالته.
  all,

  /// طلب أُرسل وينتظر ردّ السائق.
  pending,

  /// حجز قائم: قُبل أو أُكّد أو الرحلة جارية.
  confirmed,

  /// انتهت الرحلة — بقي التقييم غالباً.
  completed,

  /// انتهى الحجز بلا رحلة: إلغاء أو رفض أو عدم حضور.
  cancelled,
}

/// الحالات الخام لكل مجموعة — مكتوبة بحروف صغيرة، والمطابقة تُطبّع
/// الوارد قبلها لأن الخادم أرسل `CONFIRMED` في بعض الردود.
const _pendingStatuses = {'pending'};
const _confirmedStatuses = {
  'accepted',
  'confirmed',
  'awaiting_confirmation',
  'ongoing',
};
const _completedStatuses = {'completed', 'finished'};
const _cancelledStatuses = {'cancelled', 'canceled', 'rejected', 'no_show'};

extension BookingStatusFilterX on BookingStatusFilter {
  /// نصّ الرقاقة — قصير ليتّسع أربعة منها في شاشة ضيّقة.
  String get label => switch (this) {
        BookingStatusFilter.all => 'الكل',
        BookingStatusFilter.pending => 'قيد الانتظار',
        BookingStatusFilter.confirmed => 'مؤكّدة',
        BookingStatusFilter.completed => 'منتهية',
        BookingStatusFilter.cancelled => 'ملغاة',
      };

  /// لون المجموعة — من ألوان الحالة نفسها في `getStatusInfo`، فلا يختلف
  /// لون الرقاقة عن لون الشارة داخل البطاقة.
  Color get color => switch (this) {
        BookingStatusFilter.all => MyColors.primary,
        BookingStatusFilter.pending => MyColors.accent,
        BookingStatusFilter.confirmed => MyColors.success,
        BookingStatusFilter.completed => MyColors.blue,
        BookingStatusFilter.cancelled => MyColors.error,
      };

  IconData get icon => switch (this) {
        BookingStatusFilter.all => Icons.confirmation_number_rounded,
        BookingStatusFilter.pending => Icons.hourglass_top_rounded,
        BookingStatusFilter.confirmed => Icons.check_circle_rounded,
        BookingStatusFilter.completed => Icons.flag_rounded,
        BookingStatusFilter.cancelled => Icons.cancel_rounded,
      };

  /// نصّ الشاشة الفارغة — «لا توجد حجوزات» عامّة تُربك من فلتر على
  /// «ملغاة» ثم ظنّ أن حجوزاته كلها اختفت.
  String get emptyMessage => switch (this) {
        BookingStatusFilter.all => 'لا توجد حجوزات',
        BookingStatusFilter.pending => 'لا حجوزات قيد الانتظار',
        BookingStatusFilter.confirmed => 'لا حجوزات مؤكّدة',
        BookingStatusFilter.completed => 'لا رحلات منتهية',
        BookingStatusFilter.cancelled => 'لا حجوزات ملغاة',
      };

  /// هل تنتمي هذه الحالة الخام إلى المجموعة؟
  ///
  /// حالة لا نعرفها تبقى في [BookingStatusFilter.all] وحدها — إخفاؤها
  /// من الجميع يعني ضياع حجز من الشاشة، وحشرها في مجموعة بالتخمين يعني
  /// عرضه تحت عنوان كاذب.
  bool matches(String status) {
    final normalized = status.trim().toLowerCase();
    return switch (this) {
      BookingStatusFilter.all => true,
      BookingStatusFilter.pending => _pendingStatuses.contains(normalized),
      BookingStatusFilter.confirmed => _confirmedStatuses.contains(normalized),
      BookingStatusFilter.completed => _completedStatuses.contains(normalized),
      BookingStatusFilter.cancelled => _cancelledStatuses.contains(normalized),
    };
  }

  /// حجوزات هذه المجموعة من قائمة كاملة، بترتيبها كما وصلت.
  List<BookingMe> apply(List<BookingMe> bookings) =>
      this == BookingStatusFilter.all
          ? bookings
          : bookings.where((b) => matches(b.status)).toList();
}

/// عدد حجوزات كل مجموعة — يُحسب مرّة واحدة لكل بناء بدل مرّة لكل رقاقة.
Map<BookingStatusFilter, int> countByFilter(List<BookingMe> bookings) => {
      for (final filter in BookingStatusFilter.values)
        filter: filter.apply(bookings).length,
    };
