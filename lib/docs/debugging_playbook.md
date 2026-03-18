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

### BUG-008 — `Framework 'Pods_Runner' not found` — CocoaPods Out of Sync

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** High — app cannot build or run on iPhone at all

#### Symptom

Running `flutter run` on an iPhone (wired or wireless) fails with:

```
Error (Xcode): Framework 'Pods_Runner' not found
Linker command failed with exit code 1
```

The build stops at the Xcode linking stage. The app never installs on the device.

#### Root Cause

The `ios/Pods/` folder was missing or out of sync. CocoaPods downloads and builds all native iOS frameworks (Firebase, Geolocator, GoogleSignIn, etc.) into the `Pods/` folder. Xcode links them into the final app binary via a combined framework called `Pods_Runner`.

When `Pods/` is absent or stale, the linker cannot find `Pods_Runner` and the build fails.

This happens when:
- The project is cloned on a new machine (`Pods/` is in `.gitignore` — not committed)
- `flutter clean` was run (wipes build artifacts including pod links)
- A new Flutter plugin with native iOS code was added to `pubspec.yaml`
- CocoaPods was not installed on the machine

#### Fix Applied

```bash
cd ios && pod install
```

Output confirming fix:
```
Pod installation complete! There are 9 dependencies from the Podfile and 34 total pods installed.
```

Then ran `flutter run` normally — app launched successfully.

#### How We Debugged It

1. Ran `flutter run -d <device-id>` — build failed after "Running Xcode build..."
2. Read the error: `Framework 'Pods_Runner' not found` — clear CocoaPods issue
3. Ran `cd ios && pod install` — pods reinstalled in ~30 seconds
4. Ran `flutter run` again — built and launched on iPhone

#### Lesson Learned

> `Pods_Runner not found` always means `pod install` is needed. Think of it like `npm install` — if `node_modules/` is missing, you run `npm install`. If `ios/Pods/` is missing, you run `pod install`. You only need to do this once unless you add new native plugins, clean the project, or clone it fresh.

**The rule:** `MissingPluginException` or `Pods_Runner not found` → run `flutter clean && flutter pub get && cd ios && pod install`

---

### BUG-009 — `requireRole is not defined` Crashes Every Login Attempt

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Critical — login completely broken, no user could sign in

#### Symptom

Backend running fine. Flutter app shows "Login failed. Please try again." on every login attempt.

Server terminal shows:
```
❌ Unexpected error: ReferenceError: requireRole is not defined
    at Object.login (/src/features/auth/authService.js:43:3)
    at async exports.login (/src/features/auth/authController.js:5:20)
```

#### Root Cause

A study note about the register route was accidentally left as live code inside the `login()` function in `authService.js`.

```js
// 4) Sign JWT — payload matches what auth.middleware expects
//  Admin must be logged in (route is protected by authenticate +

requireRole('admin', 'principal')   // ← STRAY LINE — not imported, not valid here
const token = jwt.sign(...)
```

`requireRole` is a middleware function. It lives in `middleware/role.middleware.js` and belongs in route files only. It was never imported into `authService.js`. JavaScript threw `ReferenceError` every time `login()` was called, before the JWT was ever signed.

#### Fix Applied

**`src/features/auth/authService.js`**

Deleted the stray `requireRole('admin', 'principal')` call and the incomplete comment above it. The `login()` function is a PUBLIC endpoint — it requires no role check. Role checks only protect routes that require a logged-in user.

#### How We Debugged It

1. Tried to login on Flutter app — snackbar showed "Login failed"
2. Read server terminal — saw `ReferenceError: requireRole is not defined`
3. Opened `authService.js`, searched line 43
4. Found `requireRole('admin', 'principal')` sitting inside `login()` with no import
5. Deleted the line — login worked immediately

#### Lesson Learned

> `requireRole` is middleware. Middleware belongs in route files, not service files. Service files contain business logic only — they never call middleware functions. If you see a `ReferenceError` on a function name that exists somewhere else in the project, check if it was accidentally placed in the wrong file without being imported.

**The rule:**
```
routes/auth.routes.js     ← requireRole goes HERE
features/auth/authService.js ← business logic ONLY, no middleware
```

---

### BUG-010 — Student Home: Fake 2024 Events, Wrong Hero Cards, Grid Overflow

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Medium — app works but looks unprofessional and shows wrong content

#### Symptom

Three separate issues visible on the student home screen:

1. **Upcoming Events shows 2024 dates** — "Inter-school football match Nov 22, 2024", "Science project fair Dec 1, 2024", "Parent teacher meeting Dec 5, 2024". These are not real school events. Dates are over a year in the past.

2. **Hero cards show wrong features** — "Check updated homework" and "Join live class at 2:30 PM". EduAir does not have homework or live class features. These were copied from a Flutter starter template.

3. **Dashboard grid overflows** — Red `BOTTOM OVERFLOWED BY 6.1 PIXELS` warning on the quick links grid rows.

#### Root Cause

All three issues came from early development using a Flutter UI starter template:

1. The events were hardcoded `const` demo data in `student_home_page.dart` with 2024 dates — never replaced with real data.
2. The hero cards were also hardcoded template content unrelated to EduAir's actual features.
3. The `QuickLinksGrid` used `childAspectRatio: 0.9` — too tight for 8 items in 2 rows, causing the last row to clip by 6.1px.

#### Fix Applied

**`lib/src/features/student/home/student_home_page.dart`**

- Removed all 3 hardcoded `_demoUpcomingEvents`
- Removed the `UpcomingEventsSection` widget import
- Replaced events section with a clean "No upcoming events" empty state container
- Updated hero card titles to EduAir-relevant content:
  - "Mark your attendance — Clock In"
  - "View attendance history — View Now"

**`lib/src/features/student/home/widgets/quick_links_grid.dart`**

- Changed `childAspectRatio` from `0.9` to `0.85` — gives each grid item slightly more height, eliminates overflow

#### How We Debugged It

1. Logged in as student (tia.clarke@student.jm) and looked at home screen on real iPhone
2. Saw events with 2024 dates — searched `student_home_page.dart` for the data
3. Found hardcoded `_demoUpcomingEvents` const list — confirmed no external API involved
4. Saw overflow warning on screen — traced to `QuickLinksGrid`, adjusted `childAspectRatio`
5. Replaced hero card text with EduAir-relevant content

#### Lesson Learned

> When you build from a Flutter UI starter template, always audit every hardcoded string and list before demo. A date from 2024 in a 2026 demo is a red flag to any examiner. Search the codebase for fake data with: `grep -r "2024" lib/` and replace anything that doesn't belong.

> The rule for `childAspectRatio` in `GridView`: if items overflow, decrease the ratio (give more height). If items have too much empty space, increase it (give less height).

---

### BUG-011 — Hero Card Banner Overflows by 5px on iOS Simulator

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Low — visual only, yellow overflow warning on student home screen

#### Symptom

The student home screen showed a yellow `BOTTOM OVERFLOWED BY 5.0 PIXELS` warning on the hero cards banner (the auto-sliding `InfoCardsRow`).

#### Root Cause

The `_InfoCard` widget inside `info_cards_row.dart` had a hardcoded `height: 155`. The card's padding is `EdgeInsets.all(15)`, leaving `155 - 30 = 125px` of inner space for the Column content. On the iOS simulator at certain font scales, the Column (title text + subtitle + Spacer + ElevatedButton) required 130px — 5px more than the container allowed.

```dart
// info_cards_row.dart — _InfoCard
Container(
  width: double.infinity,
  height: 155,  // ← too short by 5px
  padding: const EdgeInsets.all(15),
  ...
)
```

#### Fix Applied

**`lib/src/features/student/home/widgets/info_cards_row.dart:133`**

```dart
height: 160,  // was 155 — increased to accommodate button + text content
```

#### How We Debugged It

1. Screenshot showed yellow overflow banner on the hero card
2. Read `student_home_page.dart` — overflow was inside `InfoCardsRow`
3. Opened `info_cards_row.dart` — found `height: 155` on `_InfoCard`
4. Bumped to `160` — overflow cleared

#### Lesson Learned

> When you see `BOTTOM OVERFLOWED BY X PIXELS` on a Container with a fixed height, the fix is almost always to increase the height by that exact amount (or a few pixels more). Don't use `ClipRect` to hide the overflow — fix the root size instead. Fixed-height cards need extra space for button tap targets, which Flutter sizes slightly larger than their visual size.

---

### BUG-012 — `PlatformException(permission-denied)` from Firestore on Admin Login

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Critical — every admin login after a student logout crashed the app

#### Symptom

After a student logged out and an admin logged in (via Node.js JWT), the app threw:

```
PlatformException(permission-denied, Missing or insufficient permissions., ...)
```

The crash came from Firestore, even though the admin never navigated to any attendance screen.

#### Root Cause

Three problems stacked together:

1. **Non-autoDispose provider re-fired across user sessions.** `studentRecentAttendanceProvider` was a plain `FutureProvider` (not `autoDispose`). Plain providers live for the entire ProviderScope lifetime. When `userProvider` changed (student → admin), the provider automatically re-ran its body.

2. **Wrong data source.** The provider called `AttendanceFirestoreSource.fetchDaysInRange()` — which requires a live Firebase Auth session. The admin logged in via JWT only (no Firebase Auth), so `FirebaseAuth.instance.currentUser == null`.

3. **Firestore security rules rejected the unauthenticated read.** The call threw `permission-denied` before any screen was visible.

```
Student logout → admin JWT login → userProvider changes
→ studentRecentAttendanceProvider re-fires (not autoDispose)
→ calls Firestore → no Firebase Auth session → permission-denied 💥
```

#### Fix Applied

**Architectural decision:** moved student attendance entirely from Firestore to the Node.js API. Firebase is now used ONLY for Google Sign In and FCM (as intended).

**Files changed:**

1. **`lib/src/features/attendance/data/attendance_api_repository.dart`**
   - Added `getMyToday()` → `GET /api/attendance/today` (JWT-resolved, no studentId needed)
   - Added `getMyHistory()` → `GET /api/attendance/me` (JWT-resolved)

2. **`lib/src/features/attendance/domain/attendance_models.dart`**
   - Added `AttendanceDay.fromApiMap()` factory to convert Node API response → domain model

3. **`lib/src/features/attendance/presentation/student/attendance_providers.dart`**
   - **Completely rewritten** — removed all Firestore imports
   - All three providers are now `FutureProvider.autoDispose` — tied to widget lifecycle
   - `studentTodayRawProvider` → calls `repo.getMyToday()`
   - `studentRecentAttendanceProvider` → calls `repo.getMyHistory()`
   - `studentAttendanceSummaryProvider` → derived from recent history

4. **`lib/src/features/attendance/presentation/student/student_attendance_page.dart`**
   - `_handleClockIn()` — now calls `repo.clockIn(shiftType, lat, lng, lateReasonCode)`
   - `_handleClockOut()` — reads `studentTodayRawProvider` to get MySQL `id`, then calls `repo.clockOut(attendanceId, lat, lng)`
   - Added `_mapApiError()` — maps `DioException` status codes to user-friendly messages
   - Invalidates `studentTodayRawProvider` after each clock action

5. **Node.js backend** (`attendanceRepository.js`, `attendanceService.js`, `attendanceController.js`, `attendanceRoutes.js`)
   - Added `GET /api/attendance/today` — returns logged-in student's today record from JWT
   - Added `GET /api/attendance/me` — returns logged-in student's history from JWT
   - Both routes declared BEFORE `/:id` routes (critical — prevents 'today'/'me' matching as a numeric ID)

#### How We Debugged It

1. Reproduced: logout as student → login as admin → crash immediately
2. Crash pointed to Firestore, but admin never visited an attendance screen
3. Traced `userProvider` watchers — found `studentRecentAttendanceProvider` re-firing on user change
4. Confirmed no Firebase Auth session for JWT-only login → Firestore rejects

#### Lesson Learned

> `FutureProvider` (non-autoDispose) lives for the entire app session. If it watches `userProvider`, it re-runs every time any user logs in or out — including users of completely different roles. Always use `FutureProvider.autoDispose` for user-scoped data so the provider is disposed when its widget tree leaves the screen.

> The real lesson: **pick one backend and stick to it.** Mixing Firestore and a Node API for the same data model (attendance) creates hidden coupling. The rule for this project: Firestore = Google Sign In + FCM only. Everything else = Node.js API → MySQL.

| Provider type | Lifetime | Suitable for |
|---|---|---|
| `FutureProvider` | Entire app | Global config, school settings (user-agnostic) |
| `FutureProvider.autoDispose` | Widget on screen | Per-user data (attendance, profile) |

---

### BUG-013 — Greeting Header Always Shows "Good Morning" Regardless of Time

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Low — visual only, but noticeable and unprofessional during a demo

#### Symptom

The admin home screen (and teacher home screen) showed **"Good Morning, EduAir Admin"** at 2:16 PM and in the evening. The time of day never changed the greeting.

#### Root Cause

The greeting string was hardcoded in `lib/src/features/teacher/home/widgets/greeting.dart`:

```dart
Text(
  'Good Morning, $name',  // ← never changes
  ...
)
```

There was no logic to check `DateTime.now().hour`. Additionally, two separate `GreetingHeader` widgets existed — one for student, one for teacher/admin — causing duplicated code that was harder to maintain:

```
lib/src/features/student/home/widgets/greeting_header.dart  ← student version
lib/src/features/teacher/home/widgets/greeting.dart         ← teacher/admin version (hardcoded)
```

The admin home screen imported the teacher version and passed `teacherDepartment: schoolName` — a workaround that made the widget semantically wrong for an admin context.

#### Fix Applied

**Created:** `lib/src/shared/widgets/app_greeting_header.dart`

One shared widget used across all roles. Greeting is computed at build time from the device clock:

```dart
String get _greeting {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}
```

Widget accepts generic, role-neutral parameters:

```dart
AppGreetingHeader(
  name: name,        // display name — same for all roles
  id: id,            // student ID, staff ID, admin UID, etc.
  subtitle: subtitle, // optional — school name, department, etc.
  avatarUrl: avatarUrl,
  onBellTap: onBellTap,
)
```

**Updated imports in 3 screens:**
- `student_home_page.dart` — `id: studentId`, no subtitle
- `teacher_home_screen.dart` — `id: teacherId`, `subtitle: department`
- `admin_home_screen.dart` — `id: adminId`, `subtitle: schoolName`

**Deleted the two old duplicate widgets:**
- `lib/src/features/student/home/widgets/greeting_header.dart`
- `lib/src/features/teacher/home/widgets/greeting.dart`

#### How We Debugged It

1. Noticed "Good Morning" showing at 2:16 PM on admin home screen
2. Read `teacher/home/widgets/greeting.dart` — found hardcoded string on line 58
3. Checked which screens used each widget — student, teacher, and admin all had their own copy
4. Consolidated into one shared widget with time-based greeting logic
5. Ran `flutter analyze` on all 4 files — no issues

#### Lesson Learned

> Hardcoded greeting strings are a common copy-paste mistake from UI starter templates. Always derive time-sensitive copy from `DateTime.now()`.

> When the same UI concept (greeting card with bell + avatar) appears in multiple roles, it belongs in `lib/src/shared/widgets/` — not duplicated per feature. Duplicated widgets mean a bug in one is silently absent in another.

**Time-of-day greeting logic:**
```
00:00 – 11:59 → Good Morning
12:00 – 16:59 → Good Afternoon
17:00 – 23:59 → Good Evening
```

---

### BUG-013 — `BottomNavigationBar` Assertion Crash on Role Switch

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Critical — app crashes on admin logout and on login after session restore

#### Symptom

Two separate scenarios triggered the same crash:

1. Admin on tab 4 (Settings) taps logout → app crashes immediately
2. App restarts with a saved admin JWT → session restored → app crashes on first render

```
Failed assertion: line 254 pos 15:
'0 <= currentIndex && currentIndex < items.length': is not true.
```

#### Root Cause

`TeacherShell` uses a single `_currentIndex` integer for both admin (5 tabs) and teacher (4 tabs) layouts. When `userProvider` changes — either on logout or on session restore — the nav bar item count changes in the same build frame, but `_currentIndex` is still the old value.

**Scenario 1 — logout from tab 4:**
```
Admin on tab 4 → logout → userProvider = null
→ build() runs: isAdminOrPrincipal = false → 4 items, _currentIndex = 4
→ BottomNavigationBar: 4 < 4 is false → assertion crash
```

**Scenario 2 — first attempted fix using `ref.listen`:**

`ref.listen` callbacks run AFTER the current build completes. So when `userProvider` changes:
```
userProvider changes → Flutter triggers build()
→ build() runs with stale _currentIndex → CRASH
→ ref.listen callback fires → setState (too late)
```
The `ref.listen` fix looked correct but had a race condition — the callback always arrives one frame too late.

#### Fix Applied

**`lib/src/features/shell/teacher_shell.dart`**

Added a synchronous `safeIndex` clamp computed during the build itself, before `BottomNavigationBar` ever receives the index:

```dart
// Clamp index synchronously so the assertion never fires, regardless of
// when userProvider changes relative to this build frame.
final safeIndex = _currentIndex < navItems.length ? _currentIndex : 0;

return Scaffold(
  body: IndexedStack(index: safeIndex, children: pages),
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: safeIndex,   // ← never out of range
    items: navItems,
    ...
  ),
);
```

#### How We Debugged It

1. First fix used `ref.listen` — crash persisted on login/session restore
2. Realised `ref.listen` defers its callback to after the current build frame
3. The crash happens DURING the build — so the callback is always one frame too late
4. Moved the guard into the build itself as a synchronous clamp — crash gone in all scenarios

#### Lesson Learned

> `ref.listen` is for side effects (navigation, showing a dialog, clearing a field) that run AFTER a build. It cannot protect a widget from crashing DURING the build that triggered it. For guards that must hold true within a single build frame, compute them synchronously inside `build()` itself.

| Approach | When it runs | Protects current build? |
|---|---|---|
| `ref.listen` callback | After current build | No |
| Synchronous clamp in `build()` | During current build | Yes |

---

### BUG-014 — Login 401 Shown as Debug Overlay Instead of UI Error

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Medium — wrong credentials showed Flutter's red exception screen in debug mode, looked like a crash

#### Symptom

Typing the wrong password on the login screen caused the Flutter debug exception overlay to appear (red banner, stack trace). The app had not crashed — the exception was caught — but the overlay made it look like one. The actual error message appeared briefly in a SnackBar at the bottom but was easy to miss.

#### Root Cause

Two issues together:

1. **SnackBar is the wrong widget for login errors.** A SnackBar appears at the bottom of the screen, auto-dismisses after 4 seconds, and requires the user to look away from the form. For a login error the user needs to act on (retype credentials), the message must stay visible.

2. **Flutter debug mode shows ALL exceptions in the overlay**, even caught ones. A 401 `DioException` that is caught and handled still triggers the red overlay in debug builds, making it look like a crash to the developer.

#### Fix Applied

**`lib/src/features/auth/sign_in_form.dart`**

Added `String? _errorMessage` state field. On login failure, set the message inline on the form. Clear it when the user starts typing.

```dart
// State
String? _errorMessage;

// In _handleLogin() catch block — replace _showSnack with:
setState(() => _errorMessage = message);

// In build() — inline banner above the email field:
if (_errorMessage != null) ...[
  Container(
    decoration: BoxDecoration(
      color: Color(0xFFFFE9E9),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Color(0xFFE25563)),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
        Text(_errorMessage!),
      ],
    ),
  ),
  SizedBox(height: 16),
],

// Clear on typing:
onChanged: (_) {
  if (_errorMessage != null) setState(() => _errorMessage = null);
}
```

Three cases handled:

| HTTP status | Message shown |
|---|---|
| 401 | "Invalid email or password. Please try again." |
| Connection error | "Cannot reach server. Check your connection and try again." |
| Anything else | "Something went wrong. Please try again." |

#### How We Debugged It

1. Entered wrong password → Flutter debug overlay appeared → looked like crash
2. Read the overlay: `DioException [bad response] 401` — confirmed it IS caught, just displayed badly
3. Identified SnackBar as poor UX for login errors (dismisses, bottom of screen)
4. Replaced with inline `_errorMessage` state → red banner stays on form until user retypes

#### Lesson Learned

> Never use a `SnackBar` for login form errors. The user is looking at the form, not the bottom of the screen. Use inline state (`String? _errorMessage`) to render a persistent error banner directly on the form. Clear it with `onChanged` so it disappears the moment the user starts correcting their input.

> In Flutter debug mode, caught exceptions still appear in the debug overlay. This is expected behaviour — not a sign that your error handling is broken. In release builds, this overlay does not appear.

| Error display | Stays visible | User sees it | Correct for login |
|---|---|---|---|
| `SnackBar` | 4 seconds | Maybe | No |
| Inline `_errorMessage` banner | Until user types | Always | Yes |

---

### BUG-015 — Shift UI Showed All Shift Options Regardless of School Type

**Date:** March 2026
**Status:** Confirmed Fixed ✅
**Severity:** Medium — admin could see morning/afternoon/whole_day options even when school only runs one shift

#### Symptom

An admin from a whole-day school could see morning, afternoon, and whole_day shift options in the UI. A school that only runs a morning shift should only show morning. No filtering was happening.

#### Root Cause

The `getMe()` and `login()` endpoints in `authService.js` only returned user fields — they never joined the `schools` table. So Flutter never received `default_shift_type` or `is_shift_school`. The `AppUser` model had no way to know what shift the school operated.

```js
// BEFORE — no school data
SELECT id, email, first_name, last_name, role, school_id FROM users WHERE id = ?
```

#### Fix Applied

**`src/features/auth/authService.js`** — Both `login()` and `getMe()` updated to LEFT JOIN schools:

```sql
SELECT u.id, u.email, u.first_name, u.last_name, u.role, u.school_id,
       s.default_shift_type, s.is_shift_school
FROM users u
LEFT JOIN schools s ON s.id = u.school_id
WHERE u.id = ?
```

Both now return `defaultShiftType` and `isShiftSchool` in the response.

**`lib/src/models/app_user.dart`** — Added two new fields:
```dart
final String? defaultShiftType;  // 'morning' | 'afternoon' | 'whole_day'
final bool isShiftSchool;        // whether the school runs shifts
```

**`lib/src/core/app_providers.dart`** and **`sign_in_form.dart`** — Both places that construct `AppUser` from the API now map the new fields.

#### Lesson Learned

> Auth endpoints should return all context the client needs to render the UI — not just identity fields. A `getMe()` that only returns `id/email/role` forces the client to make a second API call for school config. A single LEFT JOIN is cheaper than two round trips.

> Use `LEFT JOIN` not `INNER JOIN` when the related table row may not exist (e.g. a super admin with no school). The join returns null for school fields rather than dropping the user row entirely.

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
| `Framework 'Pods_Runner' not found` | CocoaPods out of sync | `cd ios && pod install` |
| `ReferenceError: X is not defined` in Node | Function called without import / placed in wrong file | Remove stray call, check it belongs in that file |
| `BOTTOM OVERFLOWED BY X PIXELS` | GridView/Column child too tall for available space | Decrease `childAspectRatio` or wrap parent in `SingleChildScrollView` |
| `ImpellerValidationBreak` | Impeller graphics warning | Ignore — not a real error |
| `DioException 401` on login | Wrong email or password | Show inline error banner — not a crash |
| `0 <= currentIndex && currentIndex < items.length` | BottomNavigationBar index out of range after role change | Clamp index synchronously in `build()` before passing to widget |

---

### BUG-010 — Status Bar Icons Invisible in Dark Mode

**Date:** March 2026
**File:** `lib/src/features/student/home/student_home_page.dart`

**Symptom:**
On dark mode the scaffold background is deep purple (`#1E1B2E`), but the status bar icons (time, wifi, battery) remained **black** — almost impossible to see.

**Root Cause:**
Flutter does not automatically update the OS status bar icon colour when the theme changes. Without explicit instruction the OS keeps whatever colour it last used. Pages with no `AppBar` (which normally handles this automatically) are the most vulnerable.

**The concept — two overlay styles:**
```
SystemUiOverlayStyle.dark   → dark icons (black)  → use when background is LIGHT
SystemUiOverlayStyle.light  → light icons (white) → use when background is DARK
```
The name is confusing: `.dark` means "dark-coloured icons for a light background". Always think: "what colour does my background need?"

**Fix:**
Wrap the `Scaffold` with `AnnotatedRegion<SystemUiOverlayStyle>`. This tells iOS/Android which icon colour to use for this specific page without needing an AppBar.

```dart
import 'package:flutter/services.dart';

final isDark = Theme.of(context).brightness == Brightness.dark;

return AnnotatedRegion<SystemUiOverlayStyle>(
  value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
  child: Scaffold(...),
);
```

**Why "Upcoming Events" section was unaffected:**
That container uses hardcoded `Color(0xFFF5F7FA)` — a raw hex constant, not `Theme.of(context).colorScheme.surface`. Raw colors never respond to theme changes. Only widgets that read from `Theme.of(context)` update automatically. This is expected for now; fix it later by swapping to `colorScheme.surfaceContainerHighest`.

**Rule going forward:**
Every page with no AppBar that can be viewed in both light and dark mode needs `AnnotatedRegion<SystemUiOverlayStyle>`. Add it the same way you add `SafeArea` — it's standard scaffolding.

---

### BUG-011 — Hardcoded Colors Break Dark Mode (Home Screen)

**Date:** March 2026
**Files:** `app_greeting_header.dart`, `quick_links_grid.dart`, `student_home_page.dart`

**Symptoms:**
- Greeting card stayed white in dark mode (text near-invisible)
- "Dashboard" title was dark blue on a dark purple background
- Quick link labels (Attendance, Exam, Leave…) were dark blue — invisible
- Hero strip stayed mint green instead of switching to dark card
- "Upcoming Events" card stayed bright white on dark background

**Root Cause:**
Every broken element was using a hardcoded `AppTheme.X` color constant instead of a theme-aware `Theme.of(context)` call. Hardcoded colors are static — dark mode has no power over them. The moment you type `color: AppTheme.textPrimary`, you have locked that element to one color forever, regardless of the user's theme setting.

**The two types of color in Flutter:**
```dart
// TYPE 1 — hardcoded. Static. Dark mode can't touch it.
color: AppTheme.textPrimary         // always #0D47A1 dark blue, always

// TYPE 2 — theme-aware. Flutter swaps it automatically on theme change.
color: Theme.of(context).colorScheme.onSurface  // dark blue in light, white in dark
```

**Fixes applied:**

| Element | Was | Fixed to |
|---|---|---|
| Greeting card background | `AppTheme.white` | `isDark ? AppTheme.darkCard : AppTheme.white` |
| Greeting name text | `AppTheme.textPrimary` | `colorScheme.onSurface` |
| Quick link labels | `AppTheme.textPrimary` | `colorScheme.onSurface` |
| "Dashboard" title | `.copyWith(color: AppTheme.textPrimary)` | `.copyWith(color: colorScheme.onSurface)` |
| Hero strip background | `AppTheme.heroStripBackground` | `isDark ? AppTheme.darkCard : AppTheme.heroStripBackground` |
| Upcoming Events card | `Color(0xFFF5F7FA)` | `isDark ? AppTheme.darkCard : Color(0xFFF5F7FA)` |

**Why some text was already correct:**
The "Upcoming Events" title used a raw `TextStyle` with NO color set. No color = Flutter reads from `colorScheme.onSurface` automatically = white in dark mode. It worked by accident. The moment you add `.copyWith(color: AppTheme.textPrimary)` you override and break it.

**Pattern for custom brand colors (backgrounds):**
For colors that are not in Flutter's standard `ColorScheme` slots — like `heroStripBackground` or `darkCard` — use the `isDark` flag pattern:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
color: isDark ? AppTheme.darkCard : AppTheme.heroStripBackground,
```

**Pattern for text and standard elements:**
Use `colorScheme` directly — no `isDark` check needed:
```dart
color: Theme.of(context).colorScheme.onSurface,   // text on any background
color: Theme.of(context).colorScheme.surface,      // page/card background
color: Theme.of(context).colorScheme.primary,      // brand accent
```

**Rule going forward:**
When you add a color to any widget, ask: "Does this need to change in dark mode?"
- Yes → use `Theme.of(context).colorScheme.X` or the `isDark` flag
- No (always brand color, e.g. a logo tint) → hardcode is fine

---

---

### BUG-016 — Smart/Curly Quotes in Dart String Cause `illegal_character` Compile Error

**Date:** March 2026
**File:** `lib/src/features/attendance/widgets/clock_button_row.dart`

**Symptom:**
7 compiler errors on a single line:
```
error • Illegal character '8216' • clock_button_row.dart:76:7
error • Illegal character '8217' • clock_button_row.dart:76:12
error • Illegal character '55356' • clock_button_row.dart:76:34  ← emoji surrogate
error • Undefined name ''You'
error • Expected to find ')'
```

**Root Cause:**
The string `'You're all set for today 🎉'` was written with **Unicode smart/curly quotes** (`'` U+2018 and `'` U+2019) instead of **straight ASCII single quotes** (`'` U+0027). These look nearly identical in most editors but Dart only accepts ASCII quotes as string delimiters.

Character codes that betray curly quotes:
- `8216` = U+2018 LEFT SINGLE QUOTATION MARK `'`
- `8217` = U+2019 RIGHT SINGLE QUOTATION MARK `'`

The emoji `🎉` triggered `illegal_character '55356'` / `'57225'` because once the string delimiters were broken, the emoji's UTF-16 surrogate pairs became bare characters in code.

**How it happens:**
Copy-pasting from Google Docs, Notion, Word, or a chat app. Those tools auto-replace straight quotes with curly ones. Paste into VS Code and the file looks fine visually but the bytes are wrong.

**Fix:**
Replace curly quotes with straight ASCII quotes. The safest fix is to rewrite the file entirely with the Write tool — editors that show curly quotes in the display layer may silently re-introduce them on Edit.

```dart
// WRONG — curly quotes (U+2018 / U+2019), looks fine visually but won't compile
'You're all set for today 🎉'

// RIGHT — straight ASCII apostrophe (U+0027) with escape
'You\'re all set for today'
// OR use double quotes to avoid escaping
"You're all set for today"
```

**Rule going forward:**
Never copy strings from rich-text editors (Docs, Notion, Word) directly into Dart. Always paste into a plain-text intermediary first (terminal, Notes app with rich text off) to strip smart quotes.

---

### BUG-017 — Hardcoded Colors Break Dark Mode (Calendar & Attendance Widgets)

**Date:** March 2026
**Files:**
- `lib/src/features/attendance/presentation/student/widgets/attendance_calendar.dart`
- `lib/src/features/attendance/presentation/student/widgets/timetable_tab.dart`
- `lib/src/features/attendance/presentation/student/widgets/attendance_summary_row.dart`
- `lib/src/features/attendance/widgets/attendance_status_strip.dart`
- `lib/src/features/attendance/widgets/attendance_day_tile.dart`
- `lib/src/features/attendance/widgets/clock_button_row.dart`

**Symptoms in dark mode:**
- Calendar card stayed white (blinding on dark background)
- Month label ("March 2026") and weekday headers (Mon/Tue…) — dark blue text on dark background, invisible
- Current week highlight strip — light mint green on dark background
- Empty-day dots — light grey, invisible on dark background
- Status strip ("Today / Not yet clocked in") — white card, dark text
- History tiles (Sun, Mar 15 · Late) — white card on dark background
- Summary cards (Present 02 / Absent 00) — light pastel stuck in light mode
- Timetable subject names, time values, date header — all dark-on-dark
- "You're all set for today" text — invisible

**Root Cause:**
Same pattern as BUG-011 but across the attendance widget layer. Every broken element used a hardcoded `AppTheme.X` constant instead of reading from `Theme.of(context).colorScheme`.

**Full fix table:**

| Element | Was | Fixed to |
|---|---|---|
| Calendar card background | `AppTheme.surface` | `colorScheme.surface` |
| Calendar card border | `AppTheme.outline` | `colorScheme.outline` |
| Month label | `AppTheme.textPrimary` | `colorScheme.onSurface` |
| Weekday headers | `AppTheme.textPrimary @ 60%` | `colorScheme.onSurface @ 60%` |
| Empty-day dots | `AppTheme.outline @ 40%` | `colorScheme.outline @ 40%` |
| Week highlight strip | `heroStripBackground @ 70%` | `isDark ? darkCard @ 80% : heroStripBackground @ 70%` |
| Status strip background | `AppTheme.surfaceVariant` | `isDark ? darkCard : surfaceVariant` |
| Status strip text | `AppTheme.textPrimary` | `colorScheme.onSurface` |
| Status chip background | `Colors.white` | `colorScheme.surfaceContainerHighest` |
| History tile background | `AppTheme.white` | `isDark ? darkCard : white` |
| History tile date text | `AppTheme.textPrimary` | `colorScheme.onSurface` |
| Summary card backgrounds | Hardcoded pastels | `isDark ? custom dark tones : pastels` |
| Summary count numbers | No explicit color | `colorScheme.onSurface`, `fontSize: 20`, `w800` |
| Timetable date text | `AppTheme.textPrimary` | `colorScheme.onSurface` |
| Timetable subject names | `AppTheme.textPrimary` | `colorScheme.onSurface` |
| Timetable time values | `AppTheme.textPrimary @ 55%` | `colorScheme.onSurface @ 55%` |
| "All set" text | `AppTheme.textPrimary @ 60%` | `colorScheme.onSurface @ 60%` |

**Efficient pattern — assign `cs` once at top of `build()`:**
```dart
final cs = Theme.of(context).colorScheme;
// then use cs.onSurface, cs.surface, cs.outline everywhere
// instead of repeating Theme.of(context) on every line
```

**Rule going forward:**
When building a widget, the first thing to ask after writing it: "Does any color here use `AppTheme.X`?" If yes, and if the element should adapt to dark mode, replace it with `colorScheme.X` or the `isDark` flag. Scan every `color:` line before considering a widget done.

---

*Last updated: March 2026*
*Maintained by: EduAir dev team*
