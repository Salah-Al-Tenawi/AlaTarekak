class NotificationEntity {
  final int id;
  final String title;
  final String message;

  /// general | ride | chat | profile | system
  final String category;
  final String? type;
  final String? priority;
  final bool isRead;
  final DateTime? createdAt;

  /// حمولة الربط العميق: ride_id, booking_id, complaint_id...
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.type,
    this.priority,
    required this.isRead,
    this.createdAt,
    this.data,
  });

  /// معرفات الربط العميق (إن وجدت)
  int? get rideId => _dataInt('ride_id');
  int? get bookingId => _dataInt('booking_id');
  int? get complaintId => _dataInt('complaint_id');
  int? get conversationId => _dataInt('conversation_id');

  int? _dataInt(String key) {
    final v = data?[key];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  /// العنوان للعرض: الباك إند يخزن أغلب العناوين بالإنجليزية (العيب D5)
  /// — نعيد العنونة بالعربية حسب type حتى يُعرَّب الباك إند.
  /// أي type جديد أو غير معروف يسقط إلى عنوان الخادم كما هو (لا ينكسر شيء).
  String get displayTitle => _arabicTitles[type] ?? title;

  static const Map<String, String> _arabicTitles = {
    'ride_created': 'تم إنشاء الرحلة',
    'ride_cancelled_driver': 'تم إلغاء الرحلة',
    'ride_cancelled': 'تم إلغاء الرحلة',
    'ride_cancelled_by_driver': 'قام السائق بإلغاء الرحلة',
    'ride_finished_no_passengers': 'انتهت الرحلة',
    'confirm_completion_needed': 'يرجى تأكيد إتمام الرحلة',
    'ride_completed': 'اكتملت الرحلة',
    'driver_no_show_reported': 'بلاغ عدم حضور بحقك',
    'driver_no_show_refund': 'تمت إعادة المبلغ',
    'ride_booked': 'حجز جديد',
    'booking_requested': 'طلب حجز جديد',
    'booking_confirmed': 'تم تأكيد حجزك',
    'booking_request_sent': 'تم إرسال طلب الحجز',
    'booking_accepted': 'تم قبول حجزك',
    'booking_rejected': 'تم رفض طلب الحجز',
    'booking_cancelled': 'تم إلغاء الحجز',
    'passenger_cancelled': 'قام الراكب بإلغاء مقاعد',
    'passenger_no_show': 'تسجيل عدم حضور',
    'complaint_resolved': 'تم الرد على شكواك',
    'verification_rejected': 'طلب التوثيق مرفوض',
    'verification_approved': 'تم توثيق حسابك',
    'wallet_request_approved': 'تمت الموافقة على طلب المحفظة',
    'wallet_request_rejected': 'تم رفض طلب المحفظة',
    'wallet_charged': 'تم شحن محفظتك',
    'account_banned': 'تم حظر حسابك',
    'account_unbanned': 'تمت إعادة تفعيل حسابك',
    'chat_message': 'رسالة جديدة',
    // أنواع أضافها الباك إند لاحقاً
    'charge_request_received': 'تم استلام طلب شحن المحفظة',
    'withdraw_request_received': 'تم استلام طلب سحب الرصيد',
    'verification_submitted': 'تم استلام طلب التوثيق',
    'passenger_confirmed': 'أكّد الراكب إتمام الرحلة',
    'seats_partially_cancelled': 'ألغى الراكب جزءاً من مقاعده',
    'no_show_recorded': 'تم تسجيل عدم حضورك',
    'driver_no_show_recorded': 'بلاغ عدم حضور بحقك',
    // من مرجع الباك إند (ride_notifications_reference): يرسلهما
    // RideController في مساره الموازي، وكانا يسقطان إلى عنوان الخادم
    'booking_cancelled_by_passenger': 'ألغى الراكب حجزه',
    'ride_finished': 'انتهت الرحلة',
    // نظام الغياب: للطرفين ساعتان للاعتراض بعد أي بلاغ، ثم يُحسم
    // تلقائياً — إلا أن يكون الطرفان أبلغا فتُفتح شكوى بلا عقوبة.
    'noshow_driver_reported_you': 'السائق أبلغ عن غيابك',
    'noshow_passenger_reported_you': 'الراكب أبلغ عن غيابك',
    'noshow_conflict': 'تعارض في تقارير الغياب',
    'noshow_penalty_applied': 'طُبّقت عقوبة الغياب',
    'noshow_resolved_in_your_favor': 'حُسم بلاغ الغياب لصالحك',
  };

  /// التصنيف المعروض — يُشتقّ من `type` لا من الحقل الواصل.
  ///
  /// `category` **غير موجود في قاعدة بيانات الباك إند إطلاقاً** (يُمرَّر
  /// إلى FCM فقط)، فيسقط كل إشعار إلى `general`: الأيقونة نفسها واللون
  /// نفسه للجميع، وشرط `category == 'chat'` لا يتحقق أبداً.
  ///
  /// و`type` موجود ومخزَّن، ويكفي لتصنيف كل نوع في مرجع الباك إند.
  /// ويُقدَّم الحقل الواصل حين يصل بقيمة حقيقية، فإن عرّبه الباك إند
  /// لاحقاً ساد على الاشتقاق.
  String get displayCategory {
    if (category.isNotEmpty && category != 'general') return category;
    return categoryOf(type) ?? category;
  }

  /// تصنيف نوع الإشعار — مبني على مرجع الباك إند
  /// (`ride_notifications_reference`).
  static String? categoryOf(String? type) {
    final t = type?.trim().toLowerCase();
    if (t == null || t.isEmpty) return null;
    if (t == 'chat_message') return 'chat';
    if (t.startsWith('verification_')) return 'profile';
    if (t.startsWith('wallet_') ||
        t.startsWith('charge_request') ||
        t.startsWith('withdraw_request') ||
        t.startsWith('account_') ||
        t.startsWith('complaint_')) {
      return 'system';
    }
    // كل ما تبقّى في المرجع رحلات وحجوزات: ride_* و booking_* و
    // passenger_* و driver_* و seats_* و no_show_* و confirm_*
    if (t.startsWith('ride') ||
        t.startsWith('booking') ||
        t.startsWith('passenger') ||
        t.startsWith('driver') ||
        t.startsWith('seats') ||
        t.startsWith('no_show') ||
        t.startsWith('confirm')) {
      return 'ride';
    }
    // نظام الغياب: التعارض والعقوبة قراران إداريان لا حدثا رحلة —
    // يصنّفهما الباك إند `system`، والباقي `ride`.
    if (t.startsWith('noshow')) {
      return (t == 'noshow_conflict' || t == 'noshow_penalty_applied')
          ? 'system'
          : 'ride';
    }
    return null;
  }

  /// **عائلة إشعار الغياب** — لإزالة تكرار الخادم.
  ///
  /// كل بلاغ غياب يصل الطرف المستهدف **إشعارين**: واحداً من الخدمة
  /// وآخر من الكونترولر، لهما رقمان مختلفان ونصّان متقاربان عن الحدث
  /// نفسه. فيُجمعان بعائلة واحدة ويُعرض أحدثهما.
  ///
  /// `null` لكل ما ليس من هذا الازدواج — فلا يُخفى إشعار مستقلّ سهواً.
  static String? noShowFamily(String? type) {
    switch (type?.trim().toLowerCase()) {
      case 'noshow_driver_reported_you':
      case 'no_show_recorded':
        return 'noshow_reported_passenger';
      case 'noshow_passenger_reported_you':
      case 'driver_no_show_recorded':
        return 'noshow_reported_driver';
      default:
        return null;
    }
  }

  /// مفتاح إزالة التكرار: العائلة والكيان الذي تخصّه. `null` يعني
  /// «اعرضه كما هو».
  String? get dedupeKey {
    final family = noShowFamily(type);
    if (family == null) return null;

    // البلاغ عن راكب يخصّ حجزه، والبلاغ عن سائق يخصّ الرحلة
    final entity = bookingId ?? rideId;
    return entity == null ? null : '$family:$entity';
  }

  /// تسميات التصنيفات بالعربية — الباك إند يرسلها إنجليزية (§10.3)
  static const Map<String, String> categoryLabels = {
    'general': 'عام',
    'ride': 'الرحلات',
    'chat': 'الرسائل',
    'profile': 'الملف الشخصي',
    'system': 'النظام',
  };

  String get categoryLabel => categoryLabels[category] ?? 'عام';
}

/// صفحة إشعارات مع بيانات الـ pagination وعداد غير المقروء (§10.1)
class NotificationsPageEntity {
  final List<NotificationEntity> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int unreadCount;

  const NotificationsPageEntity({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.unreadCount,
  });

  bool get hasMore => currentPage < lastPage;
}
