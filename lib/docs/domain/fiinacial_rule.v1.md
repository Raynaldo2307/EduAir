# Finance / Fees Rules V1 (Business Spec)

**Version:** 0.1 (draft)  
**Date:** 2026-01-04  

## 1. Scope

This module tracks **school fees and payments per student per school**.

Includes:
- Issuing fee invoices to students for a term.
- Recording payments against those invoices.
- Showing balances to students and parents.

Excludes (for now):
- Online payment gateway integration.
- Automatic late fees.
- Multi-currency support.

## 2. Entities & IDs

- `School`:
  - `schoolId` (string)
- `AppUser`:
  - `uid`
  - `role` (student, parent, admin)
  - `schoolId`
- `Invoice`:
  - `invoiceId` (generated)
  - `schoolId`
  - `studentUid`
  - `termId`
  - `amount`
  - `status` (`pending`, `paid`, `partial`, `cancelled`)
- `Payment`:
  - `paymentId`
  - `schoolId`
  - `studentUid`
  - `invoiceId`
  - `amount`
  - `method` (cash, card, bank, online)
  - `timestamp`

Firestore layout (planned):
- `schools/{schoolId}/fees/invoices/{invoiceId}`
- `schools/{schoolId}/fees/payments/{paymentId}`

All queries are **school-scoped by `schoolId`**.

## 3. Time Rules

- All finance timestamps use the **school’s timezone** (same as attendance).
- “Overdue” is defined as: `now > invoice.dueDate` AND `status != paid`.
- Grace periods and late fees will be added in a future version.

## 4. Core Rules

### Issuing an invoice

- Only users with role `admin` or `finance` for a given `schoolId` can create invoices.
- An invoice must specify:
  - `schoolId`, `studentUid`, `termId`, `amount`, `dueDate`.
- Initial status is always `pending`.

### Recording a payment

- Only `admin/finance` can create a payment record.
- Payment must reference:
  - `schoolId`, `studentUid`, `invoiceId`, `amount`.
- After saving a payment:
  - Recompute total paid for that invoice.
  - Set invoice.status:
    - `paid` if totalPaid == amount.
    - `partial` if 0 < totalPaid < amount.
    - `pending` if totalPaid == 0.

### Student / Parent visibility

- Student can only see invoices/payments where:
  - `studentUid == currentUser.uid`
  - AND `schoolId == currentUser.schoolId`
- Parent can only see invoices/payments for their linked children.

## 5. Statuses & Transitions

Invoice statuses:
- `pending` → `partial` (first payment lower than full amount)
- `pending` → `paid` (single full payment)
- `partial` → `paid` (remaining balance paid)
- `pending`/`partial` → `cancelled` (admin only)

Payment statuses are immutable (no edit for v1); corrections are done by extra “adjustment” records.

## 6. UI-Only vs Persisted Rules

UI-only:
- Show “Overdue” label in red if:
  - `status` in (`pending`, `partial`) AND `now > dueDate`.

Persisted:
- `status` field of invoice (`pending`, `partial`, `paid`, `cancelled`).
- Payment documents.

## 7. Multi-School & Security

- Every invoice and payment is saved under a `schoolId` path.
- Admins/finance staff must have a role tied to that `schoolId`.
- A principal at School A cannot see invoices/payments of School B.

## 8. Future Work

- Integrate payment gateway and store transaction IDs.
- Automatic cron job to:
  - Mark invoices as `overdue` or compute late fees.
- Finance dashboard for principals:
  - “Total fees billed vs paid by term”.