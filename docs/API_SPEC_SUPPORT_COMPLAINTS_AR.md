# API Specification — Technical Support & Complaints Module (الدعم الفني والشكاوى)

> **Audience:** Flutter-side AI building Models / Repositories / Cubits for this module.
> **Backend source of truth:** `ComplaintController`, `ContactController`, `ComplaintService`, `ChatMessageHandler`, enums `ComplaintType` & `ComplaintStatus`.
> **Auth:** All endpoints require `Authorization: Bearer <access_token>` (JWT middleware). Global 401/403 behavior is in the companion doc `API_RESPONSE_SPEC_AR.md` §0.4 and applies to every endpoint here — not repeated per endpoint.
> **Envelope:** This module uses **`{"status": "success" | "error"}`** (string envelope), *not* the `success` boolean used elsewhere.

---

## Module architecture (read this first)

The module has **two pillars**:

1. **Complaints (الشكاوى)** — ticket-style, asynchronous. User submits a complaint with optional attachments → it is auto-assigned to the first active support agent → agent responds/escalates → user polls status via list/detail endpoints. **There is no user-side "reply to complaint" endpoint** — a complaint is write-once; follow-up happens via support chat.
2. **Contact Support (التواصل مع الدعم)** — synchronous live chat. `POST /api/contact` finds/creates a private **chat conversation** with a support agent, then the standard chat endpoints (§5) carry the actual messages.

**Special rule for banned users:** a banned account (403 `USER_BANNED` on everything else) is **still allowed** to call `POST /api/contact` — this is the designed appeal channel. The ban screen in Flutter must expose a "تواصل مع الدعم" button wired to this endpoint.

### Localization ground truth for this module

| Source | Language | Flutter action |
|---|---|---|
| `type_label` field | ✅ **Already Arabic** (backend enum `ComplaintType::label()`) | Safe to display as-is, or use your own map keyed on `type` (recommended for consistency) |
| `status_label` field | ❌ English (`Pending`, `In Review`…) | Ignore; map the `status` key → Arabic (table below) |
| `message` fields | ❌ English, hardcoded | Never display; map scenario → ARB key |
| `title`, `description`, `resolution_notes` | User/agent-generated content | Display as-is (will naturally be Arabic) |

### Enum: `type` (ComplaintType)

| `type` value | Backend `type_label` (Arabic ✅) | Suggested ARB key |
|---|---|---|
| `trip_safety` | أمان الرحلة | `complaintTypeTripSafety` |
| `driver_behavior` | سلوك السائق | `complaintTypeDriverBehavior` |
| `passenger_behavior` | سلوك الراكب | `complaintTypePassengerBehavior` |
| `ride_cancellation` | إلغاء الرحلة | `complaintTypeRideCancellation` |
| `financial_issue` | مشكلة مالية | `complaintTypeFinancialIssue` |
| `account_issue` | مشكلة في الحساب | `complaintTypeAccountIssue` |
| `technical_issue` | عطل تقني | `complaintTypeTechnicalIssue` |
| `other` | أخرى | `complaintTypeOther` |

### Enum: `status` (ComplaintStatus)

| `status` value | Backend `status_label` (EN) | `status_color` | Arabic to display | Suggested ARB key |
|---|---|---|---|---|
| `pending` | Pending | `yellow` | قيد الانتظار | `complaintStatusPending` |
| `in_review` | In Review | `blue` | قيد المراجعة | `complaintStatusInReview` |
| `escalated` | Escalated | `orange` | مُصعّدة للإدارة | `complaintStatusEscalated` |
| `resolved` | Resolved | `green` | تم الحل | `complaintStatusResolved` |
| `closed` | Closed | `gray` | مغلقة | `complaintStatusClosed` |

> `status_color` is a plain color word (`yellow|blue|orange|green|gray`) — map to your theme colors; don't parse as hex.
> "Open" states (show as active in UI): `pending`, `in_review`, `escalated`. Terminal states: `resolved`, `closed`.

### The Complaint object (returned by all complaint endpoints)

```json
{
  "id": 14,
  "title": "السائق تأخر ساعة كاملة",
  "description": "تفاصيل الشكوى …",
  "type": "driver_behavior",
  "type_label": "سلوك السائق",
  "status": "pending",
  "status_label": "Pending",
  "status_color": "yellow",
  "resolution_notes": null,
  "assigned_to": { "name": "Sara Support" },
  "attachments": [
    {
      "id": 3,
      "url": "https://host/storage/complaints/14/img.jpg",
      "original_name": "screenshot.jpg",
      "mime_type": "image/jpeg",
      "size_kb": 240.5
    }
  ],
  "resolved_at": null,
  "submitted_at": "2026-06-12T11:30:00+03:00"
}
```

Field notes for the Dart model:
- `resolution_notes`: `String?` — the agent's answer, present once resolved (agent-written, usually Arabic). Show under «رد فريق الدعم».
- `assigned_to`: `{name}?` — **nullable** (null when no active support agent existed at submission time).
- `attachments`: always an array (may be empty). `size_kb` is a `double`.
- `resolved_at`: `String?` ISO-8601. `submitted_at`: ISO-8601 with `+03:00` — format with `intl` + `ar` locale.

---

# 1. POST `/api/complaints` — Submit a complaint

**Purpose:** Create a new complaint ticket, optionally with up to 3 attachments. Auto-assigned to a support agent. Initial status is always `pending`.

**Request:** `multipart/form-data` when sending attachments, otherwise JSON.

| Field | Type | Rules |
|---|---|---|
| `title` | string | required, max 255 |
| `description` | string | required, max 2000 |
| `type` | string | required, one of the 8 enum values above |
| `attachments[]` | file[] | optional, **max 3 files**, each: jpeg/jpg/png/**pdf**, **max 5 MB** |

### ✅ Scenario: Created — HTTP 201

```json
{
  "status": "success",
  "message": "Complaint submitted successfully.",
  "complaint": { "…full Complaint object (status=pending)…": "" }
}
```
- 🇸🇦 Display: **«تم إرسال شكواك بنجاح، سيقوم فريق الدعم بمراجعتها قريباً»**
- ARB: `complaintSubmitSuccess`
- Note the root key is **`complaint`** (singular), unlike the list/detail endpoints which use `data`.

### ❌ Scenario: Validation Error — HTTP 422

```json
{
  "status": "error",
  "errors": {
    "title": ["The title field is required."],
    "description": ["The description field is required."],
    "type": ["The selected type is invalid."],
    "attachments": ["The attachments may not have more than 3 items."],
    "attachments.0": ["The attachments.0 must be a file of type: jpeg, jpg, png, pdf."]
  }
}
```
> ⚠️ No `message` key — only `errors`. Keys for individual files are `attachments.0`, `attachments.1`, `attachments.2`.

| `errors` key | Arabic string | ARB key |
|---|---|---|
| `title` | يرجى إدخال عنوان الشكوى (بحد أقصى 255 حرفاً) | `complaintErrTitle` |
| `description` | يرجى كتابة وصف الشكوى (بحد أقصى 2000 حرف) | `complaintErrDescription` |
| `type` | يرجى اختيار نوع الشكوى | `complaintErrType` |
| `attachments` | يمكن إرفاق 3 ملفات كحد أقصى | `complaintErrAttachmentsMax` |
| `attachments.N` | يجب أن يكون المرفق صورة (JPG/PNG) أو ملف PDF بحجم لا يتجاوز 5 ميغابايت | `complaintErrAttachmentInvalid` |

> 💡 Validate client-side before upload (count ≤ 3, size ≤ 5 MB, extension) to avoid wasted multipart uploads.

### ❌ Scenario: Unauthenticated / Banned — HTTP 401 / 403
Global behavior (companion doc §0.4). Note: **banned users cannot submit complaints** — only `POST /api/contact`. On 403 `USER_BANNED` route them to support chat.

### ❌ Scenario: Server Error — HTTP 500
Unstructured (Laravel default `{"message": "Server Error"}` or exception payload).
- 🇸🇦 **«حدث خطأ غير متوقع، يرجى المحاولة لاحقاً»** — ARB: `errServer`

---

# 2. GET `/api/complaints` — My complaints (history)

**Purpose:** Fetch all complaints submitted by the authenticated user (ticket history). No pagination, no query params — returns the full list.

### ✅ Scenario: Success — HTTP 200

```json
{
  "status": "success",
  "data": [
    { "…Complaint object…": "" },
    { "…Complaint object…": "" }
  ]
}
```
- Empty list (`"data": []`) is a normal success → show empty state: 🇸🇦 **«لا توجد شكاوى سابقة»** — ARB: `complaintsEmpty`
- List screen per item: `title`, Arabic status chip (from `status` map) tinted by `status_color`, `type_label`, relative `submitted_at`.

### ❌ Scenario: Unauthenticated — HTTP 401 → global handling.

> Failure of this endpoint (network/5xx) → 🇸🇦 **«تعذر تحميل الشكاوى، حاول مجدداً»** — ARB: `complaintsLoadError` (with retry button).

---

# 3. GET `/api/complaints/{id}` — Complaint details

**Purpose:** Fetch one complaint with attachments and resolution. Ownership-checked: requesting someone else's complaint returns 404 (not 403) by design.

### ✅ Scenario: Success — HTTP 200

```json
{
  "status": "success",
  "data": { "…Complaint object…": "" }
}
```
Detail screen guidance:
- `resolution_notes != null` → show an answer card titled 🇸🇦 **«رد فريق الدعم»** (`complaintResolutionTitle`).
- `status` terminal (`resolved`/`closed`) → hide any "awaiting" indicators; show `resolved_at`.
- Attachments: render images inline (`mime_type` starts with `image/`), PDFs as an open-in-viewer tile with `original_name` + `size_kb`.

### ❌ Scenario: Not Found / Not Yours — HTTP 404

```json
{ "status": "error", "message": "Complaint not found." }
```
- 🇸🇦 **«الشكوى غير موجودة»** — ARB: `complaintNotFound` → pop back to the list.

### ❌ Edge: non-numeric `{id}` (e.g. `/api/complaints/abc`) → HTTP 500 (PHP TypeError, no route constraint). Never build such URLs; treat as `errServer`.

---

# 4. POST `/api/contact` — Open support chat (يعمل أثناء الحظر ✅)

**Purpose:** Find-or-create a private chat conversation between the user and the first active support agent. Returns a `conversation_id` to be used with the chat endpoints (§5). **The only protected endpoint a banned user may call.**

**Request payload:** none (empty body).

### ✅ Scenario: Existing conversation — HTTP 200

```json
{
  "status": "success",
  "conversation_id": 8,
  "message": "Support chat ready.",
  "agent": { "name": "Sara Support" }
}
```

### ✅ Scenario: New conversation created — HTTP 201

```json
{
  "status": "success",
  "conversation_id": 8,
  "message": "Support chat started.",
  "agent": { "name": "Sara Support" }
}
```
- Treat 200 and 201 identically: navigate to the chat screen with `conversation_id`.
- 🇸🇦 Optional toast: **«تم فتح محادثة مع فريق الدعم»** — ARB: `supportChatOpened`
- Chat screen title: 🇸🇦 **«الدعم الفني»** (`supportChatTitle`); you may show `agent.name` as subtitle.

### ❌ Scenario: No support agents — HTTP 503 (two variants, same UX)

```json
{ "status": "error", "message": "No support agents are available at the moment." }
```
```json
{ "status": "error", "message": "Support is currently unavailable." }
```
- 🇸🇦 **«الدعم الفني غير متاح حالياً، يرجى المحاولة لاحقاً»** — ARB: `supportUnavailable`

### ❌ Scenario: Self-chat guard — HTTP 422
`{"status":"error","message":"Cannot open support chat."}` (only happens if the logged-in user *is* the support agent). 🇸🇦 **«تعذر فتح محادثة الدعم»** — ARB: `supportChatFailed`

### 🚫 Banned-user nuance
On any *other* endpoint a banned user receives 403 `USER_BANNED` with a `ban` object. `POST /api/contact` still works. Build the ban screen as: ban reason + expiry (from the 403 payload) + a single CTA button calling this endpoint.

---

# 5. Support conversation messages (shared chat endpoints)

The conversation returned by §4 is a regular chat conversation. Full contract in `API_RESPONSE_SPEC_AR.md` §9; summary of what the support screen needs:

| Endpoint | Purpose | Success | Errors |
|---|---|---|---|
| `GET /api/chat/conversations/{conversationId}/messages?page=1` | Message history (50/page, envelope `success: true`) | `data: [ {id, sender{id,name,profile_photo}, type: text\|image, content, metadata, created_at, is_edited} ]` | 404 «المحادثة غير موجودة» (`chatNotFound`) |
| `POST /api/chat/conversations/{conversationId}/messages` | Send text (`{type:"text", content}`) or image (multipart `type=image, image, caption?`) | 201 + message object | 403 «لا يمكنك إرسال رسائل في هذه المحادثة» (`chatForbidden`) · 422 «محتوى الرسالة غير صالح» (`chatInvalidMessage`) · 422 image «الصورة غير صالحة» (`chatInvalidImage`) · 500 «تعذر إرسال الرسالة، حاول مجدداً» (`chatSendFailed`) |
| `DELETE /api/chat/messages/{messageId}` | Delete own message | 200 «تم حذف الرسالة» (`chatMessageDeleted`) | 404 «تعذر حذف الرسالة» (`chatDeleteFailed`) |

> Messages are also broadcast in real time (`MessageSent` event over the configured broadcast driver) — the Flutter chat screen can subscribe via the existing websocket setup, with HTTP polling as fallback.

---

# 6. Ready-to-use ARB snippet (Arabic)

```json
{
  "complaintSubmitSuccess": "تم إرسال شكواك بنجاح، سيقوم فريق الدعم بمراجعتها قريباً",
  "complaintErrTitle": "يرجى إدخال عنوان الشكوى (بحد أقصى 255 حرفاً)",
  "complaintErrDescription": "يرجى كتابة وصف الشكوى (بحد أقصى 2000 حرف)",
  "complaintErrType": "يرجى اختيار نوع الشكوى",
  "complaintErrAttachmentsMax": "يمكن إرفاق 3 ملفات كحد أقصى",
  "complaintErrAttachmentInvalid": "يجب أن يكون المرفق صورة (JPG/PNG) أو ملف PDF بحجم لا يتجاوز 5 ميغابايت",
  "complaintsEmpty": "لا توجد شكاوى سابقة",
  "complaintsLoadError": "تعذر تحميل الشكاوى، حاول مجدداً",
  "complaintNotFound": "الشكوى غير موجودة",
  "complaintResolutionTitle": "رد فريق الدعم",
  "complaintStatusPending": "قيد الانتظار",
  "complaintStatusInReview": "قيد المراجعة",
  "complaintStatusEscalated": "مُصعّدة للإدارة",
  "complaintStatusResolved": "تم الحل",
  "complaintStatusClosed": "مغلقة",
  "complaintTypeTripSafety": "أمان الرحلة",
  "complaintTypeDriverBehavior": "سلوك السائق",
  "complaintTypePassengerBehavior": "سلوك الراكب",
  "complaintTypeRideCancellation": "إلغاء الرحلة",
  "complaintTypeFinancialIssue": "مشكلة مالية",
  "complaintTypeAccountIssue": "مشكلة في الحساب",
  "complaintTypeTechnicalIssue": "عطل تقني",
  "complaintTypeOther": "أخرى",
  "supportChatTitle": "الدعم الفني",
  "supportChatOpened": "تم فتح محادثة مع فريق الدعم",
  "supportUnavailable": "الدعم الفني غير متاح حالياً، يرجى المحاولة لاحقاً",
  "supportChatFailed": "تعذر فتح محادثة الدعم",
  "chatNotFound": "المحادثة غير موجودة",
  "chatForbidden": "لا يمكنك إرسال رسائل في هذه المحادثة",
  "chatInvalidMessage": "محتوى الرسالة غير صالح",
  "chatInvalidImage": "الصورة غير صالحة",
  "chatSendFailed": "تعذر إرسال الرسالة، حاول مجدداً",
  "chatMessageDeleted": "تم حذف الرسالة",
  "chatDeleteFailed": "تعذر حذف الرسالة",
  "errServer": "حدث خطأ غير متوقع، يرجى المحاولة لاحقاً",
  "errNetwork": "تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت"
}
```

---

# 7. Implementation checklist for the Flutter side

1. **One enum-driven model:** `Complaint` with `ComplaintType` and `ComplaintStatus` Dart enums keyed on the backend string values; unknown value → fall back to `other`/`pending` defensively.
2. **Parser:** this module's envelope is `status == "success"`; the chat endpoints inside §5 use `success == true`. Handle both in the shared response wrapper.
3. **Repository methods:** `submitComplaint(payload, files)`, `getMyComplaints()`, `getComplaint(id)`, `openSupportChat()` → returns `conversationId`.
4. **Cubits:** `ComplaintsListCubit` (load/refresh/empty), `ComplaintSubmitCubit` (validate → multipart upload with progress), `ComplaintDetailCubit`, `SupportChatCubit` (reuses chat repository).
5. **Ban interceptor:** on global 403 `USER_BANNED`, allow only the support-chat flow; everything else navigates to the ban screen.
6. **Do not display any backend `message` or `status_label`** — only mapped ARB strings. `type_label` is Arabic but prefer the local map for offline consistency.
