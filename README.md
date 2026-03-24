# EduAir

A multi-role school management mobile application built for Jamaican schools.
EduAir handles student registration, staff management, and attendance tracking —
all aligned with Jamaica's Ministry of Education, Youth and Information (MoEYI)
reporting requirements.

> Built as a Final Capstone Project — Amber Academy CSC1002, Cohort 4, 2026.

---

## What EduAir Does

Jamaican schools operate on a shift system — morning, afternoon, or whole day.
Each shift is treated as a legally separate school day. EduAir is built around
this reality.

- **Admin** registers students and staff. The system auto-generates login
  credentials (email + ID code) so the admin never sets passwords manually.

- **Teachers** take batch attendance for their homeroom class — mark each
  student present, absent, late, or excused in one session.

- **Students** see their own attendance record updated in real time — including
  clock-in time, status, and history.

- **Late arrivals** must select a MoEYI-approved reason category
  (transportation, economic, illness, emergency, family) for Form SF4
  government compliance. Free-text is not permitted.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile client | Flutter 3.9.2+ / Dart |
| State management | Riverpod |
| Backend API | Node.js + Express 5 |
| Database | MySQL |
| Authentication | JSON Web Tokens (JWT) + bcryptjs |
| HTTP client | Dio + flutter_secure_storage |
| Location | Geolocator |
| Timezone | America/Jamaica (UTC-5) |

---

## Architecture

EduAir follows a strict layered architecture. Business logic never lives in
the UI.

```
UI (presentation)
    ↓
Controller (application / Riverpod)
    ↓
Repository (data — Dio HTTP calls)
    ↓
Node.js API (Express routes → service → MySQL)
```

Every feature follows this structure:

```
feature/
├── data/           # API repository (Dio calls)
├── domain/         # Models, exceptions, business rules
├── application/    # Riverpod controllers / notifiers
└── presentation/   # Flutter UI pages
```

**Interview answer — "Where is your business logic?"**
> In the domain and application layers. The UI only calls controllers.
> Controllers call repositories. Repositories call the API.
> The UI never talks to the database directly.

---

## Security

- Passwords are hashed with **bcrypt (10 salt rounds)** before being stored.
  Plain passwords never touch the database.
- Every protected route requires a **JWT Bearer token** in the
  `Authorization` header.
- `authMiddleware` verifies the token signature, checks expiry, and confirms
  the user still exists in the database on every request.
- `requireRole('admin', 'principal')` middleware blocks unauthorised roles
  from accessing admin routes.
- `school_id` is always taken from the JWT — never from the request body.
  An admin can only read and write data for their own school.
- Self-registration is disabled. Only admins can create student and staff
  accounts. This prevents unauthorised access to school data.

---

## User Roles

| Role | What they can do |
|------|-----------------|
| **Student** | View own attendance, clock in/out, see history and calendar |
| **Teacher** | Take batch attendance for homeroom class, view own attendance |
| **Admin** | Register students and staff, view attendance reports, manage school |
| **Principal** | Same as admin with full oversight |

---

## Key Features

### Admin Dashboard
- Live student count pulled from the API
- Quick Actions: Manage Students, Manage Staff, Attendance Report, School Info
- Recent Students list

### Student Registration (Admin)
- Admin fills: first name, last name, sex, class, shift
- Backend auto-generates:
  - Email: `firstname.lastname@student.{school-domain}`
  - Student code: `PAP-2026-0001`
  - Password = student code (student changes on first login)
- Credentials dialog shown to admin immediately after creation

### Staff Registration (Admin)
- Admin fills: name, department, employment type, shift
- Backend auto-generates:
  - Email: `{initial}{lastname}@{school-domain}`
  - Staff code: `PAP-MATH-001`
  - Password = staff code

### Teacher Attendance (Batch)
- Teacher selects class and date
- List of students with Present / Absent / Late / Excused toggle per row
- Single "Save Attendance" button writes all records in one batch
- Shift type is locked to the school's configured shift (no manual selection)

### Student Attendance View
- Calendar view with colour-coded attendance per day
- Status strip showing today's status
- Full history list

### Error Handling
- All API calls are wrapped in `AppErrorHandler`
- No internet → "No internet connection. Please turn on Wi-Fi or mobile data."
- Server down → "Cannot reach the server. Please check your connection."
- Logout works offline — clears local JWT, no server call needed.

### Soft Delete
- Students and staff are never permanently deleted
- Remove sets `status = 'inactive'` — all attendance history is preserved
- Records can be reactivated at any time

---

## Project Structure

```
lib/
├── main.dart
└── src/
    ├── core/
    │   ├── app_providers.dart     # Global Riverpod providers
    │   ├── app_theme.dart         # Design tokens and colors
    │   └── app_error_handler.dart # Centralised error → user message mapping
    ├── models/
    │   └── app_user.dart          # Central user model (all roles)
    ├── services/
    │   ├── api_client.dart        # Dio + JWT interceptor
    │   └── token_storage_service.dart
    ├── shared/
    │   └── app_router.dart        # Named route configuration
    └── features/
        ├── auth/                  # Sign in, forgot password
        ├── attendance/            # Student clock in/out, history
        ├── admin/
        │   ├── home/              # Admin dashboard
        │   ├── students/          # Student CRUD
        │   ├── staff/             # Staff CRUD
        │   └── attendance/        # Attendance report
        ├── Teacher/               # Teacher batch attendance
        ├── student/               # Student profile and home
        ├── settings/              # Role-aware settings + logout
        └── shell/                 # Navigation shells per role
```

---

## Running the Project

### Requirements

- Flutter SDK `>=3.9.2`
- Node.js `>=18`
- MySQL `>=8`
- Xcode (iOS) or Android Studio (Android)

### 1 — Backend (Node.js API)

```bash
cd eduair_api
npm install
# Create .env with: DB_HOST, DB_USER, DB_PASS, DB_NAME, JWT_SECRET, JWT_EXPIRES_IN, PORT=3000
npm run dev
```

### 2 — Flutter App

```bash
cd edu_air
flutter pub get
flutter run
```

> **Device note:** Update `_devIp` in `lib/src/services/api_client.dart`
> to your Mac's local IP when testing on a physical device.
> Run `ipconfig getifaddr en0` to find it.

---

## Demo Flow

```
1. Login as Admin
   → AdminHomeScreen shows student count and quick actions

2. Admin → Manage Students → Add Student
   → Fill name, sex, class, shift
   → System generates: tia.clarke@student.papine.edu.jm / PAP-2026-0001
   → Credentials dialog shown

3. Admin → Manage Staff → Add Staff
   → Fill name, department
   → System generates: mbrown@papine.edu.jm / PAP-MATH-001

4. Login as Teacher (Mark Brown)
   → Attendance tab → select Class 10A
   → Mark Tia Clarke: Present → Save

5. Login as Student (Tia Clarke)
   → Home shows: Present today ✅
   → Calendar shows today marked green
```

---

## Database Schema

The full database schema — all tables, columns, foreign keys, and indexes — is documented in the backend repository:

**[View Database Schema → EduAir Node.js Backend README](https://github.com/Raynaldo2307/EduAir-Node.js)**

The backend README covers: `schools`, `users`, `students`, `staff`, `classes`, `attendance_records`, and `attendance_audit_logs` tables with their relationships.

---

## API Endpoints

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

## License

All rights reserved. © 2026 EduAir.
