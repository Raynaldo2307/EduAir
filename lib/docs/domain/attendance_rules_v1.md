# <Module Name> Rules V1 (Business Spec)

**Version:** 1.0  
**Date:** YYYY-MM-DD  

## 1. Scope

- What this module controls (e.g. student daily attendance, school fees, etc.).
- What it does *not* cover yet.

## 2. Entities & IDs

- Core models (e.g. AppUser, School, Invoice, Payment).
- How they link:
  - user.uid
  - school.schoolId
  - invoiceId / attendance dateKey, etc.

## 3. Time & Locale Rules

- Timezone source (e.g. school timezone).
- Cutoff times / deadlines (e.g. due date, grace period).
- How “today”, “this month”, “this term” are computed.

## 4. Core Rules

List like bullets, **no code**, just logic:

- Who is allowed to do what (role-based).
- Preconditions (e.g. must belong to school, must have active status).
- Happy path.
- Error cases / blocked actions.

## 5. Statuses & State Machine

- All possible states (e.g. `pending`, `paid`, `overdue`, `refunded`).
- Allowed transitions:
  - pending → paid
  - pending → cancelled
  - paid → refunded (admin only)
  - etc.

## 6. UI-only Rules vs Persisted Rules

- What is just “display logic” (e.g. show “Overdue” in red after due date).
- What is actually written to Firestore (e.g. status: overdue).

## 7. Security / Multi-school

- How schoolId scopes data.
- Who can see which records (student, parent, teacher, principal).

## 8. Future Work

- Things you know you’ll add later (cron jobs, AI, analytics, etc.).