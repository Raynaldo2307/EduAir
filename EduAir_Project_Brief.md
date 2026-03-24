# EduAir — Project Brief & Technical Documentation
### CSC1002 Final Capstone Project | Amber Academy | Cohort 4, 2026
**Student:** Raynaldo Montague
**Date:** March 2026

---

## 1. Problem Statement

Jamaican schools rely heavily on paper-based attendance registers. This system is slow, error-prone, and cannot produce the real-time reports required by the Ministry of Education, Youth and Information (MoEYI) for government compliance reporting (Form SF4).

Schools operating on a shift system face additional complexity — morning and afternoon shifts are legally treated as separate school days, making manual tracking even harder to manage consistently.

There is no affordable, purpose-built mobile solution designed around how Jamaican schools actually operate.

---

## 2. Target Users

| Role | Description |
|------|-------------|
| **Admin / Principal** | Manages the school — registers students and staff, views attendance reports |
| **Teacher** | Takes daily attendance for their homeroom class |
| **Student** | Views their own attendance record and history in real time |

---

## 3. The Solution

**EduAir** is a multi-role mobile school management application built specifically for Jamaican schools.

- Admins register students and staff — the system **auto-generates secure login credentials**
- Teachers take **batch attendance** for their entire homeroom class in one session
- Students see their attendance **updated in real time** — including clock-in time, status, and history
- Late arrivals must select a **MoEYI-approved reason category** (transportation, economic, illness, emergency, family) for Form SF4 compliance — free text is not permitted
- All data is **scoped by school** — no cross-school data exposure

---

## 4. Technical Stack

| Layer | Technology |
|-------|------------|
| Mobile Client | Flutter 3.9.2+ / Dart |
| State Management | Riverpod |
| Backend API | Node.js + Express 5 |
| Database | MySQL |
| Authentication | JWT + bcryptjs |
| HTTP Client | Dio + flutter_secure_storage |
| Location | Geolocator |

---

## 5. System Architecture

```
Flutter App (Mobile)
        ↓
Dio HTTP Client + JWT Interceptor
        ↓
Node.js + Express REST API
        ↓
MySQL Database
```

**Architecture principle:** Business logic never lives in the UI.

```
UI (Presentation)
    ↓
Controller (Riverpod — Application Layer)
    ↓
Repository (Data Layer — Dio API calls)
    ↓
Node.js API (Routes → Controllers → MySQL)
```

---

## 6. Security Design

- Passwords hashed with **bcrypt (10 salt rounds)** — plain passwords never stored
- Every protected route requires a **JWT Bearer token**
- `authMiddleware` verifies token signature and expiry on every request
- `requireRole()` middleware blocks unauthorised roles from admin routes
- `school_id` always comes from the JWT — never from the request body
- **Self-registration is disabled** — only admins can create accounts

---

## 7. API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/login` | None | Login, returns JWT |
| GET | `/api/auth/me` | JWT | Get current user profile |
| GET | `/api/students` | Admin | List school students |
| POST | `/api/students` | Admin | Register student (auto-generates credentials) |
| PUT | `/api/students/:id` | Admin | Update student |
| DELETE | `/api/students/:id` | Admin | Soft delete student |
| GET | `/api/staff` | Admin | List school staff |
| POST | `/api/staff` | Admin | Register staff (auto-generates credentials) |
| PUT | `/api/staff/:id` | Admin | Update staff |
| DELETE | `/api/staff/:id` | Admin | Soft delete staff |
| GET | `/api/attendance` | JWT | Get attendance records |
| POST | `/api/attendance/batch` | Teacher | Save batch attendance |
| GET | `/api/classes` | JWT | List classes for school |

---

## 8. Database Schema

Full database schema is documented in the backend repository:

**[EduAir Node.js Backend → https://github.com/Raynaldo2307/EduAir-Node.js](https://github.com/Raynaldo2307/EduAir-Node.js)**

Tables: `schools`, `users`, `students`, `staff`, `classes`, `attendance_records`, `attendance_audit_logs`

---

## 9. Key Features

### CRUD Operations
- **Students** — Create, Read, Update, Soft Delete
- **Staff** — Create, Read, Update, Soft Delete
- **Attendance** — Create, Read, Update (admin override)

### Personalization
- Every user is greeted by name on their dashboard
- Role-based dashboards — student, teacher, and admin each see a different home screen
- Dark mode support across all screens
- User-specific data — students only see their own records

### Soft Delete
- Students and staff are never permanently deleted
- Deletion sets `status = inactive` — all history is preserved
- Can be reactivated at any time

---

## 10. Packages Used

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `dio` | HTTP client |
| `flutter_secure_storage` | Secure JWT storage |
| `geolocator` | GPS location for attendance |
| `flutter_animate` | UI animations |
| `intl` | Date and time formatting |

---

## 11. Source Code

| Repository | Link |
|------------|------|
| Flutter App | https://github.com/Raynaldo2307/EduAir |
| Node.js Backend | https://github.com/Raynaldo2307/EduAir-Node.js |

---

*EduAir — Learning Above Category 5*
