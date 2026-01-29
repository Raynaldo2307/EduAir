# Attendance Module — EduAir

> **Audience:** Ray (CTO), senior devs, and AI assistants (Claude, ChatGPT)
> **Scope:** Everything related to student / teacher attendance in EduAir.

---

## 0. Vision for Jamaican Schools

EduAir's attendance system is the **core engine** of the platform.
The mission is to give Jamaican schools a **trusted, automation-first attendance layer** that:

- Works reliably even with **poor or intermittent internet** (offline-first, with local storage and sync).
- Makes it **hard for students to cheat** (no easy "log in for my friend and tap Present").
- Feels as seamless and real-time as modern apps (Uber/Google level UX), but tuned to Jamaican schools.
- Produces data clean enough for **MoEYI reporting**, school leadership, and parents.

Every change to this module should respect that mission.

---

## 1. High-Level Goals

EduAir's attendance system is designed to:

- Work for **any Jamaican school** (multi-tenant, multi-school).
- Respect **Jamaican shift schools** (`morning`, `afternoon`, `whole_day`).
- Comply with **MoEYI** reporting and **Data Protection Act (DPA) 2020** principles.
- Be **UX-friendly** (no hard crashes, clear messages, retry flows).
- Stay **cleanly layered**: UI -> Controllers -> Service -> Repository -> Firestore.
- Be **offline-tolerant** *(not yet implemented -- see section 6)*:
  - Support local storage / queueing when the network is weak or down.
  - Sync safely to Firestore when connectivity returns, without corrupting data.
- Be **fraud-resistant** *(partially implemented -- see section 7)*:
  - Make it difficult for one student to clock in on behalf of another.
  - Combine account identity, device checks, geofencing, and teacher workflows.

Whenever you modify this module, you should preserve these goals.

---

## 2. Core Files (Map of the Module)

### Domain & Data (Student Self-Service)

- `lib/src/features/attendance/domain/attendance_models.dart`
  - `AttendanceDay` (one student, one `dateKey`, one `shiftType`).
  - `AttendanceStatus` (`early`, `late`, `present`, `absent`, `excused`).
  - `AttendanceLocation` (lat/lng snapshot).
  - `MoEYILateReason` enum + helpers (codes + labels).

- `lib/src/features/attendance/domain/attendance_exceptions.dart`
  - Domain errors thrown by the service layer:
    - `NotSchoolDayException`
    - `AlreadyClockedInException`
    - `AlreadyClockedOutException`
    - `NoClockInFoundException`
    - `LateReasonRequiredException`
    - `InvalidLateReasonException`
    - `AttendancePersistenceException` (wraps Firestore/platform errors)

- `lib/src/features/attendance/domain/attendance_service.dart`
  - Pure business logic (no Firestore, no UI).
  - Knows:
    - Shift rules (morning/afternoon/whole_day).
    - Lateness and grace period (30 minutes).
    - Early-leave vs overtime.
    - Idempotent clock-in/out.
    - Holiday / weekend blocking.
  - Does **not** know:
    - Widgets, `BuildContext`, SnackBars.
    - Firestore paths.

- `lib/src/features/attendance/data/attendance_repository.dart`
  - Interface between service and Firestore source.
  - Deals with `schoolId`, `studentUid`, `dateKey`, `shiftType`.

- `lib/src/features/attendance/data/attendance_firestore_source.dart`
  - Actual Firestore queries / writes.
  - Paths like:
    `schools/{schoolId}/attendance/{dateKey}_{shiftType}_{studentUid}`
  - All calls wrapped in `try / on FirebaseException / on PlatformException / catch`.
  - Detects missing index errors (`failed-precondition` + "The query requires an index").
  - Logs a **dev-friendly message** with the index creation URL.
  - Throws `AttendancePersistenceException` to keep raw Firebase errors out of upper layers.

### Application (Controllers & Providers)

- `lib/src/features/attendance/application/student_attendance_controller.dart`
  - `StudentAttendanceController` (StateNotifier).
  - Holds `AsyncValue<AttendanceDay?>` for today.
  - Methods: `refreshToday()`, `clockIn()`, `clockOut()`, `clearError()`.
  - Catches all errors, calls `mapAttendanceErrorToMessage`, stores `lastErrorMessage`.

- `lib/src/features/attendance/application/student_attendance_history_controller.dart`
  - Holds `AsyncValue<List<AttendanceDay>>` for recent days.
  - Computes stats: present / absent / late / early.
  - Same error mapping pattern.

- `lib/src/features/attendance/application/late_reason_provider.dart`
  - `LateReasonOption` model.
  - `lateReasonOptionsProvider` for dropdowns.

- `lib/src/features/attendance/application/attendance_error_mapper.dart`
  - `mapAttendanceErrorToMessage(Object error)` -- domain exceptions to human messages.

### Presentation

- `lib/src/features/attendance/presentation/student/student_attendance_page.dart`
  - Student self-service clock-in/out UI.

- `lib/src/features/attendance/presentation/admin/`
  - Admin-facing attendance views.

### Teacher Batch Attendance

- `lib/src/features/teacher/attendance/teacher_attendance_page.dart`
  - Two-tab UI: "Students" tab for roll call, "Teacher" tab for calendar/summary.

- `lib/src/features/teacher/attendance/teacher_attendance_providers.dart`
  - `teacherAttendanceRepositoryProvider`, `teacherClassStudentsProvider`, `teacherAttendanceForDateProvider`.

- `lib/src/features/teacher/attendance/data/teacher_attendance_data_source.dart`
  - `saveAttendanceBatch()` -- atomic Firestore batch write for an entire class.
  - Writes audit trail subcollection in the same batch (see section 6A).

- `lib/src/features/teacher/attendance/data/teacher_attendance_repository.dart`
  - Facade delegating to the data source.

- `lib/src/features/teacher/attendance/domain/teacher_attendance_models.dart`
  - `TeacherAttendanceEntry`, `TeacherAttendanceStudent`, `TeacherClassOption`.
  - `AttendanceBatchResult` (success/failure counts, failed UIDs for retry).
  - `ClassMonthlyAttendanceSummary` (aggregates for MoEYI Form SF4).

---

## 3. Multi-School & Current School Context

**Key idea:** The same code must work for 1 school or 600 schools.

- Every attendance call passes **`schoolId`** all the way down:
  - UI -> Controllers -> `AttendanceService` -> `AttendanceRepository` -> Firestore.

- Current school is held centrally:

  - `lib/src/core/app_providers.dart`
    - `currentSchoolProvider = StateProvider<School?>((ref) => null);`
    - Set on:
      - Startup (via `startupRouteProvider` reading `user.schoolId` and loading the `School` doc).
      - School selection (on `SelectSchoolPage`, we set both `user.schoolId` and `currentSchoolProvider`).

- `School` model:
  - `lib/src/models/school/domain/school.dart` has
    `School.fromMap(String id, Map<String, dynamic> data)` so parsing is consistent.
  - Fields: `id`, `name`, `lat`, `lng`, `radiusMeters`, `timezone` (`America/Jamaica` by default).

> **Rule:**
> Never hardcode school details (like `"stony_hill_heart"`) in business logic.
> Always use `schoolId` plus `currentSchoolProvider`.

---

## 4. Shift System (Jamaican Context)

**Shift types:**

- `morning`: 7:00 AM -- 12:00 PM
- `afternoon` / `evening`: 12:00 PM -- 5:00 PM
- `whole_day`: 8:00 AM default (most schools in Jamaica today)

**Where it lives:**

- `AttendanceDay.shiftType` holds the normalized value:
  - `AttendanceDay.normalizeShiftType(raw)` ensures values are one of:
    - `'morning'`, `'afternoon'`, `'whole_day'`.
    - Aliases like `'evening'` map to `'afternoon'`.
    - `null` -> `'whole_day'` (safe default for non-shift schools).

- In `attendance_service.dart`:
  - `_getExpectedStartTime(shiftType, date)`:
    - `morning` -> 07:00
    - `afternoon` -> 12:00
    - `whole_day`/unknown -> 08:00
  - `_classEndFor(date, shiftType)`:
    - `morning` -> 12:00
    - `afternoon` -> 17:00
    - `whole_day` -> 16:00
  - `_overtimeCutoffFor(date, shiftType)`:
    - `morning` -> 12:30
    - `afternoon` -> 17:30
    - `whole_day` -> 16:30

**Student shift:**

- `AppUser.currentShift` (string) is controlled by admin/principal UI:
  - `AdminStudentListPage` + `AdminStudentEditPage`.
- `AttendanceService` reads `student.currentShift` via `UserService` to decide which shift to use when clocking in / out.

> **Rule:**
> One student, one shift per day, one `AttendanceDay` record:
> `{dateKey}_{shiftType}_{studentUid}` = unique attendance document.

---

## 5. Clock-In / Clock-Out Logic (Student Self-Service)

### Clock-In (`AttendanceService.clockIn`)

Inputs:

- `schoolId`
- `studentUid`
- `AttendanceLocation`
- Optional: `classId`, `className`, `gradeLevel`
- Optional: `lateReason` (required if late)
- Optional: `at` (for tests; defaults to `schoolNow()`)

Flow:

1. Get `ts = at ?? schoolNow()`.
2. Block weekends & holidays (`_isSchoolDay`).
3. Load `AppUser` via `UserService.getUser(studentUid)`:
   - Read `student.currentShift`.
   - Normalize to `shiftType`.
4. Build `dateKey = AttendanceDay.dateKeyFor(ts)`.
5. Check existing record via repo (`getDay` with `schoolId`, `studentUid`, `dateKey`, `shiftType`):
   - If record exists and `clockInAt != null` -> return existing (idempotent).
6. Compute `expectedStart` + `graceCutoff` (30 mins).
7. Decide status:
   - `ts <= graceCutoff` -> `AttendanceStatus.early`
   - else -> `AttendanceStatus.late`
8. If `late`:
   - `lateReason` must be non-empty.
   - `lateReason` must be valid MoEYI code (see section **8**).
9. Build `AttendanceDay` with `shiftType`, `clockInAt`, `location`, etc.
10. Save via repo -> Firestore source.
11. On any low-level error, throw `AttendancePersistenceException`.

### Clock-Out (`AttendanceService.clockOut`)

Flow:

1. `ts = at ?? schoolNow()`.
2. Block weekends & holidays.
3. Fetch `AppUser` -> get `shiftType`.
4. Load existing `AttendanceDay` for `(schoolId, studentUid, dateKey, shiftType)`:
   - If no record or no `clockInAt` -> `NoClockInFoundException`.
   - If `clockOutAt` already set -> `AlreadyClockedOutException`.
5. Compute shift-aware `classEnd` and `overtimeCutoff`.
6. Derive UX flags:
   - `isEarlyLeave = ts.isBefore(classEnd)`
   - `isOvertime = ts.isAfter(overtimeCutoff)`
7. Copy existing `AttendanceDay` -> `updated` with clock-out fields.
8. Save via repo and return.

---

## 6. Teacher Batch Attendance

Teachers take attendance for an entire class at once. This is the **primary attendance path** -- student self-service clock-in is supplemental.

### Data Flow

```
TeacherAttendancePage (UI)
  |
  Collects status toggles for each student
  |
  Calls: repo.saveAttendanceBatch(entries: List<TeacherAttendanceEntry>)
  |
TeacherAttendanceRepository
  |
TeacherAttendanceDataSource.saveAttendanceBatch()
  +-- Pre-resolve: Fetch existing docs + student fields (sex, gradeLevel)
  +-- Build Firestore batch (atomic, all-or-nothing)
  |   +-- For each entry:
  |   |   +-- Upsert: schools/{schoolId}/attendance/{docId}
  |   |   |   (stamps sex, gradeLevel, shiftType, updatedAt, takenAt-if-new)
  |   |   +-- Append audit history (only if new or status changed)
  |   +-- Commit batch
  +-- Return AttendanceBatchResult
  |
UI receives result -> show success/error snackbar
```

### Key Details

- **Atomic writes:** Uses `FirebaseFirestore.batch()` -- all entries succeed or all fail.
- **Denormalized fields:** Each attendance doc stamps `sex`, `gradeLevel`, `shiftType` for MoEYI reporting without N+1 queries.
- **Default status:** Students not explicitly toggled default to `absent`.
- **Merge semantics:** Uses `SetOptions(merge: true)` so re-saving doesn't clobber existing fields.

### `TeacherAttendanceEntry` Fields

| Field | Type | Notes |
|-------|------|-------|
| `schoolId` | String | Multi-tenant scope |
| `dateKey` | String | "YYYY-MM-DD" |
| `status` | AttendanceStatus | Teacher's mark |
| `student` | TeacherAttendanceStudent | UID + metadata |
| `classOption` | TeacherClassOption | Class reference |
| `takenByUid` | String | Teacher UID (audit) |
| `shiftType` | String? | Resolved from student profile |
| `subjectId` / `subjectName` | String? | Optional subject-level attendance |
| `periodId` | String? | Optional period reference |

### `AttendanceBatchResult`

| Field | Type | Notes |
|-------|------|-------|
| `totalEntries` | int | Total students in batch |
| `successCount` | int | Successfully written |
| `failureCount` | int | Failed |
| `failedStudentUids` | List<String> | For retry UX |
| `isAllSuccessful` | bool | `failureCount == 0` |

### Monthly Aggregation (`ClassMonthlyAttendanceSummary`)

Used for MoEYI Form SF4 reporting:

- `totalMarkedRecords` -- total records in the month
- `totalPresentLike` -- present + early + late
- `totalAbsent`, `totalExcused`
- `distinctSchoolDays` -- unique dates with records
- `averageDailyAttendance` -- present-like / distinct days
- `percentageAttendance` -- (present-like / total) * 100

---

## 6A. Audit Trail

Every attendance status change is recorded in an immutable subcollection.

### Firestore Path

```
schools/{schoolId}/attendance/{dateKey}_{shiftType}_{studentUid}/history/{autoId}
```

### History Document Fields

| Field | Type | Notes |
|-------|------|-------|
| `previousStatus` | String? | `null` if new document; otherwise the previous status name |
| `newStatus` | String | The new status enum name |
| `changedByUid` | String | UID of teacher or student who triggered the change |
| `serverTimestamp` | Timestamp | Server-side timestamp |

### When History Is Written

- **Teacher batch writes:** Inside the same `FirebaseFirestore.batch()` -- only when the document is new or the status actually changed.
- **Student self-service clock-in/out:** After writing the attendance doc in `attendance_firestore_source.dart` -- same condition (new doc or status change).

### Design Rules

- History documents are **append-only** -- never updated or deleted.
- Both teacher and student flows use the **same audit format**.
- The `changedByUid` field enables tracing who changed a student's status and when.

---

## 7. Offline & Local Storage (Poor Internet Support)

> **Status: NOT YET IMPLEMENTED.** The design below is the target architecture. Currently, all attendance writes go directly to Firestore with no local queue. This section documents the intended behaviour for when offline support is built.

**Goal:** Attendance must still work when a student or teacher has **weak / no signal**.

Target behaviour:

- When online:
  - Normal flow: write directly via repository -> Firestore source.
- When offline / unstable:
  - Attendance actions (clock-in, clock-out) are:
    - Saved locally (e.g., on-device queue / local DB).
    - Tagged with:
      - Device timestamp.
      - `schoolId`, `studentUid`, `shiftType`, `dateKey`.
      - A unique local operation ID.
  - UI shows:
    - Clear status such as "Saved offline, will sync when connection returns."
- On reconnect:
  - A sync process replays queued operations via `AttendanceService` so **business rules still apply**.
  - Conflicts (e.g., two different devices trying to clock the same student) are resolved by **server rules**, not by blindly overwriting.

> **Rules for implementation:**
> - Offline writes must still go through `AttendanceService` logic when syncing.
> - Never silently drop a queued attendance event.
> - If sync fails, surface a clear message via the error mapper and allow manual retry.

This is critical for rural Jamaican schools and students with limited data.

---

## 8. Security & Anti-Fraud (No "Clock In For My Friend")

**Goal:** Make it hard for a student to log in as another student and tap "Present".

### Implemented

- **Account identity:** Each student has a unique account (`AppUser`). Clock-in is tied to the authenticated user.
- **Teacher as source of truth:** Teacher batch attendance (section 6) is the primary path. Student self clock-in is supplemental.
- **Geofencing:** `AttendanceGeoService` checks GPS against `School.lat/lng/radiusMeters` before allowing clock-in. Out-of-zone attempts can be blocked or flagged.
- **Audit trail:** Every status change records `changedByUid` and server timestamp (section 6A), making tampering traceable.

### Planned (Not Yet Implemented)

- **Re-auth on shared devices:** Optional PIN / biometrics before clock-in on shared devices.
- **Shorter session lifetimes:** For sensitive flows like self clock-in.
- **Device fingerprinting:** Record device info alongside attendance events to detect one device clocking in multiple UIDs.
- **Suspicious pattern detection:** Alerts for admins when anomalous patterns are detected.

> **Rule:**
> When adding new features, consider: "Does this make it easier or harder to cheat?"
> We always aim to **raise the cost of cheating** without punishing honest students.

---

## 9. MoEYI Late Reasons

File: `attendance_models.dart`:

```dart
enum MoEYILateReason {
  transportation,
  economic,
  illness,
  emergency,
  family,
  other,
}
```

**Helpers:**

- `.label` -- nicely formatted label (e.g., Transportation).
- `.code` -- enum name (`'transportation'`, `'economic'`, etc.).
- `MoEYILateReasonLabel.fromCode(code)` -- enum from stored string.
- `MoEYILateReasonLabel.isValid(code)` -- validation.

**Rules:**

- Students must pick one of the MoEYI categories when late.
- No free-text reason (keeps data clean for MoEYI reporting and avoids rude content).

**UI Support:**

- `lib/src/features/attendance/application/late_reason_provider.dart`
  - `LateReasonOption` model.
  - `lateReasonOptionsProvider` for dropdowns.
- `student_attendance_page.dart`:
  - Shows dropdown instead of free-text input.
  - Disables submit until a category is selected.

---

## 10. Error Handling & UX Behaviour

### Central Mapping

- `lib/src/features/attendance/application/attendance_error_mapper.dart`
- `mapAttendanceErrorToMessage(Object error)`:
  - `NotSchoolDayException` -> "You can't take attendance on weekends or holidays."
  - `LateReasonRequiredException` -> "Please select a reason for being late."
  - `InvalidLateReasonException` -> "That late reason is not recognized."
  - Missing index / persistence error -> "We couldn't load your attendance right now. Please try again in a moment."

### Controllers

- `student_attendance_controller.dart`
  - Holds `AsyncValue<AttendanceDay?>` for today.
  - Methods: `refreshToday()`, `clockIn()`, `clockOut()`, `clearError()`.
  - Catches all errors, calls `mapAttendanceErrorToMessage`, stores `lastErrorMessage`.
- `student_attendance_history_controller.dart`
  - Holds `AsyncValue<List<AttendanceDay>>` for recent days.
  - Computes stats: present / absent / late / early.
  - Same error mapping pattern.

### Firestore Index Errors

- Detected in `attendance_firestore_source.dart`.
- Logs include the index creation URL for developers.
- The UI never shows raw Firebase messages -- only friendly text.

### UX Rules

- Never crash the app for attendance errors.
- Show an error card / banner at the top of the screen.
- Keep controls enabled where possible so the user can retry.
- Log detailed technical error with `dev.log`, but show a simple message to the user.

---

## 11. How Geofencing Connects

- Geofence logic is in `attendance_geo_service.dart` (and related files).
- It requires a `School` instance (`lat`, `lng`, `radiusMeters`).

**Flow on clock-in/out:**

1. Get `school = ref.read(currentSchoolProvider)`.
2. If `school == null`:
   - Show message: "School configuration not available. Please restart the app."
   - Return early (no crash).
3. Call geo service with school and current GPS:
   - May block attendance or flag outside-zone incident, depending on future config.

---

## 12. Navigation & Startup Flow (Important for Multi-School)

- `main.dart`:
  - `initialRoute` must be `'/'`, not `'/teacher'`.
  - Startup decides where to go based on:
    - Auth state.
    - Whether user has a role.
    - Whether user has a `schoolId`.
- `select_role.dart`:
  - When role is chosen, if user has no `schoolId` -> route to `/selectSchool` first.
- `select_school.dart`:
  - When a school is chosen:
    - Update user profile (`schoolId`).
    - Set `currentSchoolProvider` with full `School` object.

**Result:**

- New user: Sign up -> select role -> select school -> home.
- Returning user: App startup -> user loaded -> school loaded -> attendance + geofence ready.

---

## 13. Guidelines for Future Changes (for Humans & Claude)

When you (or Claude) modify the attendance module:

1. **Do not bypass the service layer.**
   - All business rules live in `AttendanceService`.
   - UI and controllers should never talk directly to Firestore.

2. **Always respect `schoolId` and `shiftType`.**
   - `AttendanceDay` is uniquely identified by `(schoolId, dateKey, shiftType, studentUid)`.
   - Never assume single-school or single-shift.

3. **Use domain exceptions, not generic errors.**
   - Throw the custom exceptions from `attendance_exceptions.dart`.
   - Let the error mapper decide the UX message.

4. **Keep MoEYI reasons clean.**
   - Never store arbitrary strings for `lateReason`.
   - Always use the enum codes.

5. **Geofencing must use `currentSchoolProvider`.**
   - No hardcoded coordinates.
   - If school is null, handle gracefully.

6. **If you add Firestore queries, wrap them.**
   - `try / on FirebaseException / on PlatformException / catch`.
   - Log with `dev.log`.
   - Throw `AttendancePersistenceException`.

7. **Write audit history on status changes.**
   - Any code path that creates or changes an `AttendanceDay` status must append to the `history` subcollection.
   - Use the same format: `previousStatus`, `newStatus`, `changedByUid`, `serverTimestamp`.

8. **Offline & anti-fraud must be considered.**
   - Any new feature should:
     - Work in low-connectivity environments (queue + sync) once offline support is built.
     - Not make it easier for students to cheat attendance.

9. **Update this document.**
   - Whenever you introduce new core behaviours (e.g., per-school holidays, new statuses, new shift types, new anti-fraud checks), document them here so future changes are safe.

---

Before touching attendance, read this file and follow its rules.
This is the contract for how the attendance engine of EduAir must behave.

*Last updated: January 2026*
