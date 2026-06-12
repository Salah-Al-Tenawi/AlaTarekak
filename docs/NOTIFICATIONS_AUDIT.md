# Notification System Audit — Complete Trigger & Delivery Blueprint

> **Purpose:** Full audit of every notification the mobile user can receive: trigger, class, channels, real-time behavior, FCM/background behavior, payload content, and recipient. Written to be handed to the Flutter client side.
> **Audited:** `app/Notifications/`, `app/Events/`, `app/Listeners/`, `NotificationService`, `PushNotification*` services, all `createNotification()` / `broadcast()` / `->notify()` call sites, `routes/channels.php`, `BroadcastServiceProvider`, `.env` broadcast config.

---

## 1. How the system actually works (architecture)

There is **ONE active pipeline**: `App\Services\NotificationService::createNotification()`. Every real notification in the app goes through this single funnel, which does **three things at once**:

```
createNotification(user, type, title, message, data, priority, category)
 ├─ 1. DATABASE   → rows in `notifications` + `user_notifications`
 │                  (this is what GET /api/notifications returns)
 ├─ 2. FCM PUSH   → PushNotificationService → FcmSenderService (kreait, FCM V1 API)
 │                  CloudMessage with BOTH `notification` block AND `data` block
 └─ 3. REAL-TIME  → broadcast(NotificationSent) via Pusher
                    private channel: user.{id} · event: notification.sent
```

In addition, there are **three broadcast-only events** (real-time WebSocket only — **no DB row, no FCM push**): `MessageSent`, `RideCreated`, `RideBooked`/`RideCancelled`.

The legacy Laravel-notification layer (`app/Notifications/*`, `app/Listeners/*`) is **dead code** — see §6.

### Delivery-channel truth table

| Channel | Mechanism | Works today? |
|---|---|---|
| Database (in-app list) | Eloquent insert, read via `/api/notifications` | ✅ Yes — fully functional |
| FCM Push (background / terminated) | kreait `firebase-php`, **FCM HTTP V1** with service-account JSON (`config('services.fcm.credentials')`), sent **synchronously** per token | ⚠️ **Broken in practice** — see Defect D1 |
| Real-time WebSocket (foreground) | Pusher Cloud (`BROADCAST_DRIVER=pusher`, cluster `ap2`), all events are `ShouldBroadcastNow` (no queue needed) | ⚠️ **Private `user.{id}` channels broken** — see Defect D2; `conversation.{id}` works |
| Mail | Only OTP emails (`OtpVerificationMail`) — part of auth flows, not the notification system | ✅ Yes |
| SMS | Not used anywhere | — |

### Background / Terminated state analysis (FCM)

`FcmSenderService::buildMessage()` attaches **both** a `notification` payload (`title` + `body`) **and** a `data` payload. Consequence for Flutter:

- **Background / terminated:** Android & iOS render a **system-tray notification automatically** (title/body from the `notification` block). `data` (e.g. `ride_id`, `booking_id`, `notification_id`, `type`, `category`) is delivered in the tap intent → use it for deep-linking.
- **Foreground:** nothing is shown automatically — Flutter must handle `FirebaseMessaging.onMessage` and render a local notification/in-app banner itself.
- Android config adds `priority: high` only when `icon`/`sound`/`click_action` are passed — **the app never passes them**, so messages go at default priority (may be delayed in Doze mode).
- Invalid/expired tokens are auto-pruned (FCM `NotFound` → token marked invalid).

---

## 2. 🔴 Critical defects found (must-fix before Flutter integration)

### D1 — FCM token registration endpoints are NOT routed → push is dead
`PushNotificationController` (`registerToken`, `removeToken`, `getUserTokens`, `testNotification`) exists and is even imported in `routes/api.php`, **but no route points to it**. The Flutter app has no way to register its FCM token → `PushTokenManager::getUserTokens()` always returns `[]` → `sendToUser()` logs "No active tokens found" and silently skips **every push**.
**Bonus bug:** when routes are added, `registerToken` will still crash — the controller passes `$request->user()` (a `User` object) into `PushNotificationService::registerToken(int $userId, ...)` and passes 4 args to a 3-param method.
**Fix:** add routes (e.g. `POST /api/push/register`, `POST /api/push/remove` under `jwt`) and fix the call to `registerToken($request->user()->id, $request->token, $request->platform)`.

### D2 — `user.{id}` private channel has NO auth callback → all real-time user events fail
`routes/channels.php` only authorizes `App.Models.User.{id}` and `conversation.{conversationId}`. But `NotificationSent`, `RideCreated`, `RideBooked`, `RideCancelled` all broadcast on `PrivateChannel('user.{id}')`. Pusher private channels require server authorization → subscription to `private-user.{id}` returns **403** → the client can never receive them.
**Fix:** add to `routes/channels.php`:
```php
Broadcast::channel('user.{id}', fn ($user, $id) => (int) $user->id === (int) $id);
```

### D3 — Chat messages produce NO notification when the app is closed
`sendMessage` only fires `broadcast(new MessageSent(...))` (WebSocket). There is **no DB notification and no FCM push** for chat. If the recipient's app is backgrounded/terminated, the message arrives silently — the user is never alerted. The intended mechanism (`MessageReceived` event → `SendMessageNotification` listener) is never dispatched (dead, §6).
**Fix suggestion:** in `ChatController::sendMessage` (or `ChatMessageHandler`), also call `NotificationService::createNotification($receiver, 'chat_message', ..., category: 'chat')` or at minimum `PushNotificationService::sendToUser()` for the other participant.

### D4 — Verification **approval** never notifies the user
`StaffAdminController::rejectVerification` sends `verification_rejected` («طلب التوثيق مرفوض»), but the **approve** path sends nothing (same for the admin-dashboard approve route). The user finds out only by polling `GET /api/profile/verify/status/{id}`.

### D5 — Mixed languages in stored content
The DB `title`/`message` are what the mobile notifications screen displays. Currently: ride/booking/ban/wallet-reject content is **English**, staff/complaint/verification content is **Arabic**, and wallet-approve title is mixed (`"{label} - موافق"`). Also `wallet_charged` says **«ر.س» (Saudi Riyal)** while the app currency is SYP («ل.س»).
**Recommendation:** either localize all `createNotification()` call sites to Arabic on the backend (correct fix for an Arabic-only app), or have Flutter ignore `title`/`message` and re-render from `type` + `data` (fragile — `data` doesn't always carry enough info, e.g. addresses).

---

## 3. Complete trigger inventory — the ACTIVE pipeline

All entries below: **Mechanism** = `NotificationService::createNotification()` → DB + FCM (broken, D1) + Pusher `private-user.{id}` event `notification.sent` (broken, D2). **DB list always works.**

`type` is the machine key stored in DB and sent in FCM `data.type`. Categories: `ride` | `system` | `chat` | `general`.

### 3.1 Ride lifecycle (`RideService`) — category `ride`

| # | Trigger | `type` | Recipient | Title (EN, hardcoded) | Body summary | Priority | Extra `data` |
|---|---|---|---|---|---|---|---|
| 1 | Driver creates a ride | `ride_created` | Driver | `Ride Created ✓` | "Your ride from {pickup} to {destination} is now live." | normal | `ride_id` |
| 2 | Driver cancels own ride | `ride_cancelled_driver` | Driver | `Ride Cancelled` | "…has been cancelled. Your creation fee has been refunded." | normal | `ride_id`, `passengers_notified`, `elapsed_pct` |
| 3 | Driver cancels → each **confirmed** passenger | `ride_cancelled_by_driver` | Passenger(s) | `Ride Cancelled by Driver` | "The driver cancelled the ride… {refund detail}" | high | `ride_id`, `booking_id`, `refund_amount` |
| 4 | Driver cancels → each **pending** requester | `ride_cancelled_by_driver` | Passenger(s) | `Ride Cancelled by Driver` | "…Your pending booking request has been cancelled — no payment was taken." | normal | `ride_id`, `booking_id` |
| 5 | Driver finishes ride with zero bookings | `ride_finished_no_passengers` | Driver | `Ride Finished` | "No passengers booked — creation fee refunded." | normal | `ride_id` |
| 6 | Driver hits finish (with passengers) → awaiting confirmation | `confirm_completion_needed` | Driver | `Confirm Ride Completion` | "…confirm…to release your earnings and earn +10 trust points." | high | `ride_id` |
| 7 | Same trigger → each confirmed passenger | `confirm_completion_needed` | Passenger(s) | `Did the Ride Happen?` | "Please confirm…to earn +10 trust points." | normal | `ride_id`, `booking_id` |
| 8 | Both sides confirmed → ride completed | `ride_completed` | Driver | `Ride Completed ✓` | "…is complete. Earnings released." | high | `ride_id` |
| 9 | Same trigger | `ride_completed` | Passenger(s) | `Ride Completed ✓` | "…is complete. Thank you!" | high | `ride_id`, `booking_id` |
| 10 | Passenger reports driver no-show | `driver_no_show_reported` | Driver | `No-Show Reported Against You` | "{passenger} reported you… trust score penalised (−15 pts)." | high | `ride_id`, `booking_id` |
| 11 | Same trigger (e-pay refund issued) | `driver_no_show_refund` | Passenger | `Refund Issued ✓` | "Driver no-show confirmed. Full refund of {N} SYP returned to your wallet." | high | `ride_id`, `booking_id`, `refund_amount` |

### 3.2 Booking lifecycle (`BookingService`) — category `ride`

| # | Trigger | `type` | Recipient | Title (EN) | Body summary | Priority | Extra `data` |
|---|---|---|---|---|---|---|---|
| 12 | Passenger books (direct ride) | `ride_booked` | Driver | `New Booking Received` | "{passenger} booked {n} seat(s) on your ride." | high | `ride_id`, `booking_id`, `passenger_id`, `seats` |
| 13 | Passenger requests (request ride) | `booking_requested` | Driver | `New Booking Request` | "{passenger} requested {n} seat(s). Please accept or reject." | high | same |
| 14 | Booking created (direct) | `booking_confirmed` | Passenger | `Booking Confirmed ✓` | "Your {n} seat(s)… are confirmed." | normal | `ride_id`, `booking_id`, `seats` |
| 15 | Booking created (request) | `booking_request_sent` | Passenger | `Request Sent` | "…Waiting for driver approval." | normal | same |
| 16 | Driver accepts request | `booking_accepted` | Passenger | `Booking Accepted ✓` | "{driver} accepted your request for {n} seat(s).{payment note}" | high | `booking_id`, `ride_id` |
| 17 | Driver rejects request | `booking_rejected` | Passenger | `Booking Request Declined` | "…was declined by the driver." | normal | `booking_id`, `ride_id` |
| 18 | Passenger cancels seats (full or partial) | `booking_cancelled` | Passenger | `Booking Cancelled` | "Cancelled {n} seat(s)… {refund policy detail}" | normal | `booking_id`, `ride_id`, `seats_cancelled` |
| 19 | Same trigger (booking was confirmed) | `passenger_cancelled` | Driver | `Passenger Cancelled Seats` | "{passenger} cancelled {n} seat(s). You received {fee} SYP cancellation fee." / "(cash ride — no wallet impact)" | normal | same |
| 20 | Driver reports passenger no-show | `passenger_no_show` | Passenger | `No-Show Recorded` | "You were marked as a no-show…{wallet note}" | high | `ride_id`, `booking_id` |

### 3.3 Support / Complaints (`StaffComplaintService`) — category `system`, Arabic content ✅

| # | Trigger | `type` | Recipient | Title (AR) | Body | Priority |
|---|---|---|---|---|---|---|
| 21 | Support agent responds / resolves complaint | `complaint_resolved` | Complainant | «تم الرد على شكواك» | «تم معالجة شكواك "{title}" وتحديث حالتها إلى: {status}.» | high |
| 22 | Admin resolves an **escalated** complaint | `complaint_resolved` | Complainant | «تم حل شكواك المُصعَّدة» | «تمت معالجة شكواك "{title}" من قِبَل الإدارة. الحالة: {status}.» | high |

`data`: `complaint_id`. *(Submitting a complaint does NOT generate any notification to the user.)*

### 3.4 Staff / Admin actions on the user — category mixed

| # | Trigger | `type` | Recipient | Title | Body language | Priority | Category |
|---|---|---|---|---|---|---|---|
| 23 | Staff cancels a trip | `ride_cancelled` | Each booked passenger | «رحلتك تم إلغاؤها» | Arabic ✅ («تم إلغاء الرحلة من قِبل فريق الدعم. السبب: …») | high | ride |
| 24 | Staff cancels a booking | `booking_cancelled` | Passenger | «تم إلغاء حجزك» | Arabic ✅ | high | ride |
| 25 | Staff rejects verification request | `verification_rejected` | User | «طلب التوثيق مرفوض» | Arabic ✅ (+ reason) | high | system |
| 26 | ⚠️ Staff/Admin **approves** verification | — | — | **No notification is sent (gap D4)** | — | — | — |
| 27 | Admin approves wallet charge/withdraw request | `wallet_request_approved` | User | `{label} - موافق` (mixed!) | mixed | high | system |
| 28 | Admin rejects wallet request | `wallet_request_rejected` | User | `{label} - Rejected` | English ("Your request for {N} SYP has been rejected.{reason}") | normal | system |
| 29 | Admin charges passenger wallet (dashboard) | `wallet_charged` | User | «تم شحن محفظتك» | Arabic ✅ — but says **«ر.س»** instead of SYP (bug D5) | normal | system |
| 30 | Admin bans account | `account_banned` | User | `Account Banned` | English ("Your account has been banned. Reason: …{expiry}") | high | system |
| 31 | Admin unbans account | `account_unbanned` | User | `Account Restored` | English ("Your account ban has been lifted…") | high | system |
| 32 | Dev test (`testNotification`, local env only, **unrouted**) | `test` | Self | `Test Notification` | English | normal | system |

### 3.5 Auth / OTP / Login — **no notifications**
Login, signup, OTP send/verify generate **no in-app/push notifications**. OTP delivery is via **email** (`OtpVerificationMail`) or **WhatsApp** (wallet OTP). The `OtpSent` event class exists but is never dispatched.

---

## 4. Broadcast-only events (real-time WebSocket, NO DB row, NO FCM)

All implement `ShouldBroadcastNow` (broadcast synchronously over Pusher). These exist **in addition to** §3 notifications.

| Event class | Fired when | Channel(s) | Event name (Pusher) | Payload |
|---|---|---|---|---|
| `MessageSent` | Chat message sent (`POST /chat/conversations/{id}/messages`) | `private-conversation.{conversationId}` ✅ auth OK | **`App\Events\MessageSent`** (no `broadcastAs` — full class name!) | `message: {id, conversation_id, sender{id,name}, type, content (URL if image), metadata, created_at}` |
| `NotificationSent` | Every `createNotification()` (§3) | `private-user.{userId}` ❌ auth missing (D2) | `notification.sent` | `notification: {id, title, message, type, data, sent_at}` |
| `RideCreated` | Ride created | public `rides` ✅ + `private-user.{driverId}` ❌ | `ride.created` | `ride: {id, driver_id, pickup_address, destination_address, departure_time, available_seats, price_per_seat, vehicle_type}` |
| `RideBooked` | Booking created | `private-user.{driverId}` ❌, `private-user.{passengerId}` ❌ | `ride.booked` | `ride{…}, booking{id,seats,status,created_at}, passenger{id,name}` |
| `RideCancelled` | Driver cancels ride | public `rides` ✅ + `private-user.{driver}` ❌ + each affected `private-user.{passenger}` ❌ | `ride.cancelled` | `ride{…}, driver{id,name}, affected_bookings_count, cancellation_time` |

**Flutter connection details:**
- Pusher Cloud, cluster **`ap2`**, key in `.env` (`PUSHER_APP_KEY`).
- Private-channel auth endpoint: `POST /broadcasting/auth` protected by the **`jwt` middleware** → send `Authorization: Bearer <access_token>`.
- Event-name gotcha: aliased events must be bound exactly as `notification.sent`, `ride.created`, `ride.booked`, `ride.cancelled`; `MessageSent` has **no alias** → bind `App\Events\MessageSent` (or `.listen('MessageSent')` with Echo namespacing).

---

## 5. Mail-based notifications (auth flows only)

| Trigger | Class | Channel | Content |
|---|---|---|---|
| Signup / resend / forgot-password OTP | `OtpVerificationMail` (Mailable, not a Notification) | mail | 6-digit OTP, expiry 10 min |
| Laravel password-broker reset (legacy) | `CustomResetPassword` (`->notify()` in `User::sendPasswordResetNotification`) | mail | **Dead** — app uses the OTP flow, broker is never invoked |

---

## 6. Dead / legacy code (safe to delete, do NOT build against)

| Artifact | Why it's dead |
|---|---|
| `app/Notifications/RideBookedNotification.php` | Untouched scaffold stub (`mail` channel, placeholder text "The introduction to the notification."); only referenced by a dead listener |
| `app/Notifications/RideCancelledNotification.php`, `UserVerifiedNotification.php`, `MessageReceivedNotification.php` | Same scaffold stubs |
| `app/Notifications/CustomResetPassword.php` | Password reset is OTP-based; Laravel broker never runs |
| Listeners `SendRideBookedNotification`, `SendRideCancelledNotification`, `SendMessageNotification`, `SendUserVerifiedNotification` (registered in `EventServiceProvider`) | Their events are either **only `broadcast()`ed** (the `broadcast()` helper does **not** run event listeners) or **never dispatched at all** (`MessageReceived`, `UserVerified`) |
| Events `OtpSent`, `ConversationCreated`, `MessageReceived`, `UserVerified` | Never dispatched anywhere |
| `app/Jobs/SendPushNotification.php` | Never dispatched — all FCM sends are synchronous inline |
| `PushNotificationController` | Exists but unrouted (Defect D1) |

---

## 7. Recommended backend fixes (priority order)

1. **D2** — add `user.{id}` channel auth (1 line in `routes/channels.php`) → unblocks ALL real-time user notifications.
2. **D1** — route + fix `PushNotificationController::registerToken` → unblocks ALL FCM push (background/terminated delivery).
3. **D3** — add push+DB notification for incoming chat messages (category `chat`).
4. **D4** — send `verification_approved` notification on approval (Arabic).
5. **D5** — convert all English `createNotification()` titles/bodies to Arabic; fix «ر.س» → «ل.س».
6. Cleanup: delete the dead classes in §6 to stop future confusion.

---

## 8. Flutter-side `type` → Arabic display map (until D5 is fixed)

If the backend texts stay English, the client can re-title by `type` (body may still need the English string for details like addresses/amounts):

| `type` | Arabic title |
|---|---|
| `ride_created` | تم إنشاء الرحلة |
| `ride_cancelled_driver` / `ride_cancelled` | تم إلغاء الرحلة |
| `ride_cancelled_by_driver` | قام السائق بإلغاء الرحلة |
| `ride_finished_no_passengers` | انتهت الرحلة |
| `confirm_completion_needed` | يرجى تأكيد إتمام الرحلة |
| `ride_completed` | اكتملت الرحلة |
| `driver_no_show_reported` | بلاغ عدم حضور بحقك |
| `driver_no_show_refund` | تمت إعادة المبلغ |
| `ride_booked` | حجز جديد |
| `booking_requested` | طلب حجز جديد |
| `booking_confirmed` | تم تأكيد حجزك |
| `booking_request_sent` | تم إرسال طلب الحجز |
| `booking_accepted` | تم قبول حجزك |
| `booking_rejected` | تم رفض طلب الحجز |
| `booking_cancelled` | تم إلغاء الحجز |
| `passenger_cancelled` | قام الراكب بإلغاء مقاعد |
| `passenger_no_show` | تسجيل عدم حضور |
| `complaint_resolved` | تم الرد على شكواك |
| `verification_rejected` | طلب التوثيق مرفوض |
| `wallet_request_approved` | تمت الموافقة على طلب المحفظة |
| `wallet_request_rejected` | تم رفض طلب المحفظة |
| `wallet_charged` | تم شحن محفظتك |
| `account_banned` | تم حظر حسابك |
| `account_unbanned` | تمت إعادة تفعيل حسابك |
