import 'package:flutter/material.dart';

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

/// تصنيف رحلات «رحلاتي» إلى مجموعات يفهمها السائق.
///
/// الخادم يرسل ستّ حالات (`active`, `full`, `launched`, `finished`,
/// `cancelled`، ومعها `awaiting_confirmation` المهجورة التي حلّت
/// `launched` محلّها) — وعرضها جميعاً في
/// قائمة واحدة يخلط رحلة ألغاها السائق أمس برحلة تنطلق بعد ساعة وما زالت
/// تنتظر ركّاباً.
///
/// **متاحة وممتلئة مجموعتان لا واحدة**: السؤال الأول للسائق هو «أيّ
/// رحلاتي ما زالت تحتاج ركّاباً؟» — وضمّهما معاً يمحو الجواب.
///
/// **منطق نقيّ بلا واجهة** — عدا اللون والأيقونة اللذين يقرأهما شريط
/// الرقاقات — ليُختبر التصنيف وحده.
enum TripStatusFilter {
  /// كل الرحلات — الافتراضي، وملجأ ما لا نعرف حالته.
  all,

  /// تقبل الحجز: فيها مقاعد شاغرة ولم تنطلق.
  open,

  /// امتلأت مقاعدها.
  full,

  /// انطلقت وانتهت — أو تنتظر تأكيد الركّاب وصولهم.
  done,

  /// أُلغيت أو لم تقع.
  cancelled,
}

/// الحالات الخام لكل مجموعة — مكتوبة بحروف صغيرة، والمطابقة تُطبّع
/// الوارد قبلها لأن الخادم أرسل حالات بحروف كبيرة في بعض الردود.
const _openStatuses = {'active'};
const _fullStatuses = {'full'};
/// `launched` هي اسم `awaiting_confirmation` الجديد عند الخادم — وكانت
/// ناقصة هنا، فرحلةٌ انطلقت لا تُطابق مجموعةً فتختفي من كل الرقاقات إلا
/// «الكل»، ويبحث عنها سائقها في «منتهية» فلا يجدها.
const _doneStatuses = {
  'finished',
  'completed',
  'launched',
  'awaiting_confirmation',
};
const _cancelledStatuses = {'cancelled', 'canceled', 'no_show', 'rejected'};

extension TripStatusFilterX on TripStatusFilter {
  /// نصّ الرقاقة — قصير ليتّسع أكبر عدد منها في شاشة ضيّقة.
  String get label => switch (this) {
        TripStatusFilter.all => 'الكل',
        TripStatusFilter.open => 'متاحة',
        TripStatusFilter.full => 'ممتلئة',
        TripStatusFilter.done => 'منتهية',
        TripStatusFilter.cancelled => 'ملغاة',
      };

  /// لون المجموعة — من ألوان الحالة نفسها في `getStatusInfo` حيثما كان
  /// للمجموعة حالة واحدة، فلا يختلف لون الرقاقة عن لون الشارة داخل
  /// البطاقة.
  ///
  /// **«ممتلئة» وحدها تخرج عن القاعدة**: شارتها رمادية محايدة، وهو
  /// مناسب داخل بطاقة لكنه يُقرأ «معطّلاً» بين أربع رقاقات ملوّنة —
  /// ولون الرقاقة تمييز فئة لا حكم على الحالة.
  Color get color => switch (this) {
        TripStatusFilter.all => MyColors.primary,
        TripStatusFilter.open => MyColors.success,
        TripStatusFilter.full => MyColors.accent,
        TripStatusFilter.done => MyColors.blue,
        TripStatusFilter.cancelled => MyColors.error,
      };

  IconData get icon => switch (this) {
        TripStatusFilter.all => Icons.directions_car_filled_rounded,
        TripStatusFilter.open => Icons.event_available_rounded,
        TripStatusFilter.full => Icons.groups_rounded,
        TripStatusFilter.done => Icons.flag_rounded,
        TripStatusFilter.cancelled => Icons.cancel_rounded,
      };

  /// نصّ الشاشة الفارغة — «لا توجد رحلات» عامّة تُربك من فلتر على
  /// «ملغاة» ثم ظنّ أن رحلاته كلها اختفت.
  String get emptyMessage => switch (this) {
        TripStatusFilter.all => 'لا توجد رحلات',
        TripStatusFilter.open => 'لا رحلات متاحة للحجز',
        TripStatusFilter.full => 'لا رحلات ممتلئة',
        TripStatusFilter.done => 'لا رحلات منتهية',
        TripStatusFilter.cancelled => 'لا رحلات ملغاة',
      };

  /// هل تنتمي هذه الحالة الخام إلى المجموعة؟
  ///
  /// حالة لا نعرفها تبقى في [TripStatusFilter.all] وحدها — إخفاؤها من
  /// الجميع يعني ضياع رحلة من الشاشة، وحشرها في مجموعة بالتخمين يعني
  /// عرضها تحت عنوان كاذب. وهي القاعدة نفسها التي يتبعها زرّ الإلغاء
  /// في البطاقة: عند الشكّ يُعرض، والخادم يحسم.
  bool matches(String status) {
    final normalized = status.trim().toLowerCase();
    return switch (this) {
      TripStatusFilter.all => true,
      TripStatusFilter.open => _openStatuses.contains(normalized),
      TripStatusFilter.full => _fullStatuses.contains(normalized),
      TripStatusFilter.done => _doneStatuses.contains(normalized),
      TripStatusFilter.cancelled => _cancelledStatuses.contains(normalized),
    };
  }

  /// رحلات هذه المجموعة من قائمة كاملة، بترتيبها كما وصلت.
  List<TripModel> apply(List<TripModel> trips) => this == TripStatusFilter.all
      ? trips
      : trips.where((t) => matches(t.status)).toList();
}

/// عدد رحلات كل مجموعة — يُحسب مرّة واحدة لكل بناء بدل مرّة لكل رقاقة.
Map<TripStatusFilter, int> countTripsByFilter(List<TripModel> trips) => {
      for (final filter in TripStatusFilter.values)
        filter: filter.apply(trips).length,
    };
