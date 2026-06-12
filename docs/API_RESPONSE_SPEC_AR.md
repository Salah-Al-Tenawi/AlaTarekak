# API Response Specification — Mobile Client (Flutter)

> **Audience:** AI/developer building the Flutter client.
> **Backend:** Laravel 10, JWT auth (custom middleware), responses are **always JSON**.
> **Localization status:** The backend has **NO translation files** (`lang/` does not exist). All `message` strings are **hardcoded English**, except the governorate (`address`) enum values which are already Arabic. Therefore: **the Flutter client is fully responsible for Arabic localization.** Never display the backend `message` directly to the user — map scenarios to the Arabic strings specified below. Backend messages/`code` fields are for programmatic matching only.
> **Scope:** Mobile-facing endpoints only (auth, OTP, profile, rides, bookings, chat, notifications, wallet, complaints, contact). Admin/Staff/Employee panel routes are excluded.

---

# 0. Global Conventions

## 0.1 Base URL & Headers

```
Base URL : https://<host>/api
Headers  : Accept: application/json
           Content-Type: application/json   (multipart/form-data for file uploads)
           Authorization: Bearer <access_token>   (protected endpoints)
```

## 0.2 ⚠️ TWO response envelopes exist (inconsistent backend)

The backend mixes two envelope styles. The Flutter response parser **must handle both**:

| Style | Success shape | Error shape | Used by |
|---|---|---|---|
| A — `success` (bool) | `{"success": true, ...}` | `{"success": false, "message"/"errors": ...}` | Profile, Rides (most), Bookings (list/accept/reject/cancel), Chat, Notifications, Wallet, Score, password-reset flow (`success`) |
| B — `status` (string) | `{"status": "success", ...}` | `{"status": "error", "message": ...}` | Auth (signup/login/refresh/logout), JWT middleware errors, ride lifecycle (cancel/finish/confirm/no-show/create-with-route), Complaints, Contact |

**Recommended Dart guard:**
```dart
bool isOk(Map<String, dynamic> j) =>
    j['success'] == true || j['status'] == 'success';
```

## 0.3 ⚠️ TWO validation-error (422) shapes exist

| Shape | Payload | Produced by |
|---|---|---|
| Manual `Validator::make` | `{"status":"error"/"success":false, "message": "Validation failed", "errors": {field: [msg,...]}}` (sometimes no `message` key) | Most controllers |
| `$request->validate()` (Laravel default) | `{"message": "<first error>", "errors": {field: [msg,...]}}` — **no `success`/`status` key at all** | `GET/POST /rides/search`, `POST /rides/route-options`, `POST /rides/create-with-route`, `GET /autocomplete`, `POST /notifications/bulk-action`, `POST /bookings/{id}/cancel-seats` |

**Rule for Flutter:** treat any HTTP 422 with an `errors` object as a validation failure. Display the Arabic per-field strings from §0.6, or the generic fallback.

## 0.4 Global authentication errors (all `jwt`-protected endpoints)

Returned by `JwtAuthMiddleware` with **HTTP 401** (except ban = 403):

```json
{ "status": "error", "code": "<CODE>", "message": "<english>" }
```

| `code` | HTTP | Backend message | Arabic string to display | Client action |
|---|---|---|---|---|
| `TOKEN_MISSING` | 401 | Unauthenticated | انتهت الجلسة، يرجى تسجيل الدخول من جديد | Go to login |
| `TOKEN_INVALID` | 401 | Invalid or expired token | — *(silent)* | Try `POST /auth/refresh`; if it fails → login |
| `TOKEN_TYPE_INVALID` | 401 | Invalid token type | انتهت الجلسة، يرجى تسجيل الدخول من جديد | Login |
| `USER_NOT_FOUND` | 401 | User not found | تعذر العثور على الحساب، يرجى تسجيل الدخول من جديد | Logout locally → login |
| `USER_INACTIVE` | 401 | User account is inactive | تم تسجيل الخروج من حسابك، يرجى تسجيل الدخول من جديد | Login |
| `TOKEN_INVALIDATED` | 401 | Your session has been invalidated. Please log in again. | تم إنهاء جلستك (تغيير كلمة المرور أو تسجيل خروج)، يرجى تسجيل الدخول من جديد | Login |
| `USER_BANNED` | **403** | Your account has been banned. You may only use the contact form. | تم حظر حسابك. يمكنك فقط التواصل مع الدعم. | Show ban screen; only `POST /api/contact` + chat with support remain usable |

**Ban payload (403)** includes details:
```json
{
  "status": "error",
  "code": "USER_BANNED",
  "message": "Your account has been banned. You may only use the contact form.",
  "ban": {
    "reason": "سبب الحظر…",
    "type": "temporary | permanent",
    "expires_at": "2026-06-20T10:00:00+03:00"
  }
}
```
Arabic UI: permanent → **«تم حظر حسابك بشكل دائم. السبب: {reason}»** / temporary → **«تم حظر حسابك مؤقتاً حتى {expires_at}. السبب: {reason}»**

## 0.5 Generic server error (500)

Many endpoints return `{"success": false / "status": "error", "message": "<exception text>"}` with HTTP 500. **Never show the raw message.** Always display:
> **حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى لاحقاً**

Network failure / timeout (no response): **«تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت»**

## 0.6 Suggested shared Arabic strings (ARB keys)

| Key | Arabic |
|---|---|
| `errValidation` | يرجى التحقق من البيانات المدخلة |
| `errServer` | حدث خطأ غير متوقع، يرجى المحاولة لاحقاً |
| `errNetwork` | تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت |
| `errSession` | انتهت الجلسة، يرجى تسجيل الدخول من جديد |
| `errEmailRequired` | البريد الإلكتروني مطلوب |
| `errEmailInvalid` | يرجى إدخال بريد إلكتروني صحيح |
| `errPasswordMin` | يجب أن تتكون كلمة المرور من 8 أحرف على الأقل |
| `errPasswordConfirm` | كلمتا المرور غير متطابقتين |
| `errOtp6Digits` | يجب أن يتكون الرمز من 6 أرقام |
| `errPhoneSyrian` | يجب إدخال رقم هاتف سوري صحيح (09XXXXXXXX) |

> Note: the `address` field enum is **already Arabic** in the backend: `دمشق, درعا, القنيطرة, السويداء, ريف دمشق, حمص, حماة, اللاذقية, طرطوس, حلب, ادلب, الحسكة, الرقة, دير الزور` — display as-is.

## 0.7 The `tokens` object (returned by login / email-verify / refresh)

```json
{
  "access_token": "<JWT>",
  "access_token_expires_at": "2026-06-12 14:30:00",
  "refresh_token": "<JWT>",
  "refresh_token_expires_at": "2026-07-12 14:00:00",
  "token_type": "Bearer"
}
```

---

# 1. Authentication

## 1.1 POST `/api/auth/signup`

**Purpose:** Register a new account. Sends a 6-digit email OTP. The account is unusable until email is verified via §3.2.

**Body:** `first_name, last_name, email, password, password_confirmation, gender (M|F), address (Arabic governorate enum)`

### Scenarios

**✅ 201 — New account created**
```json
{
  "status": "success",
  "message": "Registration successful. Check your email for a verification code.",
  "user": { "id": 12, "first_name": "أحمد", "email": "a@b.com" },
  "otp_code": "123456"
}
```
> `otp_code` appears **only when `EMAIL_OTP_MODE=testing`** — never rely on it in production.
> 🇸🇦 Arabic: **«تم إنشاء الحساب بنجاح! أدخل رمز التحقق المرسل إلى بريدك الإلكتروني»** → navigate to OTP screen.

**✅ 200 — Email exists but NOT verified (OTP re-sent, password updated)**
```json
{
  "status": "success",
  "message": "A new verification code has been sent to your email. Your previous code had expired.",
  "user": { "id": 12, "first_name": "أحمد", "email": "a@b.com" }
}
```
> 🇸🇦 **«تم إرسال رمز تحقق جديد إلى بريدك الإلكتروني»** → navigate to OTP screen.

**❌ 409 — Email already registered & verified**
```json
{ "status": "error", "message": "This email address is already registered. Please log in." }
```
> 🇸🇦 **«هذا البريد الإلكتروني مسجل مسبقاً، يرجى تسجيل الدخول»** → offer "Login" button.

**❌ 422 — Validation**
```json
{ "status": "error", "message": "Validation failed", "errors": { "password": ["Password confirmation does not match."] } }
```
> 🇸🇦 Map fields: `first_name`→«الاسم الأول مطلوب», `last_name`→«اسم العائلة مطلوب», `email`→`errEmailInvalid`, `password` confirmed→`errPasswordConfirm`, min→`errPasswordMin`, `gender`→«يرجى اختيار الجنس», `address`→«يرجى اختيار المحافظة».

**❌ 500 — OTP email failed** — message: `Could not send verification email. Please try again.` or `Registration failed: could not send verification email.`
> 🇸🇦 **«تعذر إرسال رمز التحقق إلى بريدك، يرجى المحاولة مرة أخرى»**

**❌ 500 — Generic** — `{"status":"error","message":"Registration failed","error":"..."}` → 🇸🇦 `errServer`.

---

## 1.2 POST `/api/auth/login`

**Purpose:** Email + password login. Sets user status to active and returns token pair.

**Body:** `email, password`

**✅ 200**
```json
{
  "status": "success",
  "message": "Login successful",
  "user": {
    "id": 12,
    "first_name": "أحمد",
    "last_name": "السيد",
    "email": "a@b.com",
    "gender": "M",
    "address": "دمشق",
    "status": 1,
    "is_verified_passenger": false,
    "is_verified_driver": false,
    "verification_status": "none",
    "created_at": "2026-06-01 10:00:00"
  },
  "tokens": { "…see §0.7…" : "" }
}
```
> 🇸🇦 **«تم تسجيل الدخول بنجاح»** (toast, optional).
> ⚠️ Login does **not** check `email_verified_at`. If `user.email_verified_at` flow matters, gate on the signup/verify flow client-side.

**❌ 401 — wrong email OR wrong password (same payload, deliberate)**
```json
{ "status": "error", "message": "Invalid credentials", "code": "INVALID_CREDENTIALS" }
```
> 🇸🇦 **«البريد الإلكتروني أو كلمة المرور غير صحيحة»**

**❌ 422 — Validation** — manual-validator shape (§0.3). 🇸🇦 per-field or `errValidation`.

---

## 1.3 POST `/api/auth/refresh`

**Body:** `refresh_token`

**✅ 200**
```json
{ "status": "success", "message": "Token refreshed successfully", "tokens": { "…§0.7…": "" } }
```
> Silent — no UI message.

**❌ 401**
```json
{ "status": "error", "message": "Invalid or expired refresh token", "code": "REFRESH_TOKEN_INVALID" }
```
> 🇸🇦 `errSession` → force logout + go to login screen.

**❌ 422** — missing `refresh_token` → treat as 401 above.

---

## 1.4 POST `/api/logout` 🔒

**✅ 200**
```json
{ "status": "success", "message": "Successfully logged out" }
```
> 🇸🇦 **«تم تسجيل الخروج بنجاح»**. Revokes **all** refresh tokens and marks the user inactive.

**❌ 401** — `{"status":"error","message":"Unauthenticated"}` → already logged out; clear local state silently.

---

## 1.5 GET `/api/user` 🔒

**✅ 200** — `{"status":"success","user":{ <full user model> }}`
**❌ 401/403** — global (§0.4).

---

# 2. Password Reset (3-step OTP flow)

> All three endpoints use envelope **`success` (bool)**.

## 2.1 POST `/api/auth/password/forgot`

**Body:** `email`

**✅ 200**
```json
{
  "success": true,
  "message": "A 6-digit verification code has been sent to user@x.com. It expires in 10 minutes.",
  "otp_code": "123456"
}
```
> `otp_code` only in testing mode. 🇸🇦 **«تم إرسال رمز مكوّن من 6 أرقام إلى بريدك الإلكتروني، صالح لمدة 10 دقائق»**

**❌ 404** — `No account found with this email address.` → 🇸🇦 **«لا يوجد حساب مسجل بهذا البريد الإلكتروني»**
**❌ 422** — `{"success":false,"message":"Validation failed.","errors":{...}}` → 🇸🇦 `errEmailInvalid`
**❌ 500** — `Failed to send the verification code. Please try again.` → 🇸🇦 **«تعذر إرسال رمز التحقق، يرجى المحاولة مرة أخرى»**

> ⚠️ Rate limit: max 3 OTP requests per 5 minutes per email. The service returns success=false with message `Too many requests. Please wait a few minutes.` (surfaced via the 500 branch). 🇸🇦 **«عدد كبير من المحاولات، يرجى الانتظار بضع دقائق ثم إعادة المحاولة»**

## 2.2 POST `/api/auth/password/verify-otp`

**Body:** `email, otp_code` (exactly 6 digits)

**✅ 200**
```json
{
  "success": true,
  "message": "Code verified. You may now set a new password.",
  "reset_token": "550e8400-e29b-41d4-a716-446655440000",
  "expires_in": 900
}
```
> **Store `reset_token`** — required for step 3. Valid 15 minutes (`expires_in` seconds → show countdown).
> 🇸🇦 **«تم التحقق من الرمز بنجاح، يمكنك الآن تعيين كلمة مرور جديدة»**

**❌ 400** — `{"success":false,"message":"Invalid or expired verification code."}` → 🇸🇦 **«الرمز غير صحيح أو منتهي الصلاحية»**
**❌ 422** — `{"success":false,"errors":{...}}` (no `message` key!). Field messages: `email.exists` = "No account found with this email." → 🇸🇦 **«لا يوجد حساب بهذا البريد»**; `otp_code` size/regex → 🇸🇦 `errOtp6Digits`.

## 2.3 POST `/api/auth/password/reset`

**Body:** `reset_token (uuid), password, password_confirmation`

**✅ 200**
```json
{ "success": true, "message": "Your password has been reset successfully. You can now log in." }
```
> 🇸🇦 **«تم تغيير كلمة المرور بنجاح، يمكنك الآن تسجيل الدخول»** → navigate to login. (All old sessions are revoked server-side.)

**❌ 400** — `This reset link has expired or has already been used. Please request a new code.` → 🇸🇦 **«انتهت صلاحية رمز إعادة التعيين، يرجى طلب رمز جديد»** → restart flow at §2.1
**❌ 404** — `Account not found.` → 🇸🇦 **«تعذر العثور على الحساب»**
**❌ 422** — `{"success":false,"errors":{...}}` → 🇸🇦 `errPasswordMin` / `errPasswordConfirm`.

---

# 3. Email Verification (after signup)

## 3.1 POST `/api/email-verification/send`
**Body:** `email`, optional `type` (`EMAIL_VERIFICATION|PASSWORD_RESET`)

**✅ 200** — service passthrough:
```json
{ "success": true, "message": "Verification code sent to your email.", "expires_at": "2026-06-12 14:40:00" }
```
> Testing mode adds `otp_code` and message `OTP generated (testing mode).`
> 🇸🇦 **«تم إرسال رمز التحقق إلى بريدك الإلكتروني»**

**❌ 400** — `{"success":false,"message":"Too many requests. Please wait a few minutes."}` → 🇸🇦 **«عدد كبير من المحاولات، انتظر بضع دقائق»**, or `Failed to send verification email. Please try again.` → 🇸🇦 **«تعذر إرسال البريد، حاول مجدداً»**
**❌ 422** — Laravel FormRequest default shape `{"message": "...", "errors": {...}}` → 🇸🇦 `errEmailInvalid`.

## 3.2 POST `/api/email-verification/verify`
**Body:** `email, otp_code`

**✅ 200 — verified AND auto-logged-in (tokens returned!)**
```json
{
  "success": true,
  "message": "Email verified. You are now logged in.",
  "user": {
    "id": 12, "first_name": "أحمد", "last_name": "السيد",
    "email": "a@b.com", "email_verified_at": "2026-06-12T11:00:00.000000Z",
    "is_verified_passenger": false, "is_verified_driver": false
  },
  "tokens": { "…§0.7…": "" }
}
```
> 🇸🇦 **«تم تأكيد بريدك الإلكتروني بنجاح! مرحباً بك 🎉»** → store tokens, go straight to home (skip login).

**❌ 400** — `{"success":false,"message":"Invalid or expired verification code."}` → 🇸🇦 **«الرمز غير صحيح أو منتهي الصلاحية»**
**❌ 422** — FormRequest default shape; `email.exists` → 🇸🇦 **«لا يوجد حساب بهذا البريد»**, `otp_code` → `errOtp6Digits`.

## 3.3 POST `/api/email-verification/resend`
**Body:** `email`

**✅ 200** — same as §3.1 success. 🇸🇦 **«تمت إعادة إرسال الرمز»**
**❌ 404** — `No account found with this email.` → 🇸🇦 **«لا يوجد حساب بهذا البريد»**
**❌ 409** — `This email is already verified.` → 🇸🇦 **«هذا البريد مؤكد مسبقاً، يمكنك تسجيل الدخول»**
**❌ 400/422** — as §3.1.

---

# 4. Phone OTP (WhatsApp) — `/api/otp/*` and `/api/textme-otp/*`

> Public endpoints. Same body for both providers: `phone_number`, optional `type` (default `E-PAYMENT`), verify: `phone_number, otp_code`. Responses are raw service arrays: `{success, message, ...}` — HTTP 200 if success, 400 otherwise.

| HTTP | Backend message | Arabic |
|---|---|---|
| 200 | OTP sent successfully via WhatsApp | تم إرسال رمز التحقق عبر واتساب |
| 200 (testing) | OTP generated (testing mode — use the code below) + `otp_code` | — dev only |
| 200 | OTP verified successfully | تم التحقق من الرمز بنجاح |
| 400 | Too many OTP requests. Please try again later. | عدد كبير من المحاولات، حاول لاحقاً |
| 400 | Failed to send OTP. Please try again. | تعذر إرسال الرمز، حاول مجدداً |
| 400 | No API key configured for production OTP sending. | الخدمة غير متاحة حالياً |
| 400 | Invalid or expired OTP | الرمز غير صحيح أو منتهي الصلاحية |
| 400 | OTP has expired or exceeded maximum attempts | انتهت صلاحية الرمز أو تجاوزت عدد المحاولات المسموح |
| 400 | OTP verification failed | فشل التحقق من الرمز |
| 400 | TextMeBot service is currently disabled *(textme-otp only)* | الخدمة غير متاحة حالياً |

---

# 5. Score 🔒

## 5.1 GET `/api/score`
**✅ 200**
```json
{
  "success": true,
  "data": {
    "score": 85, "tier": "gold", "cancel_rate": 3.5,
    "total_rides": 40, "total_cancellations": 2,
    "can_create_rides": true, "can_book_rides": true
  }
}
```
> Business rules: `can_create_rides` = score ≥ 50, `can_book_rides` = score ≥ 40. Use these booleans to disable buttons **before** calling ride APIs.
> 🇸🇦 labels: score=«نقاط الثقة», tier=«المستوى», cancel_rate=«نسبة الإلغاء».

## 5.2 GET `/api/score/history?limit=20` (limit max 50)
**✅ 200** — `data: [ { id, action, points ("+5"/"-10"), previous_score, new_score, reason, high_cancel_rate_applied, reference_type, reference_id, created_at } ]`
> `reason` is English text → display generic Arabic per `action`, or show as-is in a details view.

---

# 6. Profile 🔒

## 6.1 GET `/api/profile/{userId}`

**✅ 200**
```json
{
  "success": true,
  "data": {
    "user_id": 12,
    "full_name": "أحمد السيد",
    "verification_status": "none | pending | approved | rejected",
    "address": "دمشق",
    "gender": "M",
    "profile_photo": "https://host/storage/...jpg | null",
    "description": "…| null",
    "type_of_car": "…| null",
    "color_of_car": "…| null",
    "number_of_seats": 4,
    "car_pic": "https://… | null",
    "radio": true,
    "smoking": false,
    "number_of_rides": 12,
    "documents": { "face_id_pic": "https://…", "back_id_pic": "https://…", "license_pic": "https://…", "mechanic_card_pic": "https://…" },
    "score": { "…same as §5.1…": "" },
    "ride_history": {
      "as_driver":    { "total_created": 5, "completed": 3, "cancelled": 1, "no_show": 1 },
      "as_passenger": { "total_booked": 9, "completed": 7, "cancelled": 2, "no_show": 0 }
    },
    "comments": [ "…" ],
    "rating": { "…avg/count…": "" }
  }
}
```
**❌ 404** — `{"success":false,"message":"Profile not found"}` → 🇸🇦 **«الملف الشخصي غير موجود»**

## 6.2 POST `/api/profile` (update own profile — multipart)

Fields (all optional): `first_name, last_name, description, address, gender, type_of_car, color_of_car, number_of_seats (1-12), radio, smoking` + images `profile_photo, car_pic, face_id_pic, back_id_pic, driving_license_pic, mechanic_card_pic` (jpeg/png/jpg/gif, ≤2MB).

**✅ 200** — `{"success":true,"message":"Profile updated successfully","data":{…same shape as 6.1…}}` → 🇸🇦 **«تم تحديث الملف الشخصي بنجاح»**
**❌ 422** — `{"success":false,"errors":{...}}` → 🇸🇦 image errors: **«يجب أن تكون الصورة بصيغة JPG أو PNG وبحجم أقصى 2 ميغابايت»**
**❌ 500** — raw exception message → 🇸🇦 `errServer`.

## 6.3 POST `/api/profile/{userId}/comments`
**Body:** `comment` (≤500 chars)

**✅ 201** — `{"success":true,"message":"Comment added","data":{…comment…}}` → 🇸🇦 **«تمت إضافة التعليق»**
**❌ 422** — `errors` → 🇸🇦 **«التعليق مطلوب (بحد أقصى 500 حرف)»**
**❌ 4xx/500** — `{"success":false,"message":"<service exception>"}` (HTTP code = exception code or 500) → 🇸🇦 `errServer`.

## 6.4 POST `/api/profile/{userId}/rate`
**Body:** `rating` (numeric 1–5)

**✅ 200** — `{"success":true,"message":"Rating submitted successfully","data":{…rating stats…}}` → 🇸🇦 **«تم إرسال التقييم بنجاح»**
**❌ 422** — → 🇸🇦 **«يرجى اختيار تقييم من 1 إلى 5»**

## 6.5 POST `/api/profile/documents` (upload one document — multipart)
**Body:** `type` (`face_id|back_id|license|mechanic_card`), `file` (image ≤2MB)

**✅ 200**
```json
{ "success": true, "data": { "id": 3, "url": "https://host/storage/documents/x.jpg", "type": "face_id" } }
```
> ⚠️ Uploading a document **resets verification** (`verification_status` → `none`, both verified flags → false). Warn the user: 🇸🇦 **«تم رفع المستند. ملاحظة: سيتطلب حسابك إعادة توثيق»**

**❌ 403** — `Cannot modify documents while verification is pending` → 🇸🇦 **«لا يمكن تعديل المستندات أثناء مراجعة طلب التوثيق»**
**❌ 422** — → 🇸🇦 **«يرجى اختيار نوع المستند وصورة صالحة (JPG/PNG، بحد أقصى 2MB)»**

## 6.6 POST `/api/profile/verify/passenger` (multipart)
**Body (optional):** `face_id_pic, back_id_pic`

**✅ 201** — `{"success":true,"message":"Verification request submitted","status":"pending"}` → 🇸🇦 **«تم إرسال طلب التوثيق، سيتم مراجعته قريباً»**
**❌ 409** — `You already have a pending verification request` → 🇸🇦 **«لديك طلب توثيق قيد المراجعة بالفعل»**
**❌ 422** — image validation → 🇸🇦 as §6.2.

## 6.7 POST `/api/profile/verify/driver` (multipart)
**Body (optional):** `face_id_pic, back_id_pic, driving_license_pic, mechanic_card_pic, car_pic, type_of_car, color_of_car, number_of_seats`

**✅ 201** — `{"success":true,"message":"Driver verification request submitted for review"}` → 🇸🇦 **«تم إرسال طلب توثيق السائق، سيتم مراجعته قريباً»**
**❌ 409 / 422** — same as §6.6.

## 6.8 GET `/api/profile/verify/status/{userId}`

**✅ 200**
```json
{
  "success": true,
  "status": "not_verified | pending | rejected | approved",
  "documents": { "face_id": "https://…", "back_id": "https://…", "license": "https://…", "mechanic_card": "https://…" },
  "vehicle": { "type": "سيدان", "color": "أبيض", "seats": 4, "photo": "https://… | null" },
  "verified": { "passenger": true, "driver": false }
}
```
> 🇸🇦 status labels: `not_verified`=«غير موثّق», `pending`=«قيد المراجعة», `rejected`=«مرفوض», `approved`=«موثّق».

**❌ 500** — `Failed to retrieve verification status: …` → 🇸🇦 `errServer`. (Note: a non-existent userId also lands here as 500, not 404.)

---

# 7. Rides 🔒

> ⚠️ **CRITICAL BACKEND BUG:** `POST /api/rides` is routed to `RideController::createRide`, **a method that does not exist** — calling it always returns Laravel's 500 `BadMethodCallException`. **The Flutter client must create rides via `POST /api/rides/create-with-route` (§7.4) only.**

## 7.1 GET|POST `/api/rides/search`

**Params:** `source_address` *or* (`source_lat`+`source_lng`), `destination_address` *or* (`dest_lat`+`dest_lng`), `departure_date` (date, today or later), `seats_required` (int ≥1).

**✅ 200** — `{"success": true, "data": [ <ride objects from search service> ]}` (raw service output; ride fields ≈ §7.5 RideResource minus the wrapper). Empty array = no results → 🇸🇦 **«لا توجد رحلات متاحة تطابق بحثك»**
**❌ 422** — **Laravel default shape** (§0.3) → 🇸🇦 `errValidation`; `departure_date.after` → **«يرجى اختيار تاريخ اليوم أو تاريخ لاحق»**
**❌ 500** — `Search failed: <geocoding/service error>` → 🇸🇦 **«فشل البحث، يرجى المحاولة مرة أخرى»**

## 7.2 POST `/api/rides/route-options`

**Body:** `pickup_lat, pickup_lng, destination_lat, destination_lng`

**✅ 200**
```json
{
  "success": true,
  "data": {
    "routes": [ { "geometry": "...", "distance": 12000, "duration": 900, "...": "..." } ],
    "pickup": { "lat": 33.5, "lng": 36.3 },
    "destination": { "lat": 33.6, "lng": 36.4 }
  }
}
```
> Up to 3 alternative routes. User picks one → pass its data to §7.4.

**❌ 422** — Laravel default shape → 🇸🇦 `errValidation`
**❌ 500** — `Failed to get route options: …` → 🇸🇦 **«تعذر حساب المسار، حاول مجدداً»**

## 7.3 GET `/api/autocomplete?text=<query>` (min 2 chars)

**✅ 200** — `{"success":true,"data":[ <place suggestions> ]}`
**❌ 422** — Laravel default → ignore (don't search under 2 chars client-side).
**❌ 500** — `{"success":false,"message":"…"}` → silent fail (keep last suggestions).

## 7.4 POST `/api/rides/create-with-route` ← **the ride-creation endpoint**

**Body:**
```
pickup_lat, pickup_lng, destination_lat, destination_lng   (required)
pickup_address, destination_address                        (optional — reverse-geocoded if omitted)
departure_time   (required, ≥ now+5min, Damascus time)
available_seats  (1–8), price_per_seat (≥0)
vehicle_type, payment_method (cash|e-pay), booking_type (direct|request)
communication_number (required), notes
route_geometry {type: LineString, coordinates[]}, route_index, distance, duration  (optional — recalculated if omitted)
```

**✅ 201**
```json
{ "status": "success", "message": "Ride created successfully", "ride": { "…raw Ride model…": "" } }
```
> ⚠️ Returns the **raw model**, NOT RideResource — fields are flat (`pickup_address`, `departure_time`, `available_seats`, …).
> 🇸🇦 **«تم إنشاء الرحلة بنجاح 🎉»**

**❌ 422 — business rules** (`{"status":"error","message": "<msg>"}`) — exact messages → Arabic:

| Backend message | Arabic |
|---|---|
| You must be verified as a driver to create rides | يجب توثيق حسابك كسائق قبل إنشاء الرحلات |
| Driver profile not found. Please complete your profile. | يرجى إكمال ملفك الشخصي أولاً |
| Your trust score (N) is too low to create rides. Minimum required: 50. … | نقاط الثقة لديك غير كافية لإنشاء رحلات (الحد الأدنى 50) |
| Departure time must be at least 5 minutes in the future. … | يجب أن يكون موعد الانطلاق بعد 5 دقائق على الأقل من الآن |
| Departure time cannot be more than 30 days in the future | لا يمكن جدولة رحلة بعد أكثر من 30 يوماً |

**❌ 422 — field validation** — Laravel default shape (§0.3) → 🇸🇦 `communication_number.regex` → `errPhoneSyrian`; `price_per_seat` → «يرجى إدخال سعر صحيح»; otherwise `errValidation`.
**❌ 500** — raw message → 🇸🇦 `errServer`.

## 7.5 GET `/api/rides/{rideId}` — ride details (RideResource)

**✅ 200**
```json
{
  "success": true,
  "data": {
    "id": 7,
    "driver": { "id": 3, "name": "أحمد السيد", "avatar": "https://…|null", "rating": 4.5 },
    "pickup":      { "address": "دمشق، المزة", "coordinates": { "lat": 33.5, "lng": 36.27 } },
    "destination": { "address": "حمص",        "coordinates": { "lat": 34.73, "lng": 36.71 } },
    "departure_time": "2026-06-13T08:00:00+03:00",
    "departure_time_human": "Jun 13, 2026 at 8:00 AM",
    "seats": { "available": 2, "booked": 2, "total": 4 },
    "price_per_seat": 50000,
    "status": "active | full | started | awaiting_confirmation | finished | cancelled",
    "distance": { "meters": 162000, "kilometers": 162.0 },
    "duration": { "seconds": 7200, "minutes": 120, "human": "2h 0m" },
    "vehicle_type": "سيدان",
    "payment_method": "cash",
    "booking_type": "direct",
    "communication_number": "0991234567",
    "notes": "…|null",
    "route": { "index": 0, "geometry": { "type": "LineString", "coordinates": [] } },
    "created_at": "…", "updated_at": "…"
  }
}
```
> ⚠️ `departure_time_human` is **English-formatted** — format `departure_time` yourself with `intl` + `ar` locale instead.

**❌ 404** — `Ride not found: …` → 🇸🇦 **«الرحلة غير موجودة»**

## 7.6 GET `/api/rides` — my rides as driver

**✅ 200** — `{"success":true,"data":[ <rides from service, raw shape> ]}`. Empty → 🇸🇦 **«لم تقم بإنشاء أي رحلات بعد»**
**❌ 500** — `Failed to fetch rides: …` → 🇸🇦 `errServer`.

## 7.7 PATCH `/api/rides/{rideId}/cancel`

**✅ 200** — `{"status":"success","message":"Ride cancelled successfully.","ride":{…raw model…}}` → 🇸🇦 **«تم إلغاء الرحلة، وسيتم إعادة المبالغ للركاب المحجوزين»**
**❌ 422** — messages → Arabic:

| Backend message | Arabic |
|---|---|
| Only the ride creator can cancel it | لا يمكنك إلغاء رحلة لم تقم بإنشائها |
| Cannot cancel a ride with status: {label} | لا يمكن إلغاء الرحلة في حالتها الحالية |
| Cannot cancel ride less than 1 hour before departure time | لا يمكن إلغاء الرحلة قبل أقل من ساعة من موعد الانطلاق |

**❌ 500** — → 🇸🇦 `errServer`.

## 7.8 POST `/api/rides/{rideId}/book`

**Body:** `seats (1–8), communication_number (09XXXXXXXX), idempotency_key (uuid — generate one per booking attempt and reuse on retry)`

**✅ 201** — `{"success":true,"data":{…BookingResource, see §8.0…},"message":"Ride booked successfully"}`
> 🇸🇦 direct booking: **«تم حجز مقعدك بنجاح 🎉»** / request booking (`booking_type=request`): **«تم إرسال طلب الحجز، بانتظار موافقة السائق»** (check `data.status`: `confirmed` vs `pending`).

**❌ 422 — ALL errors** (validation messages or business exceptions, `{"success":false,"message":"…"}`):

| Backend message | Arabic |
|---|---|
| You must be verified as a passenger to book rides | يجب توثيق حسابك كراكب قبل حجز الرحلات |
| Your trust score (N) is too low to book rides. Minimum required: 40. | نقاط الثقة لديك غير كافية لحجز الرحلات (الحد الأدنى 40) |
| Drivers cannot book their own rides | لا يمكنك حجز مقعد في رحلتك الخاصة |
| You already have an active booking for this ride | لديك حجز فعّال في هذه الرحلة بالفعل |
| Must request at least 1 seat | يجب حجز مقعد واحد على الأقل |
| Cannot request more than 8 seats per booking | لا يمكن حجز أكثر من 8 مقاعد |
| Not enough seats available. Requested: N, Available: M | عدد المقاعد المتاحة غير كافٍ |
| Communication number must be a valid Syrian mobile number (09XXXXXXXX) | errPhoneSyrian |
| *(insufficient wallet balance — e-pay rides; message varies)* | رصيد محفظتك غير كافٍ لإتمام الحجز |
| *(anything else)* | تعذر إتمام الحجز: حاول مجدداً |

## 7.9 POST `/api/rides/{rideId}/finish` (driver)

**✅ 200**
```json
{
  "status": "success",
  "message": "<service message>",
  "data": { "ride_status": "awaiting_confirmation | finished", "requires_confirmation": true }
}
```
> 🇸🇦 if `requires_confirmation=true`: **«تم إنهاء الرحلة، بانتظار تأكيد الركاب»**, else **«تم إنهاء الرحلة بنجاح»**

**❌ 400** — messages → Arabic: `Only the ride driver can finish it` → «هذا الإجراء متاح لسائق الرحلة فقط», `Can only finish an active or full ride (current: …)` → «لا يمكن إنهاء الرحلة في حالتها الحالية», `Cannot finish a ride before its departure time` → «لا يمكن إنهاء الرحلة قبل موعد انطلاقها».

## 7.10 POST `/api/rides/{rideId}/driver-confirm`

**✅ 200** — `{"status":"success","message":"…"}` → 🇸🇦 **«تم تأكيد إتمام الرحلة»**
**❌ 400** — `Only the ride driver can confirm completion` → «متاح للسائق فقط», `Ride is not awaiting confirmation` → «الرحلة ليست بانتظار التأكيد», `Driver has already confirmed this ride` → «قمت بتأكيد هذه الرحلة مسبقاً».

## 7.11 POST `/api/rides/{rideId}/driver-no-show` (passenger reports driver)

**✅ 200** — `{"status":"success","message":"…"}` → 🇸🇦 **«تم الإبلاغ عن عدم حضور السائق، وسيتم إعادة المبلغ المدفوع»**
**❌ 422** — `Cannot report a no-show before the departure time` → «لا يمكن الإبلاغ قبل موعد الانطلاق», `No confirmed booking found for you on this ride` → «لا يوجد لديك حجز مؤكد في هذه الرحلة».

---

# 8. Bookings 🔒

### §8.0 BookingResource shape (used by most booking responses)
```json
{
  "id": 5, "ride_id": 7,
  "status": "pending | confirmed | cancelled | completed | no_show",
  "seats": 2,
  "communication_number": "0991234567",
  "passenger": { "id": 9, "name": "سارة محمد", "avatar": "https://…|null", "rating": 4.8 },
  "ride": {
    "id": 7, "pickup_address": "دمشق", "destination_address": "حمص",
    "departure_time": "2026-06-13T08:00:00+03:00",
    "price_per_seat": 50000, "payment_method": "cash", "vehicle_type": "سيدان",
    "driver": { "id": 3, "name": "أحمد السيد", "avatar": null, "communication_number": "0997654321" }
  },
  "total_price": 100000,
  "created_at": "…", "updated_at": "…",
  "completed_at": null, "passenger_confirmed_at": null
}
```
> 🇸🇦 status labels: `pending`=«بانتظار الموافقة», `confirmed`=«مؤكد», `cancelled`=«ملغي», `completed`=«مكتمل», `no_show`=«لم يحضر».

## 8.1 GET `/api/bookings` — my bookings (passenger)
**✅ 200** — `{"success":true,"data":[ §8.0… ]}`. Empty → 🇸🇦 **«لا توجد حجوزات بعد»**

## 8.2 POST `/api/bookings/{bookingId}/accept` (driver, request-type rides)
**✅ 200** — `{"success":true,"data":{§8.0},"message":"Booking accepted successfully"}` → 🇸🇦 **«تم قبول طلب الحجز»**
**❌ 422** — `Only the ride driver can accept bookings` → «متاح لسائق الرحلة فقط», `Only request-type bookings can be accepted` → «هذا الحجز لا يتطلب موافقة», `Only pending bookings can be accepted` → «لا يمكن قبول هذا الحجز في حالته الحالية».

## 8.3 POST `/api/bookings/{bookingId}/reject` (driver)
**✅ 200** — `…"message":"Booking rejected successfully"` → 🇸🇦 **«تم رفض طلب الحجز»**
**❌ 422** — mirror of §8.2 with "reject" → same Arabic with «رفض».

## 8.4 POST `/api/bookings/{bookingId}/cancel` (passenger)
**✅ 200** — `…"message":"Booking cancelled successfully"` → 🇸🇦 **«تم إلغاء الحجز»** (+ refund if e-pay: **«وتمت إعادة المبلغ إلى محفظتك»**)
**❌ 422** — `You can only cancel your own bookings` → «لا يمكنك إلغاء حجز لا يخصك», `Cannot cancel booking less than 2 hours before departure time` → «لا يمكن إلغاء الحجز قبل أقل من ساعتين من موعد الانطلاق».

## 8.5 POST `/api/bookings/{bookingId}/cancel-seats`
**Body:** `seats_to_cancel (int ≥1)`

**✅ 200** — `{"status":"success","message":"…","data":{…}}` → 🇸🇦 **«تم إلغاء {n} مقعد/مقاعد من حجزك»**
**❌ 422** — Laravel default shape for `seats_to_cancel` errors, or `{"status":"error","message":…}`: `You can only cancel your own bookings` → «لا يمكنك تعديل حجز لا يخصك», `This booking cannot be partially cancelled` → «لا يمكن الإلغاء الجزئي لهذا الحجز».
**❌ 400** — other exceptions → 🇸🇦 `errServer`.

## 8.6 POST `/api/bookings/{bookingId}/passenger-confirm`
**✅ 200** — `{"status":"success","message":"…"}` → 🇸🇦 **«شكراً لتأكيدك إتمام الرحلة»**
**❌ 400** — `Only the booking passenger can confirm completion` → «متاح لصاحب الحجز فقط», `Ride is not awaiting confirmation` → «الرحلة ليست بانتظار التأكيد», `Only confirmed bookings can be confirmed for completion` → «لا يمكن تأكيد هذا الحجز», `You have already confirmed this ride` → «قمت بالتأكيد مسبقاً».

## 8.7 POST `/api/bookings/{bookingId}/passenger-no-show` (driver reports passenger)
**✅ 200** — `{"status":"success","message":"…"}` → 🇸🇦 **«تم الإبلاغ عن عدم حضور الراكب»**
**❌ 422** — `Only the ride driver can report a passenger no-show` → «متاح لسائق الرحلة فقط», `Can only report no-show for confirmed bookings` → «الحجز غير مؤكد», `Cannot report a no-show before the departure time` → «لا يمكن الإبلاغ قبل موعد الانطلاق».

---

# 9. Chat 🔒

## 9.1 GET `/api/chat/conversations`
**✅ 200**
```json
{
  "success": true,
  "data": [{
    "id": 1, "type": "private", "title": null,
    "other_participant": { "id": 3, "name": "أحمد السيد", "profile_photo": "https://…|null" },
    "last_message": { "content": "مرحبا | https://…(if image)", "sender_name": "أحمد", "created_at": "5 minutes ago" },
    "updated_at": "2026-06-12T11:00:00+03:00"
  }]
}
```
> ⚠️ `last_message.created_at` is English `diffForHumans()` — recompute relative time client-side in Arabic.

**❌ 500** — `Failed to fetch conversations: …` → 🇸🇦 `errServer`.

## 9.2 POST `/api/chat/conversations`
**Body:** `user_id` (must exist, ≠ self)

**✅ 200** — exists: `{"success":true,"data":{"conversation_id":1,"message":"Conversation already exists"}}`
**✅ 201** — created: `…"message":"Conversation created successfully"`
> Both: open the chat screen silently.

**❌ 422** — `errors.user_id` → 🇸🇦 **«تعذر بدء المحادثة»**
**❌ 500** — `Failed to create conversation: …` → 🇸🇦 `errServer`.

## 9.3 GET `/api/chat/conversations/{id}/messages?page=1` (50 per page)
**✅ 200**
```json
{
  "success": true,
  "data": [{
    "id": 10,
    "sender": { "id": 3, "name": "أحمد السيد", "profile_photo": "https://…|null" },
    "type": "text | image",
    "content": "نص الرسالة أو https://…/storage/chat/img.jpg",
    "metadata": { "caption": "" },
    "created_at": "2026-06-12T11:00:00+03:00",
    "is_edited": false
  }]
}
```
**❌ 404** — `Conversation not found or access denied` → 🇸🇦 **«المحادثة غير موجودة»**

## 9.4 POST `/api/chat/conversations/{id}/messages`
**Body (text):** `{"type":"text","content":"…"}` — **Body (image, multipart):** `type=image, image=<file>, caption?`

**✅ 201** — `{"success":true,"data":{…message object as §9.3…}}` (also broadcast over websockets).
**❌ HttpException passthrough** (`{"success":false,"message":…}` with the exception's HTTP code):

| HTTP | Backend message | Arabic |
|---|---|---|
| 404 | Conversation not found | المحادثة غير موجودة |
| 403 | You are not a participant of this conversation | لا يمكنك إرسال رسائل في هذه المحادثة |
| 422 | Invalid message type | نوع الرسالة غير مدعوم |
| 422 | Invalid message data | محتوى الرسالة غير صالح |
| 422 | Invalid image file | الصورة غير صالحة |
| 500 | Failed to send message: … | تعذر إرسال الرسالة، حاول مجدداً |

## 9.5 DELETE `/api/chat/messages/{messageId}`
**✅ 200** — `{"success":true,"message":"Message deleted successfully"}` → 🇸🇦 **«تم حذف الرسالة»**
**❌ 404** — `Message not found or permission denied` → 🇸🇦 **«تعذر حذف الرسالة»**

---

# 10. Notifications 🔒

## 10.1 GET `/api/notifications?category=&type=&priority=&is_read=&per_page=15`
**✅ 200** — `data` is a **Laravel paginator object**:
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [ { "id": 1, "user_id": 12, "title": "…", "message": "…", "category": "ride", "type": "…", "priority": "…", "is_read": false, "created_at": "…", "…": "…" } ],
    "last_page": 3, "per_page": 15, "total": 40, "next_page_url": "…|null"
  },
  "unread_count": 5
}
```
> Notification `title`/`message` content language depends on what the backend `NotificationService` writes — display as-is.

## 10.2 GET `/api/notifications/unread-count`
**✅ 200** — `{"success":true,"unread_count":5}`

## 10.3 GET `/api/notifications/categories`
**✅ 200** — `{"success":true,"data":{"general":"General","ride":"Rides","chat":"Messages","profile":"Profile","system":"System"}}`
> ⚠️ Labels are English — use your own Arabic map: general=«عام», ride=«الرحلات», chat=«الرسائل», profile=«الملف الشخصي», system=«النظام». Use only the **keys** from the API.

## 10.4 POST `/api/notifications/read-all`
**✅ 200** — `{"success":true,"message":"All notifications marked as read","unread_count":0}` → 🇸🦦 **«تم تحديد الكل كمقروء»**

## 10.5 POST `/api/notifications/{id}/read` · `/{id}/unread` · DELETE `/api/notifications/{id}`
**✅ 200** — `{"success":true,"message":"Notification marked as read|unread / Notification deleted","data":{…}}` → silent / 🇸🇦 **«تم حذف الإشعار»**
**❌ 404** — `{"success":false,"message":"Notification not found"}` (also returned when it belongs to another user) → refresh list silently.

## 10.6 POST `/api/notifications/bulk-action`
**Body:** `{"action":"mark_read|mark_unread|delete","notification_ids":[1,2]}`
**✅ 200** — `{"success":true,"message":"…","unread_count":N}`
**❌ 404** — `No notifications found` → refresh silently.
**❌ 422** — Laravel default shape → `errValidation`.

---

# 11. Wallet 🔒

## 11.1 GET `/api/wallet/balance`
**✅ 200** — `{"success":true,"wallet_number":"W-000123","balance":"150000.00"}`
> 🇸🇦 display: **«رصيدك: {balance} ل.س»**

**❌ 404** — `Wallet not found for this user` → 🇸🇦 **«لا تملك محفظة بعد، أنشئ واحدة الآن»** → show create-wallet CTA.

## 11.2 POST `/api/wallet/initiate` (step 1 — sends WhatsApp OTP)
**Body:** `phone_number (unique), password (account password)`

**✅ 200** — `{"success":true,"message":"OTP sent successfully. …","phone_number":"09…", ["otp_code"]}` → 🇸🇦 **«تم إرسال رمز التحقق إلى رقمك عبر واتساب»**
**❌ 401** — `Invalid password` → 🇸🇦 **«كلمة المرور غير صحيحة»**
**❌ 409** — `Wallet already exists for this user` → 🇸🇦 **«لديك محفظة بالفعل»**
**❌ 422** — `phone_number` unique fails → 🇸🇦 **«هذا الرقم مستخدم في محفظة أخرى»**; required → `errPhoneSyrian`
**❌ 400** — OTP service failure (see §4 table) → matching Arabic.

## 11.3 POST `/api/wallet/verify-and-create` (step 2)
**Body:** `phone_number, otp_code`

**✅ 201** — `{"success":true,"message":"Wallet created successfully","wallet_number":"W-000123","phone_number":"09…"}` → 🇸🇦 **«تم إنشاء محفظتك بنجاح 🎉»**
**❌ 409** — `Wallet already exists for this user` → «لديك محفظة بالفعل»
**❌ 400** — `Invalid or expired OTP` / `OTP has expired or exceeded maximum attempts` → §4 Arabic.
**❌ 422** — `errValidation`.

## 11.4 GET `/api/wallet/requests`
**✅ 200**
```json
{
  "success": true,
  "data": [{
    "id": 1, "type": "charge | withdraw", "amount": 50000.0,
    "status": "pending | approved | rejected",
    "user_notes": "…|null", "admin_notes": "…|null",
    "processed_at": "…|null", "created_at": "…"
  }]
}
```
> 🇸🇦 type: charge=«شحن», withdraw=«سحب». status: pending=«قيد المراجعة», approved=«مقبول», rejected=«مرفوض».

## 11.5 POST `/api/wallet/request-charge`
**Body:** `amount (1 – 10,000,000), notes?`

**✅ 201** — `{"success":true,"message":"Charge request submitted. The admin will review it shortly.","data":{…§11.4 item…}}` → 🇸🇦 **«تم إرسال طلب الشحن، سيقوم المسؤول بمراجعته قريباً»**
**❌ 422** — `You do not have a wallet yet. Please create one first.` → «أنشئ محفظة أولاً» / amount errors → «يرجى إدخال مبلغ صحيح»
**❌ 409** — `You already have a pending charge request. …` → 🇸🇦 **«لديك طلب شحن قيد المراجعة بالفعل»**

## 11.6 POST `/api/wallet/request-withdraw`
**Body:** `amount (≥1), notes?`

**✅ 201** — `…"message":"Withdraw request submitted. …"` → 🇸🇦 **«تم إرسال طلب السحب، سيقوم المسؤول بمعالجته قريباً»**
**❌ 422** — `You do not have a wallet yet.` → «أنشئ محفظة أولاً» / `Insufficient balance. Your current balance is N SYP.` → 🇸🇦 **«الرصيد غير كافٍ (رصيدك الحالي: {N} ل.س)»** / `You already have pending withdraw requests totalling N SYP. This request would exceed your balance.` → 🇸🇦 **«لديك طلبات سحب معلقة بقيمة {N} ل.س، هذا الطلب يتجاوز رصيدك»**

---

# 12. Complaints 🔒 (envelope B — `status`)

## 12.1 POST `/api/complaints` (multipart if attachments)
**Body:** `title (≤255), description (≤2000), type (trip_safety|driver_behavior|passenger_behavior|ride_cancellation|financial_issue|account_issue|technical_issue|other), attachments[] (≤3 files, jpeg/jpg/png/pdf, ≤5MB each)`

**✅ 201**
```json
{ "status": "success", "message": "Complaint submitted successfully.", "complaint": { "…see §12.2 item…": "" } }
```
> 🇸🇦 **«تم إرسال الشكوى بنجاح، سيتم التواصل معك قريباً»**

**❌ 422** — `{"status":"error","errors":{…}}` → 🇸🇦 title=«عنوان الشكوى مطلوب», description=«وصف الشكوى مطلوب», type=«يرجى اختيار نوع الشكوى», attachments=«المرفقات: حتى 3 ملفات (صورة أو PDF) بحجم أقصى 5MB لكل ملف».

> 🇸🇦 complaint type labels: trip_safety=«سلامة الرحلة», driver_behavior=«سلوك السائق», passenger_behavior=«سلوك الراكب», ride_cancellation=«إلغاء رحلة», financial_issue=«مشكلة مالية», account_issue=«مشكلة في الحساب», technical_issue=«مشكلة تقنية», other=«أخرى».

## 12.2 GET `/api/complaints`
**✅ 200**
```json
{
  "status": "success",
  "data": [{
    "id": 1, "title": "…", "description": "…",
    "type": "driver_behavior", "type_label": "سلوك السائق",
    "status": "pending | in_review | escalated | resolved | closed",
    "status_label": "Pending", "status_color": "yellow",
    "resolution_notes": "…|null",
    "assigned_to": { "name": "…" },
    "attachments": [{ "id": 1, "url": "https://…", "original_name": "x.jpg", "mime_type": "image/jpeg", "size_kb": 240.5 }],
    "resolved_at": "…|null", "submitted_at": "…"
  }]
}
```
> ✅ `type_label` is **already Arabic** (backend enum). ⚠️ `status_label` is English — map the `status` key yourself: pending=«قيد الانتظار», in_review=«قيد المراجعة», escalated=«مُصعّدة للإدارة», resolved=«تم الحل», closed=«مغلقة». Full detail: see `docs/API_SPEC_SUPPORT_COMPLAINTS_AR.md`.

## 12.3 GET `/api/complaints/{id}`
**✅ 200** — `{"status":"success","data":{…item…}}`
**❌ 404** — `{"status":"error","message":"Complaint not found."}` → 🇸🇦 **«الشكوى غير موجودة»**

---

# 13. Contact Support 🔒 — POST `/api/contact`

> The **only** endpoint usable by banned users (besides chat with the support conversation).

**✅ 200** — existing chat: `{"status":"success","conversation_id":1,"message":"Support chat ready.","agent":{"name":"…"}}`
**✅ 201** — new chat: `…"message":"Support chat started."`
> Both → open chat screen with `conversation_id`. 🇸🇦 optional toast: **«تم فتح محادثة مع فريق الدعم»**

**❌ 503** — `No support agents are available at the moment.` / `Support is currently unavailable.` → 🇸🇦 **«الدعم غير متاح حالياً، يرجى المحاولة لاحقاً»**
**❌ 422** — `Cannot open support chat.` → 🇸🇦 **«تعذر فتح محادثة الدعم»**

---

# 14. Backend quirks the Flutter client MUST handle

1. **`POST /api/rides` is broken** (missing controller method → always 500). Create rides exclusively with `POST /api/rides/create-with-route`.
2. **Two envelopes** (`success` bool vs `status` string) and **two 422 shapes** — see §0.2/§0.3. Build one tolerant parser.
3. **`otp_code` leaks in responses when the backend runs in testing mode** (signup, forgot-password, wallet initiate, email send). Ignore it in release builds.
4. **Human-readable strings are English** (`departure_time_human`, chat `created_at` diffForHumans, notification category labels, complaint labels) — always format raw ISO values/keys client-side with the `ar` locale.
5. **401 handling:** only attempt refresh on `TOKEN_INVALID`/`TOKEN_MISSING`; on `REFRESH_TOKEN_INVALID`, `TOKEN_INVALIDATED`, `USER_INACTIVE` → hard logout.
6. **403 `USER_BANNED`** can arrive on *any* protected call — intercept globally and route to the ban screen.
7. Ride/booking business errors arrive as **422 or 400 with a raw English sentence** — match the exact strings in §7/§8 tables; unknown string → generic Arabic fallback.
8. Wallet `balance` may be a **string** (decimal cast) — parse with `double.parse`.
9. Score gates: hide/disable "create ride" when `score < 50` and "book" when `score < 40` using §5.1 to avoid round-trip errors.
10. All timestamps are ISO-8601 with timezone (mostly `+03:00` Damascus); business rules (departure ≥ now+5min) are evaluated in **Damascus time** server-side.
