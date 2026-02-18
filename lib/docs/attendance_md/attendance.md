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
  - `AttendanceSource` (`studentSelf`, `teacherBatch`, `adminEdit`) -- provenance of the record.
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
  - Serializes `source` (enum name) and `deviceId` (if non-null) to Firestore.
  - Deserializes `source` with backward-compatible default (`studentSelf` when field is missing in old docs).
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
9. Build `AttendanceDay` with `shiftType`, `clockInAt`, `location`, `source: AttendanceSource.studentSelf`, etc.
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
7. Copy existing `AttendanceDay` -> `updated` with clock-out fields and `source: AttendanceSource.studentSelf`.
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
  |   |   |   (stamps sex, gradeLevel, shiftType, source='teacherBatch', updatedAt, takenAt-if-new)
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

> **Note:** `toFirestoreMap()` also stamps `source: 'teacherBatch'` on every document written through the teacher batch path.

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
- **Record provenance (`AttendanceSource`):** Every attendance document stores a `source` field indicating who/what created it:
  - `studentSelf` -- student self clock-in/clock-out (default for backward compat with old docs).
  - `teacherBatch` -- teacher class register / batch mark.
  - `adminEdit` -- admin or principal manual correction (enum defined, write path not yet built).
- **`deviceId` field (placeholder):** `AttendanceDay` carries an optional `deviceId` string. Currently written as `null`; ready for future device fingerprinting without a schema migration.

### Planned (Not Yet Implemented)

- **Re-auth on shared devices:** Optional PIN / biometrics before clock-in on shared devices.
- **Shorter session lifetimes:** For sensitive flows like self clock-in.
- **Device fingerprinting:** Wire real `deviceId` values (e.g., via `device_info_plus`) to detect one device clocking in multiple UIDs. The `deviceId` field on `AttendanceDay` is already in place.
- **Suspicious pattern detection:** Alerts for admins when anomalous patterns are detected.
- **Source-based analytics:** Query by `source` field to understand what percentage of records come from student self-service vs teacher batch vs admin edits.

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

## 14. Device-Based Anti-Fraud (Read-Only Analytics)

> **Goal:** Detect and discourage **Proxy Attendance** (students marking present for others) **without** punishing honest families who share devices or have weak connectivity.
>
> **Core principle:** All anti-fraud logic is **read-only analytics**. The attendance write path (`AttendanceService` + repositories) stays simple and fast. If fraud detection fails or is disabled, attendance still works normally.

---

### 14.1 Terminology

- **Proxy Attendance** -- When a student's attendance is recorded from a device or account not really under that student's control (e.g., a friend at the gate with multiple phones).
- **Primary Device** -- The device most commonly used by a student to clock themselves in/out.
- **Shared Family Device** -- A single device used by multiple **related** students in the same household (siblings, cousins, etc.).
- **School Kiosk Device** -- A device owned by the school (tablet/phone at the gate or classroom) used to help students clock in under **staff supervision**.
- **Teacher-Lent Device** -- A teacher's personal device temporarily handed to a student for clock-in (common in low-resource schools).

> We never show "buddy system" in the UI. Use the professional terms above.

---

### 14.2 Data Signals Used for Anti-Fraud

These fields already exist on `AttendanceDay` (added in the source/deviceId evolution):

| Field | Notes |
|-------|-------|
| `source` (`AttendanceSource`) | `studentSelf`, `teacherBatch`, `adminEdit` |
| `deviceId` (`String?`) | Optional device fingerprint (not yet wired; placeholder `null`) |
| `clockInLocation` / `clockOutLocation` | GPS snapshot at time of action |
| `studentUid`, `schoolId`, `dateKey`, `shiftType` | Grouping keys for pattern analysis |

Additional signals available from existing models:

| Signal | Source | Notes |
|--------|--------|-------|
| `parentGuardianPhone` | `AppUser` | Best grouping key for Jamaican families (more reliable than surname -- mixed surnames are common with different fathers, grandparent guardians, etc.) |
| `takenByUid` | `AttendanceDay` | Who triggered the write (student UID for self-service, teacher UID for batch) |
| Clock-in time deltas | Derived | Time between consecutive clock-ins from the same `deviceId` on the same day |

> **Rule:** Anti-fraud logic **never writes** attendance documents. It only reads and flags.
> The write path stays untouched.

---

### 14.3 Detection Flags (Not Scores)

Instead of a numeric risk score (0-100), we use **binary flags** per attendance event. Flags are cheap to compute, easy to query, and meaningful without calibration data from pilot schools.

| Flag | Condition | Severity |
|------|-----------|----------|
| `isSharedDevice` | Same `deviceId` used by **> 1** `studentUid` on the same `dateKey` | Info |
| `isMultiDevice` | Same `studentUid` used **> 3** distinct `deviceId` values in a rolling 30-day window | Medium |
| `isOffCampus` | `clockInLocation` is outside the school's `radiusMeters` and `source = studentSelf` | High |
| `isRapidCluster` | Same `deviceId` clocked **> 3** different students within a **2-minute window** | High |
| `isUnconfirmed` | `source = studentSelf` and no matching `teacherBatch` record exists for the same student + class + day | Info |

**Flags are signals, not verdicts.** A flagged record means "a human should look", never "auto-punish".

> **Future:** Once we have real data from pilot schools, we can layer weighted scoring on top of these flags. Until then, flags are sufficient and avoid false precision.

---

### 14.4 Real-World Detection Scenarios

We design around **real Jamaican scenarios**, not imaginary hackers.

#### Scenario A -- Normal family sharing one phone (OK)

- One `deviceId`, 2-5 students.
- Students share a `parentGuardianPhone` (strongest sibling signal in Jamaica -- more reliable than surname matching).
- Device is on campus during clock-in.
- Source: `studentSelf` or under teacher supervision.

**Flags triggered:** `isSharedDevice` (info only).
**Handling:** No action needed. Dashboard shows "shared family device" when `parentGuardianPhone` matches across students.

---

#### Scenario B -- One device marking many unrelated students (Proxy Attendance)

- One `deviceId` used to clock **> 3** different `studentUid` in a single day.
- Students do **not** share a `parentGuardianPhone`.
- Source = `studentSelf`.
- Clock-in times cluster tightly (e.g., 5 students within 2 minutes).

**Flags triggered:** `isSharedDevice` + `isRapidCluster`.
**Handling:** Surface in teacher/admin dashboard. Teacher confirms or denies with one tap per student (see 14.5).

---

#### Scenario C -- One student using many devices ("Device Hopping")

- One `studentUid` uses **> 3** unique `deviceId` in a rolling 30-day window.
- Devices appear in different locations or at unusual times.

**Flags triggered:** `isMultiDevice`.
**Handling:** Show in admin dashboard as "Requires Review". Do **not** auto-punish. Could be legitimate (broken phone, borrowed device, etc.).

---

#### Scenario D -- Off-campus "present" (Location Mismatch)

- `clockInLocation` is **outside** the school's `radiusMeters`.
- Source = `studentSelf`.
- Device is not a registered school kiosk.

**Flags triggered:** `isOffCampus`.
**Handling:**
- Student UI: "Your attendance was recorded. If you're not at school, please see your teacher."
- Teacher/admin dashboard: flag event as "Off-campus clock-in".
- Teacher can confirm or override via their batch attendance (becomes `teacherBatch` source).

---

#### Scenario E -- School kiosk device (trusted many-to-many)

- A `deviceId` registered as **school-owned** in admin settings.
- Used inside school, many students use it throughout the day.

**Flags triggered:** `isSharedDevice` (info only, suppressed in dashboards for registered kiosks).
**Handling:** Low risk. Allowed pattern for low-income schools that provide shared devices at the gate or in classrooms.

---

#### Scenario F -- Teacher-lent device

- A teacher hands their personal phone to a student to clock in.
- `deviceId` = teacher's device, `source` = `studentSelf`, `takenByUid` = student UID.
- This is **legitimate** but looks like Scenario B to naive detection.

**Flags triggered:** `isSharedDevice` (potentially `isRapidCluster` if multiple students use it).
**Handling:** When `deviceId` matches a known teacher's device (from their own `teacherBatch` records for the same day), suppress or downgrade flags. The teacher's physical presence is implicit verification. This is an expected pattern -- future fraud logic must not false-positive on it.

---

### 14.5 Teacher Confirmation as Primary Verification

The strongest anti-fraud mechanism is the one we already have: **the teacher is physically in the building.**

Rather than building complex PIN/SMS verification:

1. Student self-service records start with an implicit `isUnconfirmed` flag.
2. When a teacher submits batch attendance for the same class + day + shift, each student's record gains teacher confirmation.
3. If teacher batch and student self-service **agree** (both say present) -- high confidence.
4. If they **disagree** (student says present, teacher says absent) -- flag for admin review.
5. If no teacher batch exists for the day -- records remain `isUnconfirmed` (info-level, not blocking).

This approach:
- Requires **zero new infrastructure** (uses existing `source` field and `teacherBatch` flow).
- Works on weak connections (no SMS round-trips).
- Costs nothing (no per-message SMS fees at scale across 600+ schools).
- Fits naturally into the teacher's existing workflow.

> **Rule:** Teacher confirmation is the **primary** verification path. PIN/SMS/biometric verification is a **future optional layer** for edge cases, not the default response to flagged events.

---

### 14.6 Response Levels

#### Level 0 -- Observe (Default)

- No blocking. No student-facing friction.
- Log flags on each attendance event.
- Show flag summaries in admin/teacher dashboards (e.g., "3 shared-device events today").

#### Level 1 -- Teacher Review (Flagged Events)

Triggered when flags like `isRapidCluster`, `isOffCampus`, or `isMultiDevice` appear:

- Teacher/admin dashboard highlights the flagged records.
- Teacher can confirm or correct with one tap (writes `source: adminEdit` or overwrites via `teacherBatch`).
- Student UI (optional): "Your attendance was recorded. If this is not correct, please speak with your teacher."

No automatic blocks. The teacher decides.

#### Level 2 -- Admin Escalation (Repeated Patterns)

Triggered when the same student or device is flagged **repeatedly** over multiple days:

- Admin dashboard aggregates flag history per student and per device.
- Admin can investigate, contact parents, or adjust device registrations.
- All actions recorded in audit trail (`source: adminEdit`, `changedByUid`).

> **Rule:** Serious consequences (chronic absence flags, disciplinary actions, exam eligibility) must **never** be driven solely by automated flags. There must always be a **human review path**, in line with Jamaica's Data Protection Act 2020.

---

### 14.7 Legal & Ethical Guardrails

To align with **Jamaica Data Protection Act (DPA) 2020** and MoEYI expectations:

- Automated flags must **not** be the sole basis for decisions that significantly affect a student.
- Students and parents must have a way to:
  - Contest suspicious attendance marks.
  - Request a teacher/admin review of flagged events.
- All audit data (`changedByUid`, `source`, `deviceId`, timestamps, flag history) must be preserved for investigations.
- Device registration (kiosks, family devices) should be **opt-in and transparent** -- never silent fingerprinting without consent.

---

### 14.8 Implementation Phases

**Phase 1 (current):** `source` and `deviceId` fields exist on `AttendanceDay`. `deviceId` is written as `null`. No fraud detection logic runs yet.

**Phase 2 (next):**
- Wire real `deviceId` via `device_info_plus` (or similar) in `AttendanceService.clockIn()`/`clockOut()`.
- Build flag computation as a **server-side Cloud Function** (scheduled or on-write trigger), not client-side. Client-side aggregation would be expensive on Firestore reads and slow on weak connections.
- Build admin dashboard page to surface flags.

**Phase 3 (later):**
- Teacher confirmation matching (compare `studentSelf` vs `teacherBatch` for same class/day).
- Device registration UI (admin registers kiosk devices, family groupings auto-detected via `parentGuardianPhone`).
- Optional: weighted scoring on top of flags, calibrated with real pilot school data.

---

### 14.9 AttendanceFraudService (Domain Interface Sketch)

File: `lib/src/features/attendance/domain/attendance_fraud_service.dart`

```dart
/// AttendanceFraudService
/// ----------------------
/// Read-only analytics service to detect patterns of Proxy Attendance.
/// This service NEVER writes attendance docs; it only reads and flags.
///
/// If this service fails or is disabled, the core AttendanceService
/// still works normally. Fraud detection is always optional.
///
/// Production note: The heavy aggregation queries (group by deviceId,
/// count distinct students across a date range) should run server-side
/// via a Cloud Function on a schedule, not client-side. This service
/// is the client-side interface for reading pre-computed results or
/// performing lightweight checks.
class AttendanceFraudService {
  final AttendanceRepository _repo;

  AttendanceFraudService(this._repo);

  /// Check binary flags for a single attendance event.
  /// Returns a set of flag names (e.g., {'isSharedDevice', 'isOffCampus'}).
  Future<Set<String>> computeFlags({
    required AttendanceDay record,
    required School school,
  }) async {
    // Future implementation:
    // - Check clockInLocation vs school.radiusMeters -> isOffCampus
    // - Look up other records for same deviceId + dateKey -> isSharedDevice
    // - Look up other records for same studentUid (30-day window) -> isMultiDevice
    // - Check time deltas between consecutive clock-ins -> isRapidCluster
    // - Check for matching teacherBatch record -> isUnconfirmed
    throw UnimplementedError('Phase 2 implementation pending');
  }

  /// Find devices with multiple unrelated students on a given day.
  /// "Unrelated" = students who do not share a parentGuardianPhone.
  Future<List<DeviceAnomaly>> findSuspiciousDevices({
    required String schoolId,
    required String dateKey,
    int threshold = 3,
  }) async {
    throw UnimplementedError('Phase 2 implementation pending');
  }
}

/// Anomaly description for dashboards / reports.
class DeviceAnomaly {
  final String deviceId;
  final int uniqueStudentCount;
  final List<String> studentUids;
  final bool hasFamilyLink; // true if students share parentGuardianPhone

  DeviceAnomaly({
    required this.deviceId,
    required this.uniqueStudentCount,
    required this.studentUids,
    required this.hasFamilyLink,
  });
}
```

---

Before touching attendance, read this file and follow its rules.
This is the contract for how the attendance engine of EduAir must behave.

*Last updated: January 31, 2026*
