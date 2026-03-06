# EduAir — Bugs, Errors & Debugging Playbook

> This is a living document. Every time you hit a real bug, document it here.
> Future you (and future teammates) will thank you.

---

## Table of Contents

1. [The Debugging Mindset](#1-the-debugging-mindset)
2. [Debugging Toolkit for Flutter](#2-debugging-toolkit-for-flutter)
3. [Bug Log](#3-bug-log)
4. [Common Flutter / Firebase Error Reference](#4-common-flutter--firebase-error-reference)

---

## 1. The Debugging Mindset

Debugging is not luck — it is a disciplined skill. Follow this process every time:

```
SYMPTOM → REPRODUCE → ISOLATE → IDENTIFY ROOT CAUSE → FIX → VERIFY
```

### The Golden Rules

1. **Never guess and change code.** Read the actual error first.
2. **Get the full stack trace.** A stack trace tells you exactly what file, line, and call chain caused the crash. Without it you are guessing.
3. **One change at a time.** If you change three things at once, you don't know which one fixed it.
4. **Distinguish warnings from errors.** Not every red line is a crash. Read the message.
5. **Use `dev.log` strategically.** Add named log entries before and after risky operations so you can see exactly which step ran last before a crash.

### The First Three Questions

Before writing a single line of fix code, answer these:

| Question | Why it matters |
|----------|----------------|
| What exactly is the error message? | Tells you the type of failure |
| What file and line did it crash on? | Tells you where to look |
| What did the user do right before the crash? | Tells you how to reproduce it |

---

## 2. Debugging Toolkit for Flutter

### 2.1 Run in Terminal, Not Just the IDE Play Button

```bash
flutter run
```

The terminal shows **all** output — `dev.log` entries, native iOS/Android errors, and the full stack trace when a crash happens. The IDE Debug Console sometimes truncates or hides critical lines.

### 2.2 Add Named Logging With `dev.log`

```dart
import 'dart:developer' as dev;

dev.log('Starting Google sign-in…', name: 'AuthService');
dev.log('Got tokens: idToken=${token != null}', name: 'AuthService');
```

- The `name:` label groups your logs so you can filter them.
- Add a log at the **start** and **end** of every async operation.
- When a crash happens, the last log you see tells you which step completed.

### 2.3 Read the Full Stack Trace

In the terminal or VS Code Debug Console, look for:

```
══╡ EXCEPTION CAUGHT BY ... ╞════════════
The following PlatformException was thrown ...
  firebase_auth/sign_in_canceled
  ...
#0  AuthService.signInWithGoogle (auth_services.dart:30)
#1  _SignInPageState._handleGoogleSignIn (sign_in_form.dart:122)
```

The numbered lines (`#0`, `#1`, ...) show you the exact call chain. **Start reading from `#0`** — that is where the crash happened.

### 2.4 Distinguish Warning vs Crash

| Message type | What it means | Action |
|---|---|---|
| `[ERROR:flutter/impeller/...]` | Impeller graphics engine validation warning | **Ignore in debug** — not your code |
| `Target native_assets required define SdkRoot` | Build system warning | **Ignore** — harmless |
| `══╡ EXCEPTION CAUGHT ╞══` | A real Dart/Flutter exception | **Read and fix** |
| `E/flutter (...)` on Android | Flutter engine error | **Read carefully** |
| `[YourName] ...` from dev.log | Your own log entry | Use to trace flow |

### 2.5 Impeller Warning (iOS) — Safe to Ignore

```
[ERROR:flutter/impeller/entity/contents/contents.cc(122)]
Break on 'ImpellerValidationBreak' to inspect point of failure:
Contents::SetInheritedOpacity should never be called when
Contents::CanAcceptOpacity returns false.
```

This is Flutter's new Impeller rendering engine flagging a visual composition edge case.
**It is NOT a crash. It is NOT your code. It does not affect functionality.**
It appears constantly in debug builds on iOS. Ignore it.

---

## 3. Bug Log

---

### BUG-001 — Google Sign-In Cancel Crash

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** High — app crashed on user action

#### Symptom

Tapping the Google sign-in button and then pressing **Cancel** (or **Continue** in some cases) caused an unhandled exception and crashed the app.

#### Root Cause

The `google_sign_in` Flutter plugin can respond to a user cancel in **two different ways** depending on the iOS version and plugin version:

1. Return `null` from `_googleSignIn.signIn()` — this was handled
2. Throw a `PlatformException` with code `'sign_in_canceled'` or `'-5'` — this was **NOT** handled, causing the crash

The code originally only guarded against a null return, missing the PlatformException path entirely.

#### Fix Applied

**`lib/src/features/auth/services/auth_services.dart`**

```dart
GoogleSignInAccount? googleUser;
try {
  googleUser = await _googleSignIn.signIn();
} on PlatformException catch (e) {
  // Cancel can throw PlatformException with code 'sign_in_canceled' or '-5'
  if (e.code == 'sign_in_canceled' || e.code == '-5') {
    return null; // silent — not an error
  }
  throw Exception('Google sign-in failed. Please try again.');
}

if (googleUser == null) {
  return null; // silent — user backed out without an exception
}
```

**`lib/src/features/auth/sign_in_form.dart`**

```dart
final user = await authService.signInWithGoogle();

// null = user cancelled — do nothing, no snackbar
if (user == null) return;
```

Also added `if (mounted)` guard in the `finally` block to prevent `setState after dispose`:

```dart
finally {
  if (mounted) setState(() => _isSubmitting = false);
}
```

#### How We Debugged It

1. Ran `flutter run` in terminal to see full output
2. Reproduced the crash by tapping Cancel on the Google account picker
3. Read the full stack trace — saw `PlatformException: sign_in_canceled`
4. Added a `try/catch` specifically for `PlatformException` before the general catch block
5. Verified by tapping Cancel again — app handled it silently

#### Lesson Learned

> Third-party plugins (especially auth plugins) can signal the same user action in multiple ways. Always handle **both** null returns AND PlatformExceptions for cancellable flows. Read the plugin's GitHub issues before assuming the fix is in your own code.

---

### BUG-002 — Login Succeeds But App Goes to Wrong Screen

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** High — user cannot access the app after login

#### Symptom

After a successful login, the app showed "Login successful!" snackbar but then navigated back to the onboarding screen instead of the role-appropriate home screen (admin → `/teacherHome`, student → `/studentHome`).

#### Root Cause

After login, the code was calling `ref.read(startupRouteProvider.future)` to decide where to navigate. But `startupRouteProvider` is a `FutureProvider` — it runs **once at app startup**, caches the result, and never re-runs unless its dependencies change.

At startup there was no JWT, so it cached `"/onboarding"`. After login, reading it again returned that same cached `"/onboarding"` — not a fresh calculation.

```
App boot  → startupRouteProvider runs → no JWT → caches "/onboarding"
After login → reads startupRouteProvider → returns cached "/onboarding" ← BUG
```

#### Fix Applied

**`lib/src/features/auth/sign_in_form.dart`**

Replaced the `startupRouteProvider` call with a direct role-based routing helper. After login we already have the user's role — no need to go through the provider at all.

```dart
// Added helper method
String _routeForRole(String role, String? schoolId) {
  if (role.isEmpty) return '/selectRole';
  if (schoolId == null || schoolId.isEmpty) return '/selectSchool';
  if (role == 'student') return '/studentHome';
  if (role == 'teacher' || role == 'admin' || role == 'principal') {
    return '/teacherHome';
  }
  return '/onboarding';
}

// After login, replaced:
// final targetRoute = await ref.read(startupRouteProvider.future);
// With:
final targetRoute = _routeForRole(role, schoolId);
```

Same fix applied to the Google Sign-In path in the same file.

#### How We Debugged It

1. Noticed the snackbar said "Login successful!" but screen was wrong
2. Traced the post-login code path in `sign_in_form.dart`
3. Identified `startupRouteProvider` as a `FutureProvider` — which caches
4. Checked `app_providers.dart` and confirmed it only runs once at startup
5. Replaced provider call with direct role check — fixed immediately

#### Lesson Learned

> Never call a `FutureProvider` to compute something you already have in state. `startupRouteProvider` is for **app startup only**. After login you already have the user and their role — just use it directly. `FutureProvider` caches its result and won't re-run unless its dependencies change.

---

### BUG-003 — "Invalid Email or Password" Shown for ALL Login Errors

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Medium — misleading error messages wasted hours of debugging

#### Symptom

The login screen showed "Invalid email or password." for every failure — whether the password was wrong, the backend was offline, or the server IP/port was wrong. This made it impossible to tell what was actually failing.

#### Root Cause

The catch block in `_handleLogin` was a generic catch-all:

```dart
} catch (e) {
  _showSnack('Invalid email or password.'); // shown for EVERYTHING
}
```

Three separate issues were all hidden behind this one message:
1. Backend was not running (connection refused)
2. Wrong port in `api_client.dart` — was `3500`, backend actually runs on `3000`
3. Wrong credentials (the only case where the message was accurate)

#### Fix Applied

**`lib/src/features/auth/sign_in_form.dart`**

Added `dev.log` to expose the real error in the terminal, plus differentiated error messages:

```dart
} catch (e) {
  dev.log('Login error: $e', name: 'SignInPage');
  if (e is DioException && e.type == DioExceptionType.connectionError) {
    _showSnack('Cannot reach server. Is the backend running?');
  } else if (e is DioException && e.response?.statusCode == 401) {
    _showSnack('Invalid email or password.');
  } else {
    _showSnack('Login failed. Please try again.');
  }
}
```

**`lib/src/services/api_client.dart`**

Fixed the port constant to match the actual backend `.env` config:

```dart
static const _port = '3000'; // .env sets PORT=3000
```

#### How We Debugged It

1. Added `dev.log('Login error: $e', name: 'SignInPage')` to the catch block
2. Ran `lsof -i :3500` — nothing running, backend was off
3. Started backend with `npm run dev` — saw `Server running on http://localhost:3000`
4. Realized port mismatch: Flutter said 3500, backend said 3000
5. Checked `.env` — confirmed `PORT=3000`
6. Fixed `_port` constant in `api_client.dart`

#### Lesson Learned

> A generic catch block that shows the same message for every error is an anti-pattern. It turns a 5-minute fix into hours of guessing. Always:
> 1. Log the real error with `dev.log` in every catch block
> 2. Show different messages for network errors vs auth errors
> 3. Keep port/IP constants in ONE place (`api_client.dart`) and verify they match the backend `.env`

---

### BUG-004 — Students & Attendance Screens Show "Could not load" Error

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** High — two core screens completely broken for assessors

#### Symptom

Both the **Manage Students** and **Attendance Report** screens showed a red error message instead of data:

```
type '_Map<String, dynamic>' is not a subtype of type 'List<dynamic>' in type cast
```

#### Root Cause

The Node.js API wraps every list response inside a `data` key:

```json
{
  "message": "Students fetched successfully",
  "count": 4,
  "data": [ {...}, {...}, {...} ]
}
```

But the Flutter repositories were casting the entire `response.data` object as a `List`:

```dart
// WRONG — response.data is a Map, not a List
return List<Map<String, dynamic>>.from(response.data as List);
```

`response.data` is the full JSON object (a `Map`). The actual array lives one level deeper at `response.data['data']`.

#### Fix Applied

**`lib/src/features/admin/students/data/students_api_repository.dart`**
**`lib/src/features/attendance/data/attendance_api_repository.dart`**

Changed every list parse from:
```dart
response.data as List
```
To:
```dart
response.data['data'] as List
```

Both the `getAll()` (students) and `getByDateAndShift()` + `getStudentHistory()` (attendance) methods were fixed.

#### How We Debugged It

1. Saw the error on screen — the message itself told us the type mismatch (`_Map` vs `List`)
2. Read `students_api_repository.dart` — found `response.data as List` on line 17
3. Checked the Node.js controller with `grep -n "res.status(200).json"` to see the actual response shape
4. Confirmed the API returns `{ message, count, data: [...] }` — array is under `data` key
5. Changed both repositories to use `response.data['data'] as List` — fixed immediately

#### Lesson Learned

> Always verify the actual API response shape before writing the Flutter parse code. Use `curl` or Postman to see the exact JSON structure first. The Node API response envelope `{ message, count, data: [...] }` is the standard pattern across ALL list endpoints in this project — always access `response.data['data']` for lists, not `response.data` directly.

---

### BUG-005 — Stray `],` Causes Cascading Syntax Errors After Refactor

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** High — entire settings page broken, multiple false "unused" warnings

#### Symptom

After replacing `_SectionCard` with a custom `Container` for the profile header, the following errors appeared all at once:

- `Expected an identifier` at the `if (isAdminOrPrincipal)` line
- `Expected to find ')'`
- `_notifications`, `_darkMode`, `_handleLogout`, `isAdminOrPrincipal`, `_ToggleRow` all reported as unused
- The LOG OUT button and PREFERENCES section visually disappeared

#### Root Cause

When converting `_SectionCard` to a raw `Container`, an extra `],` was accidentally left in the file. This closed the **outer Column's `children: [` list** prematurely — before the MY ACCOUNT, SCHOOL, PREFERENCES, and LOG OUT sections.

Everything after the stray `],` was now outside the children list but still inside the `Column(` constructor, which is syntactically invalid. The Dart parser then reported cascading errors for every widget and variable that appeared after it — even though those lines were perfectly valid code.

```dart
              ),    // closes Container ✓
                ],  // ← STRAY — accidentally closed outer Column's children list!

              // ── MY ACCOUNT ─── (now outside the list — syntax error cascade begins)
```

#### Fix Applied

**`lib/src/features/settings/settings_page.dart`**

Deleted the stray `],` line. The outer Column's `children` list was already correctly closed at the bottom of the build method — this extra bracket served no purpose.

#### How We Debugged It

1. Saw "Expected an identifier" pointing to `if (isAdminOrPrincipal)` — but that line was valid
2. Noticed ALL warnings were on variables/widgets that came AFTER the profile card
3. Read upward from the error line — spotted the orphan `],` immediately after the Container's closing `)`
4. Counted brackets: Container closed correctly at `),`, the `],` below it had no matching `[`
5. Deleted the stray `],` — all 7 errors/warnings cleared instantly

#### Lesson Learned

> When you refactor a widget (e.g. `_SectionCard` → `Container`), cascading "unused variable" warnings are a strong signal that a bracket mismatch has broken the syntax tree, not that your variables are actually unused. Always read **upward** from the first error line, not at the error line itself — the root cause is usually a mismatched bracket a few lines above.

---

### BUG-006 — Custom Container Shrinks to Content Width Instead of Full Width

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Low — visual only, profile card appeared as a small box on the left

#### Symptom

After replacing the profile header's `_SectionCard` with a raw `Container`, the card shrank to only fit its content (roughly half the screen width), while all other section cards remained full width.

#### Root Cause

`_SectionCard` uses a `Column(children: children)` where the children include `_SettingsRow` — which contains a `Row` with an `Expanded` widget. That `Expanded` forces the Row, then the Column, then the Container to stretch to maximum available width.

The profile card's Column children (`Text`, `CircleAvatar`, badge `Container`) have no `Expanded` or `double.infinity` constraint. Without one, a `Container` with no explicit `width` simply wraps to its child's intrinsic size.

```
_SectionCard → Column → _SettingsRow → Row → Expanded ← forces full width ✓
Custom Container → Column → Text/CircleAvatar ← no expansion → shrinks to content ✗
```

#### Fix Applied

**`lib/src/features/settings/settings_page.dart`**

Added `width: double.infinity` to the profile `Container`:

```dart
Container(
  width: double.infinity, // forces container to fill available width minus margins
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  decoration: BoxDecoration(...),
  child: ...
)
```

#### How We Debugged It

1. Screenshot showed the card was half the screen width
2. Compared profile card code vs `_SectionCard` code side by side
3. Identified that `_SectionCard`'s children had `Expanded` inside `Row` — profile card did not
4. Added `width: double.infinity` — card stretched to match other sections

#### Lesson Learned

> In Flutter, a `Container` without an explicit `width` sizes itself to its child's intrinsic width. If the child has no `Expanded`, `double.infinity`, or tight constraint, the Container shrinks. When replacing a shared card widget with a raw `Container`, always add `width: double.infinity` if you expect it to fill the screen width.

| Widget layout | Fills width? |
|---|---|
| `Container` (no width set, child has `Expanded`) | Yes |
| `Container` (no width set, child is Text/Icon) | No — shrinks to content |
| `Container(width: double.infinity, ...)` | Always yes |

---

### BUG-007 — `AdminAttendancePage` in Wrong Folder, Wrong Import Path

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Low — no runtime crash, but causes confusion during debugging and maintenance

#### Symptom

`admin_attendance_page.dart` lived inside the attendance feature folder:
```
lib/src/features/attendance/presentation/admin/admin_attendance_page.dart
```
But all other admin screens live in:
```
lib/src/features/admin/
```
This meant admin screens were split across two unrelated feature folders, making it harder to find files during debugging.

#### Root Cause

The file was initially scaffolded inside the attendance feature tree (`attendance/presentation/admin/`) rather than the admin feature folder where all other admin pages live (`admin/home/`, `admin/students/`, `admin/staff/`).

#### Fix Applied

Moved the file to:
```
lib/src/features/admin/attendance/admin_attendance_page.dart
```

Updated the import in `teacher_shell.dart`:
```dart
// Before
import 'package:edu_air/src/features/attendance/presentation/admin/admin_attendance_page.dart';

// After
import 'package:edu_air/src/features/admin/attendance/admin_attendance_page.dart';
```

Deleted the old folder: `lib/src/features/attendance/presentation/`

#### How We Debugged It

1. Noticed `admin_attendance_page.dart` was the only admin screen not in `lib/src/features/admin/`
2. Checked with `Grep` — only one file imported it (`teacher_shell.dart`)
3. Wrote file to new location, updated the one import, deleted old folder

#### Lesson Learned

> All screens for a given role should live in the same feature folder. Admin screens belong in `lib/src/features/admin/`. When a file is in the wrong place, finding it during a bug hunt costs time. The rule: **one role, one folder**.

**Admin folder structure (correct):**
```
lib/src/features/admin/
├── home/         admin_home_screen.dart
├── students/     admin_student_list_page.dart, admin_student_edit_page.dart
├── staff/        admin_staff_list_page.dart
└── attendance/   admin_attendance_page.dart   ← moved here
```

---

## 4. Common Flutter / Firebase Error Reference

| Error | Meaning | Fix |
|---|---|---|
| `PlatformException: sign_in_canceled` | User cancelled Google Sign-In | Return null silently — not an error |
| `FirebaseAuthException: user-not-found` | Email not in Firebase Auth | Show "No account found" message |
| `FirebaseAuthException: wrong-password` | Wrong password | Show "Incorrect password" message |
| `FirebaseAuthException: network-request-failed` | No internet | Show "Check your connection" message |
| `setState() called after dispose()` | Widget unmounted before async finished | Add `if (mounted)` check before every `setState()` |
| `Null check operator used on null value` | Used `!` on a null value | Check for null before accessing, use `?.` |
| `MissingPluginException` | Native plugin not linked | Run `flutter clean && flutter pub get && pod install` |
| `ImpellerValidationBreak` | Impeller graphics warning | Ignore — not a real error |

---

*Last updated: March 2026*
*Maintained by: EduAir dev team*
