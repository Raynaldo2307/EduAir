# EduAir — Debugging Playbook

> One rule: `SYMPTOM → REPRODUCE → ISOLATE → ROOT CAUSE → FIX → VERIFY`
> Read the actual error first. Never guess and change code.

---

## Quick Debug Checklist

| Step | Action |
|------|--------|
| 1 | What is the **exact** error message? |
| 2 | What **file + line** did it crash on? |
| 3 | What did the user do **right before** the crash? |
| 4 | Is the **server running**? (`npm run dev`) |
| 5 | Is the **port correct**? (`3000` in `.env` and `api_client.dart`) |

---

## Bug Log

---

### BUG-001 — Google Sign-In Cancel Crash
**Symptom:** App crashes when user taps Cancel on the Google Sign-In sheet.
**Root Cause:** `signInWithGoogle()` threw `PlatformException(sign_in_canceled)` — not caught.
**Fix:** Catch `PlatformException` with code `sign_in_canceled` / `-5` and return `null` silently. Add `if (user == null) return;` after the call.
**Rule:** Handle both `null` returns AND `PlatformException` for any cancellable third-party auth flow.

---

### BUG-002 — Login Succeeds But App Goes to Wrong Screen
**Symptom:** After login, app navigates to `/onboarding` or `/selectRole` instead of the correct home screen.
**Root Cause:** `startupRouteProvider` (`FutureProvider`) cached its result from app launch and didn't re-run after login.
**Fix:** Removed `startupRouteProvider` from the login flow. Added `_routeForRole(role, schoolId)` helper in `sign_in_form.dart` and navigated directly.
**Rule:** `startupRouteProvider` is for app launch only. After login you already have the user — navigate directly, don't re-run the startup check.

---

### BUG-003 — All Login Errors Show "Invalid Email or Password"
**Symptom:** Network errors, 500s, and wrong credentials all showed the same message.
**Root Cause:** Single `catch` block with a hardcoded message. Also wrong API port (`3500` instead of `3000`).
**Fix:** Created `AppErrorHandler` to map `DioException` types and status codes to specific messages. Fixed port to `3000` in `api_client.dart`.
**Rule:** Log the real error with `dev.log` in every catch. Keep port/base URL in ONE place (`api_client.dart`).

---

### BUG-004 — Students & Attendance Show "Could not load"
**Symptom:** Admin screens showed error state immediately after loading.
**Root Cause:** Flutter code did `response.data` but the Node API wraps lists as `{ message, count, data: [...] }`.
**Fix:** Changed all list parsers to `response.data['data']`.
**Rule:** Always check the actual JSON in Postman before writing the parse code. All list endpoints use `response.data['data']`.

---

### BUG-005 — Stray `],` Causes Cascading Syntax Errors
**Symptom:** 10+ "unused variable" and "undefined" errors after a widget refactor. Nothing looked wrong at the error lines.
**Root Cause:** A leftover `],` from the old widget left a bracket mismatch above the first error line.
**Fix:** Read upward from the first error line — found and removed the stray bracket.
**Rule:** Cascading errors after a refactor = bracket mismatch. Read UP from the first error, not at it.

---

### BUG-006 — Container Shrinks to Content Width
**Symptom:** A full-width card widget was only as wide as its text content.
**Root Cause:** `Container` without explicit `width` shrinks to its child's intrinsic width.
**Fix:** Added `width: double.infinity` to the Container.
**Rule:** Always add `width: double.infinity` when you expect a Container to fill the screen width.

---

### BUG-007 — `AdminAttendancePage` Wrong Folder / Import Path
**Symptom:** Import not found at runtime after creating the file.
**Root Cause:** File was placed in `teacher/` folder instead of `admin/`.
**Fix:** Moved file to `lib/src/features/admin/attendance/`.
**Rule:** One role = one folder. Admin screens in `admin/`, teacher screens in `Teacher/` or `teacher/`.

---

### BUG-008 — `Framework 'Pods_Runner' not found`
**Symptom:** iOS build fails with `Framework 'Pods_Runner' not found`.
**Root Cause:** `ios/Pods/` directory missing — CocoaPods not initialised.
**Fix:** `cd ios && pod install`
**Rule:** Missing Pods = run `pod install`. Same as `npm install` for Node. Only needed after fresh clone or adding native plugins.

---

### BUG-009 — `requireRole is not defined` Crashes Login
**Symptom:** Every login attempt crashes the Node server with `ReferenceError: requireRole is not defined`.
**Root Cause:** `requireRole` middleware was called inside a service file — never imported.
**Fix:** Moved middleware call to the route file where it belongs.
**Rule:** Middleware lives in route files only. Service files contain business logic — they never call middleware.

---

### BUG-010 — Student Home Had Fake 2024 Dates / Grid Overflow
**Symptom:** Upcoming events showed Nov 2024. GridView items overflowed.
**Root Cause:** Hardcoded demo data from a UI template. Wrong `childAspectRatio` on GridView.
**Fix:** Updated to current dates. Decreased `childAspectRatio` to give items more height.
**Rule:** Before any demo, search `grep -r "2024" lib/` and remove stale dates. If grid items overflow → decrease `childAspectRatio`.

---

### BUG-011 — Hero Card Overflows by 5px
**Symptom:** `BOTTOM OVERFLOWED BY 5 PIXELS` on the hero card strip.
**Root Cause:** Fixed card height didn't account for Flutter's button tap target padding.
**Fix:** Increased the fixed card height by 8px.
**Rule:** When you see overflow on a fixed-height container, increase the height. Don't use `ClipRect` to hide overflow.

---

### BUG-012 — `permission-denied` from Firestore on Admin Login
**Symptom:** Admin login threw `PlatformException(permission-denied)` from a Firestore provider.
**Root Cause:** A non-autoDispose `FutureProvider` was watching `userProvider` and re-ran when any user logged in — including admins who have no Firestore permission.
**Fix:** Changed to `FutureProvider.autoDispose`. Migrated admin data to Node API (not Firestore).
**Rule:** Use `autoDispose` for any user-scoped provider. Don't mix Firestore + Node API for the same data. In this project: Firestore = Google Sign In + FCM only.

---

### BUG-013a — Greeting Header Always Shows "Good Morning"
**Symptom:** Header showed "Good Morning" at 3pm.
**Root Cause:** Hardcoded string from a UI template.
**Fix:** Derived greeting from `DateTime.now().hour` in `AppGreetingHeader`.
**Rule:** Never hardcode time-sensitive strings. Shared widgets like greeting headers belong in `lib/src/shared/widgets/`.

---

### BUG-013b — `BottomNavigationBar` Assertion Crash on Role Switch
**Symptom:** App crashed with assertion error when navigating after role switch.
**Root Cause:** `ref.listen` fired a navigation side-effect during a build frame — too late to protect the widget.
**Fix:** Moved the role guard to a synchronous check inside `build()` itself.
**Rule:** `ref.listen` is for post-build side effects. Guards that must hold within a build frame go directly inside `build()`.

---

### BUG-014 — Login 401 Shown as Debug Overlay, Not UI Error
**Symptom:** A failed login showed Flutter's red debug overlay instead of an error message in the form.
**Root Cause:** Exception was not caught — it propagated to Flutter's error handler. Also: error was shown in a SnackBar (easy to miss).
**Fix:** Wrapped login call in `try/catch`. Replaced SnackBar with an inline error banner above the form fields. Banner clears on `onChanged`.
**Rule:** Login errors go inline on the form, not in a SnackBar. In debug mode, caught exceptions still show in the debug overlay — that's normal, not a sign the handling is broken.

---

### BUG-015 — Shift UI Showed All Options Regardless of School Type
**Symptom:** Non-shift schools saw morning/afternoon/whole-day dropdowns.
**Root Cause:** `GET /api/auth/me` didn't return `isShiftSchool` — client had to guess.
**Fix:** Added `LEFT JOIN schools` to the `/me` endpoint to return `isShiftSchool` and `defaultShiftType`. Client hides shift UI when `isShiftSchool == false`.
**Rule:** Auth endpoints should return everything the UI needs to render. One JOIN is cheaper than a second API round-trip.

---

### BUG-016 — Smart Quotes Cause `illegal_character` Compile Error
**Symptom:** `illegal_character` compile error on a line that looks correct.
**Root Cause:** Copy-pasted text contained curly/smart quotes (`"` `"`) instead of straight quotes (`"`).
**Fix:** Replaced smart quotes with straight quotes in the Dart string.
**Rule:** Never paste from Word, Notion, or any rich-text editor into Dart code. Smart quotes are invisible culprits.

---

### BUG-017 — Hardcoded Colors Break Dark Mode (Calendar & Attendance)
**Symptom:** Calendar and attendance widgets had white/light backgrounds in dark mode — unreadable.
**Root Cause:** `Color(0xFFFFFFFF)`, `Colors.white`, `Colors.black`, `Colors.grey` hardcoded throughout widgets.
**Fix:** Replaced with `Theme.of(context).colorScheme.surface / onSurface / surfaceContainerHighest`.
**Rule:** Never hardcode white/black/grey in widgets. Always use `colorScheme` tokens. `AppTheme.X` static colors are light-mode only — don't use them in widget trees.

---

### BUG-018 — `InkWell` Crash: "No Material widget found"
**Symptom:** Red screen — `_InkResponseStateWidget requires a Material widget ancestor`.
**Root Cause:** `InkWell` was used without a `Material` ancestor (inside a plain `Container`).
**Fix:** Wrapped each `InkWell` in `Material(color: Colors.transparent, child: InkWell(...))`.
**Rule:** `InkWell` always needs a `Material` ancestor for the ripple to render.

---

### BUG-019 — Role Badge Always Blue in Settings Page
**Symptom:** Teacher badge showed blue instead of green. All roles looked identical.
**Root Cause:** Badge used `AppTheme.primaryColor` (blue) for every role.
**Fix:** Added a role-to-color map in `SettingsPage`: `student→blue`, `teacher→green`, `admin→purple`, `principal→orange`.
**Rule:** Role-aware UI needs a switch/map — not a single static color.

---

### BUG-020 — 401 Crash When Switching Users (Teacher → Student)
**Symptom:** Logging in as a student after a teacher session caused immediate 401 on all API calls.
**Root Cause:** `pushReplacementNamed` only removed one route — the old `TeacherShell` stayed mounted, its providers re-fired with the new JWT, and role-gated endpoints rejected the student token.
**Fix:** Changed to `pushNamedAndRemoveUntil(route, (r) => false)` to clear the entire navigation stack on login/logout.
**Rule:** Any session transition (login, logout, role switch) must use `pushNamedAndRemoveUntil(..., (r) => false)`. Never use `pushReplacementNamed` for session changes.

---

### BUG-021 — AssertionError: Early/Late Record Missing `clockInAt`
**Symptom:** App crashed on student login when a teacher-marked attendance record had `status = early/late` but `clockInAt = null`.
**Root Cause:** `AttendanceDay` asserted that `early`/`late` records must have `clockInAt`. Teacher-marked records set status without a clock-in timestamp.
**Fix:** Added defensive normalization — if `clockInAt == null` and status is `early`/`late`, downgrade status to `present`.
**Rule:** Teacher-marked records have `status` set but no `clockInAt`. Always handle `clockInAt == null` defensively before asserting on status.

---

### BUG-022 — `ProviderScope(parent:)` Deprecation Warning in Bottom Sheet
**Symptom:** `'parent' is deprecated and shouldn't be used. Will be removed in 3.0.0` warning on `showModalBottomSheet`.
**Root Cause:** `ProviderScope(parent: ProviderScope.containerOf(context))` was the old way to attach a bottom sheet to the parent container. Removed in Riverpod 3.0.
**Fix:** Replace with `UncontrolledProviderScope(container: ProviderScope.containerOf(context), child: ...)`.
**Rule:** Any `showModalBottomSheet` that needs providers from the parent scope must use `UncontrolledProviderScope`, not `ProviderScope(parent:)`.

---

### BUG-023 — Card Tiles Invisible Against Page Background in Light Mode
**Symptom:** List tiles look like plain text rows — no card shape, no depth, no separation.
**Root Cause:** `Material(elevation: 1)` barely renders a shadow at low elevation on a white background. The tile colour and the page background are identical (`AppTheme.white`).
**Fix:** Replaced `Material(elevation: 1)` with `Container(decoration: BoxDecoration(color: ..., borderRadius: ..., boxShadow: [BoxShadow(color: black.06, blurRadius: 8, offset: Offset(0, 2))]))`.
**Rule:** For card tiles, always use explicit `BoxDecoration` + `boxShadow`. Never rely on `Material(elevation:)` — it is unreliable at low values. Adjust `alpha` for dark mode (`0.06` light / `0.2` dark).

---

### BUG-024 — Duplicate Avatar Palette Across Every Tile Widget
**Symptom:** Staff tile, student tile, attendance tile, and home screen each had their own copy of `static const _bgColors` / `_iconColors` with slightly different values — colour inconsistency across screens.
**Root Cause:** No shared avatar widget. Each developer copy-pasted the palette.
**Fix:** Replaced all inline `CircleAvatar` + palette logic with the shared `UserAvatar` widget (`lib/src/shared/widgets/user_avatar.dart`). It uses a deterministic hash (not just first letter) so the same person always gets the same colour.
**Rule:** Never write `CircleAvatar` + a colour palette inline. Always use `UserAvatar(initials: ..., photoUrl: ..., radius: ...)`. It handles photo fallback, dark mode, and consistent colour hashing in one place.

---

## Common Error Quick-Reference

| Error | Most Likely Cause | Fix |
|-------|------------------|-----|
| `401 Unauthorized` | Wrong JWT or stale shell still mounted | Check token; use `pushNamedAndRemoveUntil` on login |
| `connection refused` | Server not running | `npm run dev` in `eduair_api/` |
| `permission-denied` (Firestore) | Non-autoDispose provider re-ran for wrong role | Use `autoDispose`; migrate to Node API |
| `BOTTOM OVERFLOWED BY X px` | Fixed-height container too small | Increase height; check button tap targets |
| `No Material widget found` | `InkWell` without `Material` ancestor | Wrap in `Material(color: Colors.transparent)` |
| `illegal_character` | Smart/curly quotes in Dart string | Replace `"` `"` with `"` |
| `pod install` needed | `Pods_Runner` not found on iOS | `cd ios && pod install` |
| Cascading undefined errors | Bracket mismatch after refactor | Read upward from first error line |
| Dark mode looks broken | Hardcoded `Colors.white` / `AppTheme.X` | Use `colorScheme.surface` / `onSurface` |
| API list returns empty | Parsing `response.data` not `response.data['data']` | Use `response.data['data']` for all list endpoints |
| Tile invisible in light mode | `Material(elevation:1)` on white bg | Use `Container` + explicit `boxShadow` |
| `ProviderScope parent deprecated` | Old Riverpod API in bottom sheet | Use `UncontrolledProviderScope(container: ...)` |
| Inconsistent avatar colours | Inline palette per widget | Use shared `UserAvatar` widget from `shared/widgets/` |
