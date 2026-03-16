# Push Notifications Feature — Detailed Implementation Plan

## Overview

Add push notifications to the app for three events:

| # | Event | Who receives | When sent |
|---|-------|-------------|-----------|
| 1 | **New recording uploaded** | All users | Automatically after a successful upload |
| 2 | **Publisher added to mosque** | The new publisher only | Automatically after being added |
| 3 | **Day schedule table updated** | All users | **Only** when admin presses a manual "إرسال إشعار" button |

---

## User Review Required

> [!IMPORTANT]
> **Firebase project required.** You will need a Firebase project linked to this app. The Supabase Edge Function will need the Firebase Admin SDK service account key. I'll guide you through setup.

> [!WARNING]
> **Breaking change for existing installs:** Users must update the app to start receiving notifications. Old app versions won't have FCM tokens stored.

---

## Architecture Decision

```
┌─────────────┐     ┌───────────────────────┐     ┌─────────────┐
│  Flutter App │────▶│  Supabase Edge Function│────▶│  Firebase    │
│  (FCM Token) │     │  (sends notifications) │     │  Cloud Msg   │
└─────────────┘     └───────────────────────┘     └─────────────┘
```

**Why this approach (Supabase Edge Function + FCM)?**
- The app already uses Supabase — no need for a separate backend server.
- FCM is free and handles delivery to Android/iOS.
- Edge Functions let us send notifications server-side (secure, no API keys on client).
- The Flutter app only needs to: (a) register FCM token, (b) call Edge Functions at the right time.

---

## Proposed Changes

### 1. Firebase Setup (Manual — one-time)

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Add Android app (`com.sout_salah.app` or your actual package name).
3. Download `google-services.json` → place in `android/app/`.
4. (Optional) Add iOS app if needed later.

---

### 2. Supabase Database Changes

#### [MODIFY] `schema.sql` & new migration

```sql
-- Store FCM tokens for each user
CREATE TABLE public.fcm_tokens (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  token TEXT NOT NULL,
  platform TEXT DEFAULT 'android',  -- 'android' or 'ios'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Users can manage their own tokens
CREATE POLICY "Users can manage own tokens"
  ON fcm_tokens FOR ALL
  USING (auth.uid() = user_id);
```

---

### 3. Supabase Edge Function (Backend — sends push notifications)

#### [NEW] `supabase/functions/send-notification/index.ts`

A Deno edge function that:
1. Receives a JSON body with `{ type, data }`.
2. Based on `type`:
   - `"new_recording"` → fetches ALL FCM tokens → sends notification with salah name, sheikh name, and day number.
   - `"publisher_added"` → fetches the specific publisher's FCM token → sends personal notification.
   - `"day_schedule"` → fetches ALL FCM tokens → sends notification about the day schedule being ready.
3. Uses Firebase Admin SDK (via service account) to send via FCM.

**Notification content:**

| Type | Title (Arabic) | Body (Arabic) |
|------|---------------|---------------|
| `new_recording` | `تلاوة جديدة 🎧` | `{salah} - الشيخ {shikh} - يوم {dayNumber}` |
| `publisher_added` | `تمت إضافتك كناشر 🕌` | `تم إضافتك كناشر في مسجد {mosqueName}` |
| `day_schedule` | `جدول شيوخ اليوم 📋` | `تم نشر جدول شيوخ يوم {dayNumber}` |

---

### 4. Flutter Dependencies

#### [MODIFY] `pubspec.yaml`

Add:
```yaml
firebase_core: ^3.13.0
firebase_messaging: ^15.2.3
```

---

### 5. Flutter — Core Notification Service

#### [NEW] `lib/core/services/notification_service.dart`

```dart
class NotificationService {
  // Initialize Firebase Messaging
  static Future<void> initialize();

  // Get and store FCM token in Supabase
  static Future<void> registerToken(String userId);

  // Request notification permissions (iOS)
  static Future<void> requestPermissions();

  // Handle foreground notifications
  static void setupForegroundHandler();

  // Send notification via Supabase Edge Function
  static Future<void> sendNotification({
    required String type,           // 'new_recording', 'publisher_added', 'day_schedule'
    required Map<String, dynamic> data,
  });
}
```

#### [MODIFY] `lib/main.dart`

- Add `Firebase.initializeApp()` before `runApp`.
- Call `NotificationService.initialize()`.

#### [MODIFY] `lib/core/di/injection_container.dart`

- Register `NotificationService`.

---

### 6. Flutter — Trigger Point 1: New Recording Uploaded

#### [MODIFY] `lib/features/mosques/presentation/pages/upload_recording_page.dart`

In the `_uploadRecording()` method, after `result.fold(... (recording) { ... })` success callback:

```dart
// After successful upload
NotificationService.sendNotification(
  type: 'new_recording',
  data: {
    'salah': _selectedPrayer!.arabicName,
    'shikh': _sheikhNameController.text.trim(),
    'dayId': widget.dayId,
    'mosqueId': widget.mosqueId,
  },
);
```

---

### 7. Flutter — Trigger Point 2: Publisher Added

#### [MODIFY] `lib/features/mosques/presentation/pages/add_publisher_page.dart`

In the `_submit()` method, after the success callback:

```dart
// After successful publisher add
NotificationService.sendNotification(
  type: 'publisher_added',
  data: {
    'publisherEmail': _emailController.text.trim(),
    'mosqueId': widget.mosqueId,
  },
);
```

---

### 8. Flutter — Trigger Point 3: Day Schedule "Send Notification" Button

#### [MODIFY] `lib/features/mosques/presentation/pages/day_schedule_page.dart`

Add a **"إرسال إشعار بالجدول"** button at the bottom of the page. It is **admin/publisher only** and **only visible when there are rows** in the schedule.

```dart
// Inside the Scaffold body, below DayScheduleTableWidget:
ElevatedButton.icon(
  icon: Icon(LucideIcons.send),
  label: Text('إرسال إشعار بالجدول'),
  onPressed: () async {
    await NotificationService.sendNotification(
      type: 'day_schedule',
      data: {
        'dayId': dayId,
        'mosqueId': mosqueId,
        'dayNumber': dayNumber,
      },
    );
    // Show success snackbar
  },
);
```

This button is **only visible** to admins/publishers (using the same `permissionCheckerProvider.canShowUploadButton()` check used elsewhere).

---

### 9. Android Configuration

#### [MODIFY] `android/app/build.gradle.kts`

Add:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

#### [MODIFY] `android/build.gradle.kts`

Add:
```kotlin
classpath("com.google.gms:google-services:4.4.0")
```

#### [NEW] `android/app/google-services.json`

Downloaded from Firebase Console (manual step).

#### [MODIFY] `android/app/src/main/AndroidManifest.xml`

Add notification permission and default channel:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<meta-data
  android:name="com.google.firebase.messaging.default_notification_channel_id"
  android:value="sout_salah_notifications" />
```

---

### 10. Token Registration Flow

When user **logs in** or **opens the app**:

1. `NotificationService.initialize()` is called.
2. Get FCM token via `FirebaseMessaging.instance.getToken()`.
3. Upsert token into `fcm_tokens` table in Supabase.
4. Listen for token refreshes via `FirebaseMessaging.instance.onTokenRefresh`.

When user **logs out**:

1. Delete the FCM token from `fcm_tokens` table.
2. Delete local token via `FirebaseMessaging.instance.deleteToken()`.

---

## File Changes Summary

| Action | File |
|--------|------|
| NEW | `lib/core/services/notification_service.dart` |
| NEW | `supabase/functions/send-notification/index.ts` |
| NEW | `android/app/google-services.json` (manual) |
| NEW | `migration_fcm_tokens.sql` |
| MODIFY | `pubspec.yaml` |
| MODIFY | `lib/main.dart` |
| MODIFY | `lib/core/di/injection_container.dart` |
| MODIFY | `schema.sql` |
| MODIFY | `upload_recording_page.dart` |
| MODIFY | `add_publisher_page.dart` |
| MODIFY | `day_schedule_page.dart` |
| MODIFY | `android/app/build.gradle.kts` |
| MODIFY | `android/build.gradle.kts` |
| MODIFY | `AndroidManifest.xml` |

---

## Verification Plan

### Static Analysis
```
flutter analyze
```

### Build Test
```
flutter build apk --debug
```
Ensure the app compiles with Firebase dependencies.

### Manual Testing

**Token Registration:**
1. Install the app → check `fcm_tokens` table in Supabase → token should appear.
2. Log out → token should be deleted from `fcm_tokens`.

**Notification 1 — New Recording:**
1. Log in as admin/publisher.
2. Upload a recording.
3. Check that ALL other devices receive a notification: `"تلاوة جديدة 🎧 — {salah} - الشيخ {shikh}"`.

**Notification 2 — Publisher Added:**
1. Log in as admin.
2. Add a publisher by email.
3. Check that ONLY the publisher's device receives: `"تمت إضافتك كناشر 🕌"`.

**Notification 3 — Day Schedule:**
1. Log in as admin/publisher.
2. Open a day schedule → add rows.
3. The "إرسال إشعار بالجدول" button appears at the bottom.
4. Press it → ALL devices receive: `"جدول شيوخ اليوم 📋 — تم نشر جدول شيوخ يوم {dayNumber}"`.
5. Verify notification is NOT sent automatically when rows are added — only on button press.
