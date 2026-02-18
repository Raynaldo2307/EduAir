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
