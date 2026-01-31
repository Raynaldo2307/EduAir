# CLAUDE.md — EduAir Developer Guide

> Senior dev context for Claude Code. Treat this as the single source of truth for architecture, patterns, and conventions.

---

## 1. Project Overview

**EduAir** is a multi-tenant school management app for Jamaican schools. Current focus: **attendance tracking with geofencing**.

| Layer | Tech |
|-------|------|
| Client | Flutter 3.9.2+ |
| State | Riverpod |
| Backend | Firebase (Auth, Firestore, Storage) |
| Location | Geolocator |
| Timezone | `America/Jamaica` |

**User Roles:** `student`, `teacher`, `parent`, `admin`, `principal`

**Multi-Tenancy:** All data scoped by `schoolId`. Users select school after auth via `/selectSchool`.

---

## 2. Directory Structure

```
lib/
├── main.dart                     # Entry point, ProviderScope
├── firebase_options.dart         # Auto-generated Firebase config
└── src/
    ├── core/
    │   ├── app_providers.dart    # Global Riverpod providers
    │   ├── app_theme.dart        # Theme tokens & colors
    │   └── app_module.dart       # Feature module registry
    ├── models/
    │   ├── app_user.dart         # Central user model
    │   └── school/               # School domain model
    ├── services/
    │   └── user_services.dart    # UserService (CRUD for users)
    ├── shared/
    │   └── app_router.dart       # Named route config
    └── features/
        ├── auth/                 # Sign in/up flows
        ├── attendance/           # Student attendance (main feature)
        │   ├── data/             # Repository + Firestore source
        │   ├── domain/           # Service, models, exceptions
        │   ├── application/      # Riverpod controllers
        │   ├── presentation/     # UI pages (student/, admin/)
        │   └── widgets/          # Reusable attendance widgets
        ├── admin/
        │   └── students/         # Admin student management
        ├── Teacher/              # ⚠️ Capital T - teacher attendance
        ├── teacher/              # ⚠️ Lowercase - other teacher features
        ├── student/              # Student profile, etc.
        ├── shell/                # Role/school selection, main shells
        ├── onboard_page/
        └── splash_page/
```

> **Warning:** Two teacher folders exist (`Teacher/` and `teacher/`). This is a filesystem artifact. Be careful when adding teacher features.

---

## 3. Architecture Patterns

### 3.1 Feature Structure

Every feature follows this layered architecture:

```
feature/
├── data/           # Firestore sources, repositories
├── domain/         # Business logic, services, models, exceptions
├── application/    # Riverpod controllers (StateNotifier/AsyncNotifier)
├── presentation/   # UI pages organized by role
└── widgets/        # Feature-specific reusable widgets
```

**Rule:** UI never talks to Firestore directly. Always: `UI → Controller → Service → Repository → Firestore`

### 3.2 State Management (Riverpod)

Global providers live in `app_providers.dart`:

```dart
// Current user (set after auth)
final userProvider = StateProvider<AppUser?>((ref) => null);

// Services (singletons)
final userServiceProvider = Provider<UserService>((ref) => UserService());
final attendanceServiceProvider = Provider<AttendanceService>((ref) => ...);
final attendanceGeoServiceProvider = Provider<AttendanceGeoService>((ref) => ...);

// Current school config
final currentSchoolProvider = Provider<School>((ref) => ...);
```

Feature-specific controllers go in `application/` folders:

```dart
// Example: StudentAttendanceController
final studentAttendanceControllerProvider =
    StateNotifierProvider<StudentAttendanceController, StudentAttendanceState>(...);
```

### 3.3 Routing

Named routes in `app_router.dart`:

| Route | Destination |
|-------|-------------|
| `/` | SplashPage |
| `/onboarding` | OnboardingPage |
| `/signin`, `/signup` | Auth pages |
| `/selectRole` | Role selection (after auth) |
| `/selectSchool` | School selection (after role) |
| `/studentHome` | StudentShell |
| `/teacherHome` | TeacherShell (also used by admin/principal) |
| `/adminStudents` | Admin student management |

**Startup flow:** `startupRouteProvider` in `app_providers.dart` determines initial route based on user state.

---

## 4. Attendance System (Core Feature)

### 4.1 Jamaican Shift System

Many Jamaican schools operate shifts. **Each shift is legally a separate school day.**

| Shift | Start | End | Overtime |
|-------|-------|-----|----------|
| `morning` | 7:00 AM | 12:00 PM | 12:30 PM |
| `afternoon` | 12:00 PM | 5:00 PM | 5:30 PM |
| `whole_day` | 8:00 AM | 4:00 PM | 4:30 PM |

**Grace period:** 30 minutes after start time.

### 4.2 Data Model

**Firestore path:** `schools/{schoolId}/attendance/{dateKey}_{shiftType}_{studentUid}`

**AttendanceDay fields:**
- `dateKey` — "YYYY-MM-DD" in school timezone
- `studentUid`, `schoolId`, `classId`, `className`, `gradeLevel`, `sex`
- `status` — `early`, `late`, `present`, `absent`, `excused`
- `shiftType` — `morning`, `afternoon`, `whole_day`
- `clockInAt`, `clockOutAt`, `clockInLocation`, `clockOutLocation`
- `lateReason` — MoEYI category code
- `isEarlyLeave`, `isOvertime`
- Audit: `takenByUid`, `takenAt`, `updatedAt`

### 4.3 MoEYI Late Reason Categories

Required for government reporting (Form SF4). **No free-text allowed.**

```dart
enum MoEYILateReason {
  transportation,  // Taxi/bus/traffic issues
  economic,        // Can't afford transport/lunch
  illness,         // Student sick
  emergency,       // Family emergency
  family,          // Family obligation
  other,           // Catch-all (use sparingly)
}
```

### 4.4 Domain Exceptions

All attendance errors use typed exceptions (in `attendance_exceptions.dart`):

| Exception | When |
|-----------|------|
| `NotSchoolDayException` | Weekend or holiday |
| `AlreadyClockedInException` | Already clocked in for this shift |
| `AlreadyClockedOutException` | Already clocked out |
| `NoClockInFoundException` | Trying to clock out without clock-in |
| `LateReasonRequiredException` | Late without selecting a reason |
| `InvalidLateReasonException` | Reason not in MoEYI categories |
| `AttendancePersistenceException` | Firestore write failed |

**Error mapping:** Use `mapAttendanceErrorToMessage(error)` from `attendance_error_mapper.dart` to convert to user-friendly strings.

### 4.5 Key Invariants

1. **Historical integrity:** Once written, a record's `shiftType` and `status` are frozen. Never recompute old records when a student changes shift.

2. **Idempotency:** `clockIn()` returns existing record if already clocked in. No duplicate writes.

3. **Shift from profile:** `AttendanceService` reads `AppUser.currentShift` to determine which shift document to create.

4. **No Firestore in UI:** All persistence goes through `AttendanceService → AttendanceRepository`.

---

## 5. Key Models

### AppUser (`lib/src/models/app_user.dart`)

```dart
// Core
uid, firstName, lastName, email, phone, role, schoolId

// Student fields
studentId, gradeLevel, classId, className, sex, dateOfBirth, currentShift

// Teacher fields
teacherDepartment, homeroomClassId, homeroomClassName, subjectAssignments[]

// Parent fields
childrenIds[]

// Profile
parentGuardianName, parentGuardianPhone, address, bio, photoUrl
```

**Helpers:** `displayName`, `initials`, `gradeLevelNumber`, `fromMap()`, `toMap()`, `copyWith()`

### School (`lib/src/models/school/domain/school.dart`)

```dart
id, name, lat, lng, radiusMeters, timezone
```

---

## 6. Services

### UserService (`lib/src/services/user_services.dart`)

```dart
createUser(AppUser user)
getUser(String uid) → Future<AppUser?>
updateUser(AppUser user)
updateUserRole(String uid, String role)
updateUserSchoolId({uid, schoolId})
getStudentsBySchool(String schoolId) → Future<List<AppUser>>
getStaffBySchool(String schoolId) → Future<List<AppUser>>
watchUser(String uid) → Stream<AppUser?>
```

### AttendanceService (`lib/src/features/attendance/domain/attendance_service.dart`)

```dart
// Time
schoolNow() → DateTime
isSchoolDay(DateTime day) → bool
todayDateKey() → String

// Student self-service
clockIn({schoolId, studentUid, location, lateReason?, ...}) → Future<AttendanceDay>
clockOut({schoolId, studentUid, location, ...}) → Future<AttendanceDay>

// Queries
getToday({schoolId, studentUid, shiftType?}) → Future<AttendanceDay?>
getRecentDays({schoolId, studentUid, limit, shiftType?}) → Future<List<AttendanceDay>>
```

### AttendanceGeoService (`lib/src/features/attendance/domain/attendance_geo_service.dart`)

```dart
isUserOnCampus(School school) → Future<bool>
currentAttendanceLocation() → Future<AttendanceLocation>
```

Throws: `LocationServiceDisabledException`, `PermissionDeniedException`, `MockLocationsException`

---

## 7. Controllers (Application Layer)

### StudentAttendanceController

**File:** `lib/src/features/attendance/application/student_attendance_controller.dart`

```dart
// State
StudentAttendanceState {
  AsyncValue<AttendanceDay?> today;
  String? lastErrorMessage;
}

// Methods
refreshToday()
clockIn({location, lateReasonCode}) → Future<String?> // Returns error message or null
clockOut({location}) → Future<String?>
clearError()
```

### StudentAttendanceHistoryController

**File:** `lib/src/features/attendance/application/student_attendance_history_controller.dart`

```dart
// State
StudentAttendanceHistoryState {
  AsyncValue<List<AttendanceDay>> days;
  String? lastErrorMessage;
}

// Methods
loadRecent({limit = 14, shiftType?})
refresh()
```

### Late Reason Provider

**File:** `lib/src/features/attendance/application/late_reason_provider.dart`

```dart
final lateReasonOptionsProvider = Provider<List<LateReasonOption>>(...);
// Returns list of {code, label} for dropdown
```

---

## 8. Code Conventions

### Style
- Follow `flutter_lints` rules
- Trailing commas for better diffs
- Prefer `const` constructors
- No emojis in code unless user requests

### Architecture Rules
- Business logic in `domain/` — no UI code
- Controllers in `application/` — no Firestore imports
- UI in `presentation/` — thin, delegates to controllers
- Services throw domain exceptions, controllers catch and map to messages

### Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Providers: `camelCaseProvider`
- Private helpers: `_privateMethod()`

---

## 9. Commands

```bash
# Run
flutter run

# Build
flutter build apk
flutter build appbundle
flutter build ios

# Analyze
flutter analyze

# Test
flutter test
```

---

## 10. Firebase

**Project ID:** `pocketpal-661d6`

**Collections:**
```
users/{uid}                                    # AppUser profiles
schools/{schoolId}                             # School config
schools/{schoolId}/attendance/{docId}          # Attendance records
schools/{schoolId}/attendance/{docId}/history  # Audit trail
schools/{schoolId}/incidents/{incidentId}      # Geofence incidents
```

**Timestamps:** Data layer uses `FieldValue.serverTimestamp()` for `takenAt`, `updatedAt`.

---

## 11. TODOs / Known Issues

- [ ] **NTP/Server Time:** Currently using `DateTime.now()`. Should use server time for DPA 2020 compliance.
- [ ] **Two teacher folders:** Filesystem artifact. Consider consolidating.
- [ ] **Test coverage:** Minimal. Need unit tests for services and controllers.
- [ ] **Admin shell:** Currently uses TeacherShell with role check. Consider dedicated AdminShell.

---

## 12. Quick Reference

### Adding a New Feature

1. Create folder in `lib/src/features/{feature_name}/`
2. Add subfolders: `data/`, `domain/`, `application/`, `presentation/`, `widgets/`
3. Add route in `app_router.dart`
4. Add providers in `app_providers.dart` or feature-local file
5. Update `app_module.dart` if it's a top-level module

### Adding a New Attendance Status Check

1. Add exception class in `attendance_exceptions.dart`
2. Throw from `AttendanceService` method
3. Add case in `attendance_error_mapper.dart`
4. UI will automatically get user-friendly message

### Editing Student Data (Admin)

1. `AdminStudentListPage` lists students via `UserService.getStudentsBySchool()`
2. Tap opens `AdminStudentEditPage` with form
3. Save calls `UserService.updateUser()`
4. Role check: only `admin` or `principal` see edit UI

---
*Last updated: January 2026*


