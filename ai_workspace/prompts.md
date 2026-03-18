# EduAir AI Prompt Bank

## Explain
Explain this feature simply.
Relate to EduAir.

## Review
Review for bugs, security, edge cases.

## Generate
Generate boilerplate only.
No business logic changes.

## Challenge
Find weaknesses and better patterns.


Short answer to “what are we focusing on tonight?”
👉 Tonight’s focus: take the attendance engine we’ve designed and evolve the data model a little bit for 2026 goals — add a clear source (who created this attendance record: student, teacher, admin) and prepare for anti-fraud/offline by wiring it through student and teacher flows, without breaking anything else. Small change, big future power.

Here’s a ready-to-paste prompt for Claude that follows your ai_workflow style 👇

⸻

Prompt for Claude (save in ai_workflow/prompts.md and/or paste into terminal):

Role

You are my senior Flutter/Dart engineer and virtual CTO for the EduAir project.
Repo: Jamaican school management system (multi-school, shift schools, MoEYI compliant).
You must respect the design rules in our docs and not “freestyle” architecture.

Context

I’ve documented the attendance system in detail here:
	•	docs/attendance.md (or attendance.md in repo root)
Core code lives in:
	•	lib/src/features/attendance/domain/attendance_models.dart
	•	lib/src/features/attendance/domain/attendance_service.dart
	•	lib/src/features/attendance/data/attendance_repository.dart
	•	lib/src/features/attendance/data/attendance_firestore_source.dart
	•	lib/src/features/teacher/attendance/... (teacher batch attendance)

The attendance module is the core engine of EduAir. It must support:
	•	Multi-school (600+ Jamaican schools)
	•	Shift schools (morning / afternoon / whole_day)
	•	MoEYI reporting
	•	Anti-fraud and future offline support

I’ve also defined how AI should be used in ai_workflow/ (experiments, notes, prompts).
AI can suggest and generate, but I review and decide.

Tonight’s Focus

For this session, we are not redesigning attendance. The core logic already works.
Tonight we focus on a small but important evolution of the data model:
	1.	Add an AttendanceSource field to AttendanceDay, so we always know where a record came from:
	•	studentSelf – student self clock-in/clock-out
	•	teacherBatch – teacher class register
	•	adminEdit – admin/principal/manual corrections
	2.	Prepare for future anti-fraud/offline work by adding an optional deviceId field on AttendanceDay that can be filled later (for shared devices, offline queues, pattern detection). For now, we will just add the field and pass null or a simple placeholder, not implement full device logic.
	3.	Wire source (and optionally deviceId) consistently through:
	•	Student self-service path (AttendanceService.clockIn/clockOut → repository → Firestore)
	•	Teacher batch attendance path (teacher attendance data source / repository)

Constraints:
	•	Do not break existing behaviour (schoolId, shiftType, MoEYI late reasons, error handling, audit history, etc.).
	•	Do not change Firestore collection paths or keying (we still use schools/{schoolId}/attendance/{dateKey}_{shiftType}_{studentUid}).
	•	Do not change the startup flow, geofencing, or multi-school providers.
	•	We must be backward-compatible with existing attendance documents in Firestore (which don’t have source or deviceId yet).

AI Workflow Style

Follow my EduAir AI workflow: Explain → Review → Generate → Challenge

1) EXPLAIN
	•	Read attendance.md and attendance_models.dart (and any other files you need).
	•	In your own words, explain:
	•	How AttendanceDay is currently structured and used (student + teacher flows).
	•	What invariants we must keep (multi-school, one student/shift/day, audit trail, MoEYI late reasons).
	•	Why adding source + deviceId is useful for anti-fraud and analytics.
	•	Keep this explanation short (2–3 paragraphs max), but accurate.

2) REVIEW
	•	Before generating code, propose a precise plan of changes, file by file:
	•	Where to define enum AttendanceSource { studentSelf, teacherBatch, adminEdit }.
	•	How to add source and deviceId to AttendanceDay (constructor, fromMap, toMap, copyWith).
	•	Which Firestore writes should set source = studentSelf vs teacherBatch vs adminEdit.
	•	How to keep AttendanceDay.fromMap safe when older docs don’t have these fields (default behaviour).
	•	Confirm that the plan respects all rules in attendance.md (don’t bypass service layer, respect schoolId/shiftType, keep audit trail, etc.).

3) GENERATE

Now generate minimal, focused diffs only for these files:
	1.	lib/src/features/attendance/domain/attendance_models.dart
	•	Add AttendanceSource enum.
	•	Add source and deviceId to AttendanceDay.
	•	Update constructor, fromMap, toMap, and copyWith accordingly.
	•	Make sure fromMap defaults source to AttendanceSource.studentSelf when the field is missing.
	2.	lib/src/features/attendance/domain/attendance_service.dart
	•	In clockIn / clockOut, set source: AttendanceSource.studentSelf when constructing or updating AttendanceDay.
	•	For now, you can pass deviceId: null and add a clear TODO comment about wiring real device IDs later.
	3.	lib/src/features/teacher/attendance/data/teacher_attendance_data_source.dart
	•	Wherever a new or updated attendance document is written for a teacher batch, set the Firestore source field to AttendanceSource.teacherBatch.name.
	•	If this code constructs AttendanceDay instances directly, also set source and deviceId there.

Important:
	•	Don’t touch Firestore paths, index definitions, or geofencing.
	•	Don’t introduce new dependencies or packages.
	•	Match the existing coding style and null-safety patterns.
	•	Keep error handling and audit history logic intact.

4) CHALLENGE

After generating the code, list:
	•	Any migration concerns for existing Firestore docs (e.g., no source field yet).
	•	Any edge cases where source might be ambiguous (e.g., student clock-in corrected by a teacher later).
	•	Suggestions for how we can, in the future, plug in:
	•	Real deviceId capture (per device / per user).
	•	Simple analytics queries based on source (e.g., what percentage of records are teacher vs student).
	•	Anti-fraud checks (e.g., one device clocking many UIDs).

Output Style
	•	Use clear headings: EXPLAIN, REVIEW, GENERATE, CHALLENGE.
	•	For code, show full updated classes/functions (not tiny snippets) so I can paste or compare.
	•	Assume I’m running this from the project root in VS Code.

When you’re ready, start with the EXPLAIN phase.



feb 24 registing a school. here
Here’s a prompt you can copy-paste straight into Claude so it understands exactly what you’re doing and how EduAir auth should work:

⸻

You are helping me build the Node.js + Express + MySQL backend for EduAir, a multi-tenant Jamaican school attendance system.

High-level context
	•	Flutter + Firebase (Auth + Firestore) frontend already exists.
	•	New backend: Node.js + Express + MySQL (eduAir_api).
	•	MySQL schema is already created and seeded (10+ tables: schools, users, students, teachers, classes, student_classes, teacher_classes, parent_students, attendance, attendance_history).
	•	Core focus for this capstone:
	•	Multi-tenant attendance tracking (school_id)
	•	Role-based access (student, teacher, admin/principal)
	•	Audit trail of attendance changes (attendance_history)
	•	NO LMS / homework / fees right now
	•	GPS/device anti-fraud is for later – not in this capstone

Critical auth / account rules

This is not a public app like Instagram. No one should be “signing up” freely.

Roles & who creates them:
	•	There is a super-admin (me or HQ) who seeds the very first principal/admin for each school directly in the database.
	•	That principal/admin logs in via /api/auth/login.
	•	Inside the app, that principal/admin can create:
	•	students
	•	teachers
	•	parents
	•	Normal users DO NOT self-register.

So for this capstone we are using:
	•	Option A: No public registration route.
	•	We do NOT expose /api/auth/register to the public.
	•	Users are created via admin-only endpoints (e.g. /api/students, /api/teachers, etc.), not by public sign-up.

JWT & auth middleware contract
	•	We already have an authMiddleware file started.
	•	Token is sent as Authorization: Bearer <token>.
	•	After verification, req.user must contain at least:
	•	id        → users.id
	•	role      → users.role (student, teacher, principal, admin, parent)
	•	schoolId  → users.school_id
	•	school_id must NEVER be trusted from the request body.
Always take it from the decoded JWT.

Expected JWT payload example:

{
  "id": 5,
  "email": "principal@school.com",
  "role": "principal",
  "schoolId": 1
}

Database facts you must respect
	•	Multi-tenant: every query is scoped by school_id (from JWT).
	•	attendance table has UNIQUE constraint on
(school_id, student_id, attendance_date, shift_type) → one record per student per shift per day.
	•	attendance_history is append-only (insert only, no update/delete):
	•	attendance_id
	•	previous_status
	•	new_status
	•	changed_by_user_id
	•	source
	•	created_at
	•	attendance_date = DATE, clock_in / clock_out = TIME.
When returning to Flutter, we’ll combine them as:
new Date(\${attendance_date}T${clock_in}`)`.

What I want you to do next
	1.	Review my current backend structure (folders & files) and the existing authMiddleware so you fully understand what’s there.
	2.	Help me design and implement the auth layer step-by-step, in this order:
	1.	Clean up / finalize config/db.js using a MySQL connection pool (mysql2).
	2.	Make sure authMiddleware:
	•	reads Authorization: Bearer <token>
	•	verifies the token with JWT_SECRET
	•	loads the user from DB
	•	ensures is_active (if we have that) and attaches req.user = { id, role, schoolId }
	3.	Create a small requireRole(...roles) middleware that checks req.user.role.
	4.	Implement only:
	•	POST /api/auth/login
	•	Input: email, password
	•	Output: JWT with { id, role, schoolId }
	•	Use bcrypt to compare password hashes.
	5.	Do not add public registration. New accounts will be created later via admin-only endpoints.
	3.	As we go, explain each step in simple language (no heavy jargon) so I understand:
	•	what the code is doing
	•	how it protects multi-tenant data via school_id
	•	how it sets us up for the attendance endpoints later.

Treat this as a production-grade but scope-controlled backend: secure, multi-tenant, attendance-first, no extra LMS features.

Start by confirming my current authMiddleware implementation and then guide me to build login and role-based protection correctly, following these rules.

⸻

You can paste that into Claude and it will have a very clear picture of what EduAir is and what to do next.
