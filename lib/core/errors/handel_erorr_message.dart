import 'package:alatarekak/core/utils/class/arabic_plural.dart';
import 'package:alatarekak/core/utils/class/no_show_report.dart';

/// ترجمة رسائل الباك إند الإنجليزية إلى عربية وفق مستند مواصفات الـ API.
/// القاعدة: لا تُعرض رسالة الباك إند للمستخدم أبداً — تُطابق برمجياً فقط.
/// المطابقة بـ contains() على lowercase لأن بعض الرسائل تحتوي أرقاماً متغيرة
/// (مثل "Your trust score (35) is too low...").
class HandelErorrMessage {
  // ---------- نصوص عامة مشتركة (§0.6) ----------
  static const String errValidation = "يرجى التحقق من البيانات المدخلة";
  static const String errServer = "حدث خطأ غير متوقع، يرجى المحاولة لاحقاً";
  static const String errNetwork =
      "تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت";
  static const String errSession =
      "انتهت الجلسة، يرجى تسجيل الدخول من جديد";
  static const String errPhoneSyrian =
      "يجب إدخال رقم هاتف سوري صحيح (09XXXXXXXX)";
  static const String errOtp6Digits = "يجب أن يتكون الرمز من 6 أرقام";
  static const String errPasswordMin =
      "يجب أن تتكون كلمة المرور من 8 أحرف على الأقل";
  static const String errPasswordConfirm = "كلمتا المرور غير متطابقتين";

  static const String errRateLimited =
      "عدد كبير من المحاولات، يرجى الانتظار قليلاً ثم إعادة المحاولة";

  /// هل الرد 429 من مُحدِّد المعدّل؟ الخادم يرسل "Too Many Attempts."
  /// و[RateLimitInterceptor] يُثبّت عدد ثواني الانتظار داخل النصّ.
  static bool isRateLimited(String message) =>
      message.toLowerCase().contains("too many attempts");

  static int? _retryAfterSeconds(String message) {
    final match = RegExp(r'(\d+)\s*seconds').firstMatch(message.toLowerCase());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// رسالة 429 عامة — تظهر في كل الشاشات المحميّة.
  static String rateLimited(String message) {
    final seconds = _retryAfterSeconds(message);
    return seconds == null
        ? errRateLimited
        : "عدد كبير من المحاولات، أعد المحاولة بعد $seconds ثانية";
  }

  /// رسالة 429 على شاشات المصادقة. الحدّ هناك محسوب بعنوان IP لا
  /// بالمستخدم، فمن يشترك في نفس الشبكة (بيانات الهاتف، واي فاي عام)
  /// يتقاسم الحدّ — والمستخدم يستحق أن يعرف أن السبب قد لا يكون منه.
  static String rateLimitedAuth(String message) {
    final seconds = _retryAfterSeconds(message);
    final wait = seconds == null ? "قليلاً" : "$seconds ثانية";
    return "محاولات كثيرة من هذه الشبكة. انتظر $wait ثم أعد المحاولة "
        "— قد يكون السبب مستخدماً آخر يشاركك الاتصال نفسه";
  }

  /// الأخطاء العامة المشتركة بين كل النقاط (جلسة، تحقق، OTP...).
  /// ترجع null إذا لم تطابق شيئاً ليُكمل المستدعي بخريطته الخاصة.
  static String? _common(String m) {
    // قبل كل شيء: 429 ليست خطأ منطق عمل ولا انتهاء جلسة
    if (isRateLimited(m)) return rateLimited(m);
    if (m.contains("unauthenticated") || m.contains("invalid token type")) {
      return errSession;
    }
    if (m.contains("validation failed") || m.contains("validation error")) {
      return errValidation;
    }
    if (m.contains("invalid or expired verification code") ||
        m.contains("invalid or expired otp")) {
      return "الرمز غير صحيح أو منتهي الصلاحية";
    }
    if (m.contains("expired or exceeded maximum attempts")) {
      return "انتهت صلاحية الرمز أو تجاوزت عدد المحاولات المسموح";
    }
    if (m.contains("too many") &&
        (m.contains("request") || m.contains("otp"))) {
      return "عدد كبير من المحاولات، يرجى الانتظار بضع دقائق ثم إعادة المحاولة";
    }
    if (m.contains("password confirmation does not match")) {
      return errPasswordConfirm;
    }
    if (m.contains("valid syrian mobile number")) return errPhoneSyrian;
    return null;
  }

  static String _match(String message, Map<String, String> map,
      {String fallback = errServer}) {
    final m = message.toLowerCase().trim();
    final common = _common(m);
    if (common != null) return common;
    for (final entry in map.entries) {
      if (m.contains(entry.key.toLowerCase())) return entry.value;
    }
    return fallback;
  }

  // =====================================================================
  // §1 المصادقة
  // =====================================================================

  /// مسارات المصادقة محدودة بـ 5 طلبات/دقيقة **لكل عنوان IP** لا لكل
  /// مستخدم، فرسالة 429 هنا تختلف عن بقية التطبيق.
  static String _auth(String message, Map<String, String> map) {
    if (isRateLimited(message)) return rateLimitedAuth(message);
    return _match(message, map);
  }

  static String login(String message) => _auth(message, {
        "invalid credentials": "البريد الإلكتروني أو كلمة المرور غير صحيحة",
        // 403 EMAIL_NOT_VERIFIED — الواجهة تنقله إلى شاشة الرمز، وهذا
        // النصّ احتياطٌ لو تعذّر الانتقال
        "email address is not verified":
            "لم يتم تأكيد بريدك الإلكتروني بعد — أدخل رمز التحقق المُرسل إليك",
      });

  /// الحساب موجود وكلمة مروره صحيحة، لكن بريده غير مؤكَّد.
  ///
  /// ليس فشل دخول بل **خطوة ناقصة**: الواجهة تنقله إلى شاشة إدخال الرمز
  /// بدل أن تتركه أمام رسالة لا يعرف ما يفعل بعدها. يرسله الخادم بحالة
  /// 403 مع `code: EMAIL_NOT_VERIFIED` — والنصّ احتياط لو غاب الكود.
  static bool isEmailNotVerified(String message) =>
      message.toLowerCase().contains("email address is not verified") ||
      message.toLowerCase().contains("email is not verified");

  static String singin(String message) => _auth(message, {
        "already registered":
            "هذا البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول",
        "could not send verification email":
            "تعذر إرسال رمز التحقق إلى بريدك، يرجى المحاولة مرة أخرى",
        "registration failed": errServer,
      });

  /// تسجيل الخروج — فشله لا يمنع الخروج محلياً، لكن الرسالة كانت تُعرض
  /// كما وصلت من الخادم.
  static String logout(String message) =>
      _match(message, {}, fallback: "فشل تسجيل الخروج، حاول مجدداً");

  // =====================================================================
  // §2 استعادة كلمة المرور
  // =====================================================================

  static String forgetPassword(String message) => _auth(message, {
        "no account found": "لا يوجد حساب مسجل بهذا البريد الإلكتروني",
        "failed to send": "تعذر إرسال رمز التحقق، يرجى المحاولة مرة أخرى",
      });

  static String verifyOtpForgetPassword(String message) => _auth(message, {
        "no account found": "لا يوجد حساب بهذا البريد",
      });

  static String resetPassword(String message) => _auth(message, {
        "expired or has already been used":
            "انتهت صلاحية رمز إعادة التعيين، يرجى طلب رمز جديد",
        "account not found": "تعذر العثور على الحساب",
      });

  // =====================================================================
  // §3 تأكيد البريد الإلكتروني
  // =====================================================================

  static String emailVerification(String message) => _auth(message, {
        "no account found": "لا يوجد حساب بهذا البريد",
        "already verified": "هذا البريد مؤكد مسبقاً، يمكنك تسجيل الدخول",
        "failed to send": "تعذر إرسال البريد، حاول مجدداً",
      });

  // =====================================================================
  // §5 نقاط الثقة
  // =====================================================================

  /// `/score` و`/score/transactions` — مساران للقراءة فقط، فأخطاؤهما
  /// الواقعية هي أخطاء الوصول لا أخطاء منطق العمل: جلسة منتهية، أو تجاوز
  /// حدّ الطلبات. وكلاهما يلتقطه [_common] قبل أي خريطة.
  ///
  /// الخريطة فارغة عن قصد: لا نعرف رسالة خاصة يرسلها الخادم هنا، واختراع
  /// مفاتيح لا وجود لها يعطي وهم التغطية ولا يترجم شيئاً. القيمة كلها في
  /// تمرير رسالة الخادم إلى [_common] بدل رميها.
  static String score(String message) => _match(message, {});

  // =====================================================================
  // §6 الملف الشخصي
  // =====================================================================

  static String showProfile(String message) => _match(message, {
        "profile not found": "الملف الشخصي غير موجود",
      });

  static String updateProfile(String message) => _match(message, {
        // الخادم يقفل الاسم وبيانات المركبة ما دام طلب التوثيق معلّقاً،
        // لأنها البيانات نفسها التي يراجعها الأدمن
        "while verification is pending":
            "لا يمكن تعديل الاسم أو بيانات المركبة أثناء مراجعة طلب التوثيق. "
                "يمكنك تعديل باقي البيانات، أو الانتظار حتى يُبتّ في طلبك",
        "cannot modify documents while verification is pending":
            "لا يمكن تعديل المستندات أثناء مراجعة طلب التوثيق",
        "image": "يجب أن تكون الصورة بصيغة JPG أو PNG وبحجم أقصى 2 ميغابايت",
      });

  static String commet(String message) => _match(message, {
        "comment": "التعليق مطلوب (بحد أقصى 500 حرف)",
      });

  static String rateUser(String message) => _match(message, {
        "rating": "يرجى اختيار تقييم من 1 إلى 5",
      });

  static String uploadDocument(String message) => _match(message, {
        "cannot modify documents while verification is pending":
            "لا يمكن تعديل المستندات أثناء مراجعة طلب التوثيق",
        "image": "يرجى اختيار نوع المستند وصورة صالحة (JPG/PNG، بحد أقصى 2MB)",
      });

  static String verfiyPassanger(String message) => _match(message, {
        "pending verification request": "لديك طلب توثيق قيد المراجعة بالفعل",
        "image": "يجب أن تكون الصورة بصيغة JPG أو PNG وبحجم أقصى 2 ميغابايت",
      });

  static String verfiyDriver(String message) => verfiyPassanger(message);

  // =====================================================================
  // §7 الرحلات
  // =====================================================================

  static String search(String message) => _match(message, {
        // البحث يتطلب توثيق الراكب — والواجهة تُتبع الرسالة بتوجيهه إلى
        // شاشة التوثيق، فالنصّ هنا يمهّد لها لا يكتفي بالاعتذار
        "must be verified as a passenger":
            "يجب توثيق حسابك كراكب قبل البحث عن الرحلات",
        "search failed": "فشل البحث، يرجى المحاولة مرة أخرى",
        "departure_date": "يرجى اختيار تاريخ اليوم أو تاريخ لاحق",
      }, fallback: "فشل البحث، يرجى المحاولة مرة أخرى");

  /// هل رُفض الطلب لأن الراكب غير موثَّق؟ الواجهة تنقله إلى شاشة التوثيق
  /// بدل تركه أمام رسالة لا يعرف ما يفعل بعدها.
  static bool isPassengerNotVerified(String message) =>
      message.toLowerCase().contains("verified as a passenger");

  static String routeOptions(String message) => _match(message, {
        "failed to get route options": "تعذر حساب المسار، حاول مجدداً",
      }, fallback: "تعذر حساب المسار، حاول مجدداً");

  // ---------- رسوم الرحلات النقدية (5% من المحفظة عند الإنشاء) ----------
  // الخادم يرمي هذه الأخطاء بحالة 500 لا 422، ورسائلها تحمل مبالغ متغيرة،
  // لذا تُطابق قبل الخريطة العامة وتُستخرج منها الأرقام.

  static String? _cashRideFee(String m, String original) {
    if (m.contains("must create a wallet")) {
      return "يجب إنشاء محفظة إلكترونية قبل إنشاء رحلة بالدفع النقدي";
    }
    if (m.contains("outstanding debt")) {
      // المبلغ لم يعد يُستخرج من نصّ الرسالة: صار له مصدر حقيقي في
      // meta.cash_ride_debt من GET /wallet/transactions، وتعرضه شاشة
      // المحفظة في بطاقة مستقلة. الاستخراج النصّي كان هشّاً وينكسر
      // بأي تغيير في صياغة الخادم.
      return "عليك رسوم مستحقّة من رحلات نقدية سابقة. اطّلع على قيمتها في "
          "محفظتك واشحنها لتسويتها قبل إنشاء رحلة جديدة";
    }
    if (m.contains("insufficient wallet balance") &&
        m.contains("creation fee")) {
      final amounts = _amounts(original);
      if (amounts.length >= 2) {
        return "رصيد محفظتك لا يكفي رسوم إنشاء هذه الرحلة (${amounts[0]} ل.س)، "
            "ورصيدك الحالي ${amounts[1]} ل.س. اشحن محفظتك ثم أعد المحاولة";
      }
      return "رصيد محفظتك لا يكفي رسوم إنشاء الرحلة، اشحن محفظتك ثم أعد المحاولة";
    }
    return null;
  }

  /// المبالغ الواردة في رسالة الخادم بالترتيب (مثل "1,500.00 SYP").
  static List<String> _amounts(String message) => RegExp(
        r'([0-9][0-9,]*(?:\.[0-9]+)?)\s*SYP',
        caseSensitive: false,
      ).allMatches(message).map((m) => m.group(1)!).toList();

  /// السائق لا يملك محفظة — الواجهة تعرض له طريقاً مباشراً لإنشائها.
  static bool isCashRideWalletMissing(String message) =>
      message.toLowerCase().contains("must create a wallet");

  /// هل فشل إنشاء الرحلة بسبب رسوم الدفع النقدي؟ (محفظة/دين/رصيد)
  static bool isCashRideFeeError(String message) =>
      _cashRideFee(message.toLowerCase().trim(), message) != null;

  static String createWithRoute(String message) {
    final cash = _cashRideFee(message.toLowerCase().trim(), message);
    if (cash != null) return cash;
    return _match(message, {
      // أخطاء تحقّق الحقول (صيغة Laravel الافتراضية) — تصل كنصّ إنجليزي
      // يذكر اسم الحقل، فنترجمها بدل إظهار «حدث خطأ غير متوقع»
      "vehicle type field is required":
          "نوع المركبة مطلوب — أضف سيارتك من «مركباتي» في ملفك الشخصي",
      "vehicle type": "يرجى تحديد نوع المركبة",
      "available seats": "يرجى تحديد عدد المقاعد المتاحة",
      "price per seat": "يرجى إدخال سعر المقعد",
      "communication number": "رقم التواصل مطلوب ويجب أن يبدأ بـ 09",
      "pickup": "يرجى تحديد نقطة الانطلاق على الخريطة",
      "destination": "يرجى تحديد الوجهة على الخريطة",
      "must be verified as a driver": "يجب توثيق حسابك كسائق قبل إنشاء الرحلات",
      "missing required verification documents":
          "يجب توثيق حسابك كسائق قبل إنشاء الرحلات",
      "driver profile not found": "يرجى إكمال ملفك الشخصي أولاً",
      "trust score": "نقاط الثقة لديك غير كافية لإنشاء رحلات (الحد الأدنى 50)",
      "at least 5 minutes":
          "يجب أن يكون موعد الانطلاق بعد 5 دقائق على الأقل من الآن",
      "departure_time":
          "يجب أن يكون موعد الانطلاق بعد 5 دقائق على الأقل من الآن",
      "more than 30 days": "لا يمكن جدولة رحلة بعد أكثر من 30 يوماً",
      "insufficient wallet balance": "لا يوجد رصيد كافٍ في المحفظة",
      "price": "يرجى إدخال سعر صحيح",
    });
  }

  static String showAllride(String message) => _match(message, {});

  static String showOneRide(String message) => _match(message, {
        "ride not found": "الرحلة غير موجودة",
      });

  static String cancelRide(String message) => _match(message, {
        "only the ride creator": "لا يمكنك إلغاء رحلة لم تقم بإنشائها",
        "cannot cancel a ride with status":
            "لا يمكن إلغاء الرحلة في حالتها الحالية",
        "less than 1 hour":
            "لا يمكن إلغاء الرحلة قبل أقل من ساعة من موعد الانطلاق",
      });

  static String bookAset(String message) => _match(message, {
        "must be verified as a passenger":
            "يجب توثيق حسابك كراكب قبل حجز الرحلات",
        "trust score":
            "نقاط الثقة لديك غير كافية لحجز الرحلات (الحد الأدنى 40)",
        "cannot book their own rides": "لا يمكنك حجز مقعد في رحلتك الخاصة",
        "already have an active booking":
            "لديك حجز فعّال في هذه الرحلة بالفعل",
        "already booked this ride": "لديك حجز فعّال في هذه الرحلة بالفعل",
        "at least 1 seat": "يجب حجز مقعد واحد على الأقل",
        "more than 8 seats": "لا يمكن حجز أكثر من 8 مقاعد",
        "not enough seats": "عدد المقاعد المتاحة غير كافٍ",
        "not available for booking": "هذه الرحلة لم تعد متاحة للحجز",
        "insufficient balance": "رصيد محفظتك غير كافٍ لإتمام الحجز",
        "wallet balance": "رصيد محفظتك غير كافٍ لإتمام الحجز",
      }, fallback: "تعذر إتمام الحجز، حاول مجدداً");

  /// نقص الرصيد بعد التعريب — الواجهة تستقبل الرسالة العربية لا الخام.
  ///
  /// ليس عطلاً بل حالة يعالجها المستخدم، فالشاشة تعرض له «اشحن محفظتي»
  /// بدل «أعد المحاولة»: إعادة المحاولة برصيد لم يتغيّر تعيد الخطأ نفسه.
  static bool isInsufficientBalance(String message) =>
      message.contains("رصيد محفظتك غير كافٍ") ||
      message.contains("رصيد محفظتك لا يكفي");

  /// رحلة بلا ركّاب: الخادم ينهيها فعلاً ثم يرمي هذا الخطأ بحالة 400
  /// (عيب مؤكد في الباك إند). المستدعي يعيد جلب الرحلة ويتحقق من
  /// status == "finished" بدل عرض خطأ كاذب للسائق.
  static bool isRideNotAwaitingConfirmation(String message) =>
      message.toLowerCase().contains("not awaiting confirmation");

  /// تأكيد مكرر (ضغط مزدوج على الزر) — حالة طبيعية تُعامل كنجاح صامت.
  /// الخادم يرجعها بحالة 500 من passenger-confirm وبحالة 400 من driver-confirm.
  static bool isAlreadyConfirmed(String message) =>
      message.toLowerCase().contains("already confirmed");

  static String finishRide(String message) => _match(message, {
        "only the ride driver": "هذا الإجراء متاح لسائق الرحلة فقط",
        "can only finish an active or full ride":
            "لا يمكن إنهاء الرحلة في حالتها الحالية",
        "before its departure time":
            "لا يمكن إنهاء الرحلة قبل موعد انطلاقها",
        "no confirmed bookings found":
            "لا يوجد حجوزات في هذه الرحلة، يمكنك إلغاؤها بدلاً من ذلك",
        // تصل هنا فقط إذا لم تكن الرحلة قد انتهت فعلاً — الحالة الكاذبة
        // (رحلة بلا ركّاب) يلتقطها isRideNotAwaitingConfirmation قبلها
        "not awaiting confirmation": "الرحلة ليست بانتظار التأكيد",
      });

  static String driverConfirm(String message) => _match(message, {
        "only the ride driver": "هذا الإجراء متاح للسائق فقط",
        "not awaiting confirmation": "الرحلة ليست بانتظار التأكيد",
        "already confirmed": "قمت بتأكيد هذه الرحلة مسبقاً",
      });

  /// بلاغ الراكب عن غياب السائق.
  ///
  /// «unlocks» تحمل الدقائق المتبقية في نصّها، فتُعرض بها بدل جملة عامّة
  /// لا تقول للمستخدم متى يعود.
  static String driverNoShow(String message) {
    final minutes = NoShowReport.minutesUntilUnlock(message);
    if (minutes != null) return _unlocksIn(minutes);

    return _match(message, {
      "before the departure time": "لا يمكن الإبلاغ قبل موعد الانطلاق",
      "no confirmed booking found": "لا يوجد لديك حجز مؤكد في هذه الرحلة",
      "already submitted": "سبق أن أبلغت عن هذه الرحلة",
      "cannot report no-show for a ride with status":
          "لم يعد الإبلاغ متاحاً لهذه الرحلة",
      // «غير موجود» يصل 422 برسالة Laravel خام لا 404 — تُطابَق بنصّها
      "no query results for model": "الرحلة غير موجودة",
    });
  }

  /// «يمكنك الإبلاغ بعد ٣٧ دقيقة» — بصيغة العربية لا «37 دقيقة» دائماً.
  static String _unlocksIn(int minutes) =>
      'الإبلاغ عن الغياب يُفتح بعد ساعة من الانطلاق — يمكنك الإبلاغ بعد '
      '${arabicMinutes(minutes)}';

  // =====================================================================
  // §8 الحجوزات
  // =====================================================================

  static String bookingMe(String message) => _match(message, {
        "must be verified as a passenger": "لم يتم توثيق الحساب",
        "not in confirmation state":
            "لم يتم تأكيد إنهاء الرحلة من قبل السائق بعد",
      });

  static String acceptPassanger(String message) => _match(message, {
        "only the ride driver": "متاح لسائق الرحلة فقط",
        "only request-type": "هذا الحجز لا يتطلب موافقة",
        "only pending bookings": "لا يمكن قبول هذا الحجز في حالته الحالية",
      });

  static String rejectPassanger(String message) => _match(message, {
        "only the ride driver": "متاح لسائق الرحلة فقط",
        "only request-type": "هذا الحجز لا يتطلب موافقة",
        "only pending bookings": "لا يمكن رفض هذا الحجز في حالته الحالية",
      });

  static String cancelBooking(String message) => _match(message, {
        "only cancel your own": "لا يمكنك إلغاء حجز لا يخصك",
        "less than 2 hours":
            "لا يمكن إلغاء الحجز قبل أقل من ساعتين من موعد الانطلاق",
        "cannot be partially cancelled": "لا يمكن الإلغاء الجزئي لهذا الحجز",
      });

  static String passangerConfirm(String message) => _match(message, {
        "only the booking passenger": "متاح لصاحب الحجز فقط",
        "not awaiting confirmation": "الرحلة ليست بانتظار التأكيد",
        "only confirmed bookings": "لا يمكن تأكيد هذا الحجز",
        "already confirmed": "قمت بالتأكيد مسبقاً",
      });

  /// بلاغ السائق عن غياب راكب — لكل حجز على حدة.
  static String passengerNoShow(String message) {
    final minutes = NoShowReport.minutesUntilUnlock(message);
    if (minutes != null) return _unlocksIn(minutes);

    return _match(message, {
      "only the ride driver": "متاح لسائق الرحلة فقط",
      "only report no-shows for your own rides": "متاح لسائق الرحلة فقط",
      "for confirmed bookings": "الحجز غير مؤكد",
      "is not in 'confirmed' status": "هذا الحجز غير مؤكَّد",
      "before the departure time": "لا يمكن الإبلاغ قبل موعد الانطلاق",
      "already submitted": "سبق أن أبلغت عن هذا الراكب",
      "cannot report no-show for a ride with status":
          "لم يعد الإبلاغ متاحاً لهذه الرحلة",
      "no query results for model": "الحجز غير موجود",
    });
  }

  // =====================================================================
  // §9 المحادثات
  // =====================================================================

  static String chat(String message) => _match(message, {
        "conversation not found": "المحادثة غير موجودة",
        "not a participant": "لا يمكنك إرسال رسائل في هذه المحادثة",
        "invalid message type": "نوع الرسالة غير مدعوم",
        "invalid message data": "محتوى الرسالة غير صالح",
        "invalid image file": "الصورة غير صالحة",
        "failed to send message": "تعذر إرسال الرسالة، حاول مجدداً",
        "message not found": "تعذر حذف الرسالة",
      });

  // =====================================================================
  // §11 المحفظة
  // =====================================================================

  static String checkbalance(String message) => _match(message, {
        "wallet not found": "لا تملك محفظة بعد، أنشئ واحدة الآن",
      });

  /// إنشاء المحفظة مباشرة برقم الهاتف بلا رمز تحقق.
  static String createWalletDirect(String message) => _match(message, {
        "already have a wallet": "لديك محفظة بالفعل",
        "already linked": "هذا الرقم مستخدم في محفظة أخرى",
        "already been taken": "هذا الرقم مستخدم في محفظة أخرى",
        "phone_number": "هذا الرقم مستخدم في محفظة أخرى",
      }, fallback: "تعذر إنشاء المحفظة، حاول مجدداً");

  /// المحفظة موجودة أصلاً — ليست خطأً: الواجهة تكتفي بتحديث الرصيد.
  static bool isWalletAlreadyExists(String message) =>
      message.toLowerCase().contains("already have a wallet");

  static String requestCharge(String message) => _match(message, {
        "do not have a wallet": "أنشئ محفظة أولاً",
        "pending charge request": "لديك طلب شحن قيد المراجعة بالفعل",
        "amount": "يرجى إدخال مبلغ صحيح",
      });

  static String requestWithdraw(String message) => _match(message, {
        "do not have a wallet": "أنشئ محفظة أولاً",
        "insufficient balance": "الرصيد غير كافٍ",
        "pending withdraw requests":
            "لديك طلبات سحب معلقة، هذا الطلب يتجاوز رصيدك",
        "amount": "يرجى إدخال مبلغ صحيح",
      });

  // =====================================================================
  // §12-13 الشكاوى والدعم
  // =====================================================================

  static String complaint(String message) => _match(message, {
        "complaint not found": "الشكوى غير موجودة",
        "title": "عنوان الشكوى مطلوب",
        "description": "وصف الشكوى مطلوب",
        "type": "يرجى اختيار نوع الشكوى",
        "attachments":
            "المرفقات: حتى 3 ملفات (صورة أو PDF) بحجم أقصى 5MB لكل ملف",
      });

  static String contactSupport(String message) => _match(message, {
        "no support agents": "الدعم غير متاح حالياً، يرجى المحاولة لاحقاً",
        "currently unavailable": "الدعم غير متاح حالياً، يرجى المحاولة لاحقاً",
        "cannot open support chat": "تعذر فتح محادثة الدعم",
      });

  // =====================================================================
  // §10 الإشعارات
  // =====================================================================

  static String notifications(String message) => _match(message, {
        "notification not found": "الإشعار غير موجود",
        "no notifications found": "لا توجد إشعارات",
      });
}
