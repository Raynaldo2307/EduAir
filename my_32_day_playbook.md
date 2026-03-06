# EduAir — 32-Day Capstone Playbook
**Start:** February 23, 2026
**Due:** March 27, 2026 (Friday)
**Viva:** Week of March 30, 2026
**Student:** Solo

---

> **Node.js reminder — combining DATE + TIME from MySQL:**
> ```js
> // attendance_date is DATE, clock_in is TIME — combine them in your API response
> const clockInAt = new Date(`${attendance_date}T${clock_in}`);
> const clockOutAt = new Date(`${attendance_date}T${clock_out}`);
> ```

---

## Project Overview

**EduAir** — Multi-tenant school attendance management app for Jamaican schools.

**Full Stack:**
- Frontend: Flutter + Riverpod
- Primary Auth: Node.js JWT (bcrypt + JWT) ✅
- Google Sign In + FCM: Firebase (identity layer only)
- Backend API: Node.js + Express ✅ feature-complete
- Database: MySQL ✅ all 10 tables live, test data seeded

**Auth Architecture Decision (Mar 2):**
Email/password login now goes through Node.js JWT — NOT Firebase.
Firebase is kept only for Google Sign In and future FCM notifications.
Viva answer: *"I built my own auth with bcrypt and JWT. Firebase only handles Google Sign In."*

**Capstone Domain:** Education

---

## What Is Already Done

- [x] Node.js JWT auth — login, register, GET /api/auth/me (replaces Firebase email auth)
- [x] Flutter sign in wired to Node API — JWT stored securely on device
- [x] startupRouteProvider checks Node JWT on app start (not Firebase)
- [x] Firebase kept for Google Sign In + future FCM only
- [x] Dio HTTP client + JWT interceptor (api_client.dart)
- [x] Token storage service (flutter_secure_storage)
- [x] Auth, Attendance, Students API repositories (data layer)
- [x] All 5 Node API repositories wired as Riverpod providers
- [x] Multi-school support (schoolId scoping)
- [x] Student attendance — clock in/out with geofencing
- [x] Jamaica shift system (morning / afternoon / whole_day)
- [x] MoEYI late reason categories
- [x] Teacher attendance flow
- [x] Admin student management (view + edit)
- [x] Layered architecture (UI → Controller → Service → Repository → API/Firestore)
- [x] Riverpod state management
- [x] Typed domain exceptions + error mapping

---

## MySQL Tables — Progress

All 10 tables designed. Next step: write and run CREATE TABLE SQL scripts.

- [x] `schools` — id, name, parish, school_type, moey_school_code, is_shift_school, default_shift_type, lat, lng, radius_meters, timezone, is_active, timestamps
- [x] `users` — id, email, password_hash, first_name, last_name, role, school_id, timestamps
- [x] `students` — id, school_id, user_id, first_name, last_name, student_code, sex, date_of_birth, current_shift_type, phone_number, homeroom_class_id, status, timestamps
- [x] `teachers` — id, school_id, user_id, staff_code, department, employment_type, hire_date, current_shift_type, homeroom_class_id, status, timestamps
- [x] `classes` — id, school_id, name, grade_level, timestamps
- [x] `student_classes` — id, student_id, class_id (many-to-many)
- [x] `teacher_classes` — id, teacher_id, class_id (many-to-many)
- [x] `parent_students` — id, parent_user_id, student_id, relationship_type, is_primary_guardian
- [x] `attendance` — id, school_id, student_id, class_id, attendance_date, shift_type, status, source, clock_in, clock_in_lat/lng, clock_out, clock_out_lat/lng, late_reason_code, device_id, recorded_by_user_id, note, timestamps
- [x] `attendance_history` — id, attendance_id, previous_status, new_status, changed_by_user_id, source, created_at
- [x] Write all CREATE TABLE SQL scripts in correct order
- [x] Run scripts in MySQL — zero errors
- [x] Insert test data (5 schools, 4 students, 35+ attendance rows)

---

## Deliverables Checklist

- [ ] Functional Flutter app (APK or runnable)
- [x] Node/Express + MySQL backend running
- [ ] GitHub repository (clean, pushed)
- [ ] Technical documentation (architecture, API endpoints, DB schema)
- [ ] User manual with screenshots
- [ ] Application screenshots
- [ ] 5-minute demo video
- [ ] Project brief / problem statement

---

## The 32-Day Plan

---

### PHASE 1 — MySQL Database Design ✅ COMPLETE
> Started week of Feb 16. All 10 tables designed and documented.
> Remaining: write SQL scripts and test in MySQL.

---

#### Day 1 — Feb 23 ✅
**All 10 tables designed** — schools, users, students, teachers, classes, student_classes, teacher_classes, parent_students, attendance, attendance_history

---

#### Days 2–6 — Feb 24–28 ✅
**Focus: Write and test CREATE TABLE SQL scripts**
- [x] Create `edu_air_db.sql` — all 10 CREATE TABLE statements in correct order
- [x] Order matters: `schools` → `users` → `classes` → `students` → `teachers` → `student_classes` → `teacher_classes` → `parent_students` → `attendance` → `attendance_history`
- [x] Run scripts in MySQL (TablePlus / DBeaver / MySQL Workbench)
- [x] Fix any errors until all 10 tables create with zero issues
- [x] Insert test data: 5 schools, 4 students, 35+ attendance rows
- [x] Test foreign key enforcement (insert a student with a bad school_id — it must fail)

---

#### Day 7 — Mar 1 ✅
**Focus: Schema review + diagram**
- [ ] Draw the relationship diagram on dbdiagram.io or paper
- [x] Confirm every table has `created_at` + `updated_at` where appropriate
- [x] Save `edu_air_db.sql` to the `/DB` folder — this is a deliverable

---

### PHASE 2 — Node.js + Express Backend ✅ COMPLETE (finished Mar 1 — 9 days ahead of schedule)
> Goal: A working API that the Flutter app (or Postman) can call. Cover auth, students, and attendance.
> All 4 modules (auth, schools, students, attendance) built, tested in Postman, and domain-aligned with Flutter.

---

#### Day 8 — Mar 2 ✅ (completed early — Feb 25)
**Focus: Node project setup**
- [x] Create `/eduair_api` repo — separate from Flutter project
- [x] Run `npm init -y`
- [x] Install: `express`, `mysql2`, `dotenv`, `bcryptjs`, `jsonwebtoken`, `cors`
- [x] Create folder structure (feature-based, not flat):
  ```
  eduair_api/
  ├── src/features/auth/
  ├── src/features/schools/
  ├── src/features/students/
  ├── src/features/attendance/
  ├── middleware/
  ├── config/
  └── app.js
  ```
- [x] Create `app.js` — Express app running on port 3500
- [x] Create `.env` — DB_HOST, DB_USER, DB_PASS, DB_NAME, JWT_SECRET
- [x] Test: server starts with no errors

---

#### Day 9 — Mar 3
**Focus: MySQL connection**
- [x] Create `config/db.js` — MySQL connection pool using `mysql2`
- [x] Test connection: query `SELECT 1` and log success
- [x] Handle connection errors gracefully

---

#### Day 10 — Mar 4
**Focus: Auth routes — Register + Login**
- [x] Create `routes/auth.routes.js`
- [x] Create `controllers/auth.controller.js`
- [x] POST `/api/auth/register` — hash password with bcryptjs, insert into users table, return JWT
- [x] POST `/api/auth/login` — verify password, return JWT
- [x] Test both routes in Postman

---

#### Day 11 — Mar 5
**Focus: Auth middleware + protected routes**
- [x] Create `middleware/auth.middleware.js` — verify JWT from Authorization header
- [x] Create `middleware/role.middleware.js` — check user role (admin, teacher, student)
- [x] Test: call a protected route without token — should return 401
- [x] Test: call with valid token — should pass through

---

#### Day 12 — Mar 6 ✅ (completed early — Mar 1)
**Focus: Schools routes**
- [x] Create `schools.routes.js`, `schools.controller.js`, `schools.service.js`, `schools.repository.js`
- [x] GET `/api/schools` — list all schools (public)
- [x] GET `/api/schools/:id` — get one school (public), returns 404 if not found
- [x] POST `/api/schools` — create school (public for now)
- [x] PUT `/api/schools/me` — admin updates THEIR OWN school only (JWT-scoped, not /:id)
- [x] Input validation — rejects bad school_type with 400 + allowed values list
- [x] Cross-school security — admin token locks update to their school_id only
- [x] Tested all routes in Postman ✅

---

#### Day 13 — Mar 7 ✅ (completed early — Mar 1)
**Focus: Students routes — Read + Create**
- [x] Create `students.routes.js`, `students.controller.js`, `students.service.js`, `students.repository.js`
- [x] GET `/api/students` — list all students scoped to admin's school_id from JWT
- [x] GET `/api/students/:id` — get one student, 404 if not in your school
- [x] POST `/api/students` — enrols student, creates user account + student row in one transaction
- [x] Tested in Postman ✅

---

#### Day 14 — Mar 8 ✅ (completed early — Mar 1)
**Focus: Students routes — Update + Delete**
- [x] PUT `/api/students/:id` — update student profile (shift, phone, sex, etc.)
- [x] DELETE `/api/students/:id` — soft delete (sets status = 'inactive', row preserved)
- [x] Full CRUD complete for students ✅
- [x] Cross-school isolation proven — admin2 (school 2) cannot access school 1 students → 404
- [x] This is the CRUD demonstration for the capstone — tested and working cleanly

---

#### Day 15 — Mar 9 ✅ (completed early — Mar 1)
**Focus: Attendance routes — Create + Read**
- [x] Create `attendance.routes.js`, `attendance.controller.js`, `attendance.service.js`, `attendance.repository.js`
- [x] POST `/api/attendance/clock-in` — auto-resolves status (early/late) from Jamaica server time
- [x] GET `/api/attendance?date=YYYY-MM-DD&shift_type=` — school attendance by date/shift
- [x] GET `/api/attendance/student/:studentId` — student history with limit + shift filters
- [x] Late clock-in requires `late_reason_code` — MoEYI categories enforced
- [x] Audit trail written to `attendance_history` on every clock-in
- [x] Tested in Postman ✅

---

#### Day 16 — Mar 10 ✅ (completed early — Mar 1)
**Focus: Attendance routes — Update + polish**
- [x] PUT `/api/attendance/:id/clock-out` — clock out, writes audit trail
- [x] PUT `/api/attendance/:id` — admin/teacher corrects status/note, writes audit trail
- [x] DELETE `/api/attendance/:id` — admin only, today's records only (historical = 404)
- [x] Input validation on all routes — required fields, enum checks, coord validation
- [x] Global error handler in `app.js` — catches all next(err) calls
- [x] Backend feature-complete — all routes Postman tested ✅
- [x] Bug fix: `status` was returning `present` for on-time clock-ins → fixed to `early`
- [x] Bug fix: `is_early_leave` was never written on clock-out → now computed + saved

---

### PHASE 3 — Connect Flutter to Node Backend
> Goal: Flutter calls at least one real Node API endpoint. Shows full-stack integration.

---

#### Day 17 — Mar 11 ✅ (completed early — Mar 2)
**Focus: HTTP service in Flutter**
- [x] Add `dio` + `flutter_secure_storage` to pubspec.yaml
- [x] Create `lib/src/services/api_client.dart` — base Dio client + JWT interceptor (platform-aware URL)
- [x] Create `lib/src/services/token_storage_service.dart` — secure JWT storage
- [x] Create `lib/src/features/auth/data/auth_api_repository.dart` — login, register, getMe, logout
- [x] Create `lib/src/features/attendance/data/attendance_api_repository.dart` — clock-in/out, history
- [x] Create `lib/src/features/admin/students/data/students_api_repository.dart` — full CRUD
- [x] All 5 providers registered in app_providers.dart
- [x] **ARCH DECISION:** Switched Flutter email/password auth from Firebase → Node JWT
- [x] sign_in_form.dart calls Node API login (not Firebase)
- [x] startupRouteProvider validates JWT via GET /api/auth/me on app start
- [x] auth_services.dart — removed signIn/signUp, kept Google Sign In + signOut
- [x] Node API: extended login response (firstName, lastName) + added GET /api/auth/me

---

#### Day 18 — Mar 12 ✅ (completed early — Mar 2)
**Focus: Connect student listing to Node API**
- [x] `admin_student_list_page.dart` — schoolStudentsProvider now calls Node API (not Firestore)
- [x] Node student data mapped to AppUser via _nodeStudentToAppUser()
- [x] `admin_student_edit_page.dart` — save now calls studentsApiRepositoryProvider.update() (not Firestore)
- [x] Loading, empty, error states all handled (existing UI reused)
- [x] Full student CRUD now runs through Node API + MySQL

---

#### Day 19 — Mar 13 ✅ (completed early — Mar 2)
**Focus: Connect attendance to Node API**
- [x] Created `admin_attendance_page.dart` — reads school-wide attendance from Node API
- [x] Date picker + shift filter + refresh — calls GET /api/attendance?date=&shift_type=
- [x] Status chips (Early/Late/Present/Absent/Excused) with colour coding
- [x] Added as Attendance tab in TeacherShell for admin/principal users
- [x] Clock-in/out stays on Firebase Firestore (realtime, geofenced — untouched)
- [x] Node API handles reports/admin views, Firebase handles realtime student flow

---

#### Day 20 — Mar 14
**Focus: Test full flow end-to-end**
- [ ] Flutter → Node API → MySQL → response back to Flutter
- [ ] Fix any CORS issues on the backend
- [ ] Fix any auth token issues
- [ ] Verify the full flow works on a real device or emulator

---

#### Day 21 — Mar 15
**Focus: Polish + error handling**
- [ ] Every API call in Flutter must handle: loading, success, error
- [ ] No raw error messages shown to user — use friendly messages
- [ ] Test offline behaviour — what happens when API is unreachable?

---

### PHASE 4 — Flutter App Completion
> Goal: All screens working, all CRUD visible, UI polished.

---

#### Day 22 — Mar 16
**Focus: Complete any unfinished screens**
- [ ] Identify every screen that is incomplete or placeholder
- [ ] List them and prioritize
- [ ] Start with the ones assessors will see first (auth flow, dashboard, attendance)

---

#### Day 23 — Mar 17
**Focus: CRUD completeness check**
- [ ] Create — works and shows success feedback
- [ ] Read — works with loading indicator + empty state
- [ ] Update — works with confirmation
- [ ] Delete — works with confirmation dialog before deleting
- [ ] Every CRUD operation must be visible in the UI — this is an assessment criterion

---

#### Day 24 — Mar 18
**Focus: UI polish**
- [ ] Consistent color system throughout the app
- [ ] Typography hierarchy (headings vs body vs captions)
- [ ] Consistent spacing and padding
- [ ] Every screen has a proper AppBar or navigation
- [ ] No placeholder/Lorem ipsum text anywhere

---

#### Day 25 — Mar 19
**Focus: Final Flutter testing**
- [ ] Run on real device
- [ ] Test every user role (student, teacher, admin)
- [ ] Test the full attendance flow (clock in → see record → clock out)
- [ ] Fix any crashes or broken states
- [ ] Build APK: `flutter build apk`

---

### PHASE 5 — Deliverables
> Goal: Everything submitted on time. Nothing left to chance.

---

#### Day 26 — Mar 20
**Focus: GitHub repository**
- [ ] Clean up the repo — remove debug prints, dead code, test files
- [ ] Write a proper `README.md` (project name, description, setup instructions, tech stack)
- [ ] Push all code — Flutter app + `/backend` Node server
- [ ] Make sure the repo is public or accessible to assessors

---

#### Day 27 — Mar 21
**Focus: Technical documentation**
- [ ] Architecture overview (1 page — describe the 3 layers: Flutter, Firebase, Node/MySQL)
- [ ] API endpoints table (method, route, description, auth required)
- [ ] Database schema diagram (screenshot from dbdiagram.io or TablePlus)
- [ ] Packages and services used (list with brief reason for each)

---

#### Day 28 — Mar 22
**Focus: User manual**
- [ ] Take screenshots of every key screen
- [ ] Write step-by-step instructions for: register, log in, clock in, view attendance, admin add student
- [ ] Export as PDF

---

#### Day 29 — Mar 23
**Focus: Project brief / problem statement**
- [ ] 1 page: What problem does EduAir solve?
- [ ] Who are the target users? (students, teachers, admins at Jamaican schools)
- [ ] What is your solution?
- [ ] Keep it professional — this is the first thing assessors read

---

#### Day 30 — Mar 24
**Focus: 5-minute demo video**
- [ ] Record screen + audio (use QuickTime or OBS)
- [ ] Script: App overview (30s) → Auth flow (45s) → Key features (90s) → CRUD demo (90s) → Backend/API (45s)
- [ ] Keep it under 5 minutes
- [ ] Export and upload to Google Drive or YouTube (unlisted)

---

#### Day 31 — Mar 25
**Focus: Review everything**
- [ ] Read through all deliverables — is anything missing?
- [ ] Do a final run-through of the app on device
- [ ] Check the APK installs and runs cleanly
- [ ] Make sure GitHub link works

---

#### Day 32 — Mar 26
**Focus: Submit**
- [ ] Final submission
- [ ] Double-check everything is uploaded/linked
- [ ] Breathe — you made it

---

## Viva Prep (Mar 27 onwards)

Be ready to answer these without hesitation:

1. **"Describe your app architecture and why you structured it that way."**
   > EduAir uses a feature-first layered architecture: UI → Controller → Service → Repository → Firestore/API. Business logic never lives in the UI.

2. **"Why did you choose Riverpod for state management?"**
   > Riverpod eliminates context dependency issues, is compile-safe, and scales well for multi-role apps. Better than Provider for this complexity level.

3. **"How does your authentication work?"**
   > Firebase Auth handles identity and sessions. On login, user role and schoolId are loaded from Firestore. The Node API uses JWT for its own protected routes.

4. **"How does your app separate user data?"**
   > All data is scoped by schoolId. Users can only access data for their school. Role checks happen at the controller level.

5. **"Where is your business logic located?"**
   > In the `domain/` layer — service classes. Never in the UI. The UI calls controllers, controllers call services, services talk to repositories.

6. **"Walk me through your database design."**
   > 10 tables: schools, users, students, teachers, classes, student_classes, teacher_classes, parent_students, attendance, attendance_history. Fully normalized, foreign keys enforced, indexed for the most common queries. Multi-tenant — every table scoped by school_id.

7. **"Why did you design your attendance table with a unique key on (school_id, student_id, attendance_date, shift_type)?"**
   > To enforce idempotency — a student cannot have two attendance records for the same shift on the same day in the same school. Data integrity enforced at the database level, not just the app level.

8. **"What is the `source` field on your attendance table?"**
   > It tracks how the record was created — `studentSelf` (student clocked in via app), `teacherBatch` (teacher marked the class), or `adminEdit` (admin corrected a record). This is for audit and anti-fraud purposes, and it mirrors the AttendanceSource enum in the Flutter app.

9. **"Why do you have an attendance_history table?"**
   > It's an append-only audit trail. Every time a teacher or admin changes an attendance status, we insert a new row recording the old status, new status, who changed it, and when. We never update or delete history rows — that's the rule.

---

## Bonus Features (if time allows — high scoring)

- [ ] Dark/Light theme toggle
- [ ] Search and filtering on student list
- [ ] Attendance report export (PDF/CSV)
- [ ] Push notifications (FCM)
- [ ] Role-based access visible in UI

---

*Last updated: March 2, 2026 — Days 17, 18, 19 complete in one session. Full Phase 3 done. Flutter → Node → MySQL proven end-to-end across auth, students, and attendance. 13 days ahead of schedule. Next: Day 20 — end-to-end test, then Phase 4 (Flutter screen polish).*
