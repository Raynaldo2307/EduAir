# EduAir

A multi-tenant school management app built for Jamaican schools. EduAir provides attendance tracking with geofencing, role-based dashboards, and tools aligned with Jamaica's Ministry of Education (MoEYI) reporting requirements.

## Features

- **Geofenced Attendance** — Students clock in/out using GPS. The app verifies they are within the school's defined radius before recording attendance.
- **Shift-Aware Scheduling** — Supports morning, afternoon, and whole-day shifts, reflecting how many Jamaican schools operate split schedules.
- **MoEYI Late Reason Codes** — Late arrivals are categorized using government-standard reason codes (transportation, economic, illness, emergency, family) for Form SF4 compliance.
- **Role-Based Access** — Separate experiences for students, teachers, parents, admins, and principals.
- **Multi-Tenancy** — All data is scoped by school. Users select their school after authentication.
- **Teacher Batch Attendance** — Teachers can take attendance for their homeroom class in bulk.
- **Attendance History** — Calendar and list views of past attendance records.
- **Audit Trail** — All attendance actions are logged with timestamps and the acting user.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Client | Flutter 3.9.2+ |
| State Management | Riverpod |
| Backend | Firebase (Auth, Firestore, Storage) |
| Location | Geolocator |
| Auth Providers | Email/Password, Google Sign-In |
| Timezone | America/Jamaica (UTC-5) |

## Getting Started

### Prerequisites

- Flutter SDK `>=3.9.2`
- Dart SDK `>=3.9.2`
- Firebase project configured (Auth, Firestore, Storage)
- Xcode (for iOS) / Android Studio (for Android)

### Setup

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd edu_air
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Place your `google-services.json` (Android) in `android/app/`
   - Place your `GoogleService-Info.plist` (iOS) in `ios/Runner/`
   - The `firebase_options.dart` file is auto-generated via FlutterFire CLI

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/src/
├── core/             # Global providers, theme, module registry
├── models/           # Shared data models (AppUser, School)
├── services/         # Cross-feature services (UserService)
├── shared/           # Router, shared utilities
└── features/
    ├── auth/         # Sign in / sign up
    ├── attendance/   # Core attendance feature
    │   ├── data/     # Firestore data sources
    │   ├── domain/   # Service, models, exceptions
    │   ├── application/  # Riverpod controllers
    │   └── presentation/ # UI (student/, admin/)
    ├── admin/        # Admin tools (student management)
    ├── Teacher/      # Teacher attendance pages
    ├── shell/        # Navigation shells, school selection
    └── onboard_page/ # Onboarding flow
```

## Architecture

EduAir follows a layered architecture per feature:

```
UI (presentation) → Controller (application) → Service (domain) → Repository (data) → Firestore
```

- **UI** is thin — delegates all logic to controllers
- **Controllers** manage state via Riverpod and call domain services
- **Services** contain business rules and throw typed domain exceptions
- **Repositories** handle Firestore reads/writes

## User Roles

| Role | Access |
|------|--------|
| Student | Clock in/out, view attendance history |
| Teacher | Take class attendance, view own dashboard |
| Parent | View linked children's attendance |
| Admin | Manage students, view school-wide reports |
| Principal | Full access, same as admin with additional oversight |

## App Flow

1. **Splash** — Check auth state
2. **Onboarding** — First-time introduction screens
3. **Sign In / Sign Up** — Email or Google authentication
4. **Select Role** — User picks their role
5. **Select School** — User picks their school (multi-tenancy)
6. **Home** — Role-specific dashboard (StudentShell or TeacherShell)

## Commands

```bash
flutter run              # Run in debug mode
flutter build apk        # Build Android APK
flutter build ios         # Build iOS
flutter analyze           # Run static analysis
flutter test              # Run tests
```

## License

All rights reserved.
