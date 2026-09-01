# TT Staff Pro — Codebase Index

> Auto-generated index of the repository structure to help agents & developers navigate the codebase.
> App: **TT Staff Pro** (Flutter HRMS employee app, `open_core_hr` fork) · Backend: Laravel `https://ttstaffpro.in/api/V1/`

---

## Root Layout

| Path | Purpose |
|---|---|
| `lib/` | Main employee app source code |
| `apps/ttstaffpro_attend/` | Sub-app: attendance-focused Flutter app |
| `apps/ttstaffpro_face_attendance/` | Sub-app: face recognition attendance kiosk |
| `android/`, `ios/`, `web/` | Platform hosts for the main app |
| `assets/` | Lottie animations, GIFs, map styles, images |
| `fonts/` | Lufga font family |
| `docs/` | BRDs, PRDs, roadmaps, troubleshooting |
| `scripts/` | Utility scripts (`update_deps.sh`) |
| `test/` | Unit tests (face attendance, passkey, token storage, parsing) |
| `distribution/whatsnew/` | Release "what's new" notes |

---

## `lib/` — Main App

### Entry & Routing
- `main.dart` — app bootstrap, Firebase init, theme, localization
- `routes.dart` — named route table
- `firebase_options.dart` — generated Firebase config

### `lib/api/` — Networking
- `api_service.dart`, `api_routes.dart`, `config.dart` — legacy HTTP layer & endpoint constants
- `network_utils.dart` — connectivity helpers
- `pdf_api.dart` — PDF download/open helpers
- `result.dart` — result wrapper type
- `dio_api/` — newer Dio-based layer:
  - `dio_client.dart`, `base_repository.dart`
  - `interceptors/` — auth/logging interceptors
  - `repositories/` — feature repositories (incl. face attendance, passkey)
  - `exceptions/`

### `lib/screens/` — UI (feature folders)
Account, Assets, Attendance, AttendanceHistory, AttendanceRegularization, Banned, Calendar, ChangePassword, DigitalId, Disciplinary, Document, Expense, FaceAttendance, ForgotPassword, Holidays, Home, HRPolicies, Language, Leave, Loan, Login, Maps, MyTimeLine, NoticeBoard, Notification, Offline, OfflineMode, Payroll, Payslip, Permission, Scanner, Settings, SettingUp, Support, UserProfile
- Top-level: `splash_screen.dart`, `navigation_screen.dart`, `org_choose_screen.dart`, `domain_screen.dart`, `language_screen.dart`, `about_app_screen.dart`, `privacy_screen.dart`, `server_unreachable_screen.dart`

### `lib/store/` & `lib/stores/` — State (MobX)
- `AppStore.dart` — global app state (user, org, theme, language)
- Feature stores: `asset_store`, `payroll_store`, `document_management_store`, `form_builder_store`, `global_attendance_store`, `leave_store`
- `*.g.dart` — generated MobX files (regenerate via `dart run build_runner build --delete-conflicting-outputs`)

### `lib/models/` — Data models (JSON serialization)
Dashboard, user, attendance history, calendar events, expenses, holidays, leaves, notices, notifications, payroll/payslip, salary structure, schedules, messages, plus subfolders: `Approval/`, `Assets/`, `Attendance/`, `disciplinary/`, `Document/`, `Expense/`, `face_attendance/`, `FormBuilder/`, `HRPolicies/`, `leave/`, `Loan/`, `OnBoarding/`, `payroll/`, `Settings/`, `status/`

### `lib/db_models/` — Local DB / sync models
Clients, domains, visits (offline sync support)

### `lib/components/` — Reusable UI components
Dashboard widgets (greeting, attendance info, shifts, live attendance, distance, expense), attendance status, support, custom app bar

### `lib/service/` — Services
`background_sync_service`, `socket_service` (realtime), `passkey_service`, `permission_service`, `module_service`, `map_helper`, `SharedHelper` (local storage)

### `lib/utils/` — Helpers
Theme (`app_theme`, `design_system`, `app_colors`), constants, images, widgets, date utils/parsers, `token_storage` (secure storage), `url_helper`, string extensions, bottom nav

### `lib/locale/` — Localization
`app_localizations.dart` + 17 language files (en, hi, ar, bn, de, es, fr, id, it, ja, ko, pt, ru, ta, te, th, tr, vi)

### `lib/Widgets/`
Shared widgets: `button_widget`, `text_widget`, `home_attendance_loading_widget`

---

## Sub-apps (`apps/`)

- **ttstaffpro_attend** — lightweight attendance app (`lib/`, `android/`, `test/`)
- **ttstaffpro_face_attendance** — face attendance kiosk (full Flutter app: android/ios/linux/macos/web/windows, docs, security roadmap)

> Both are tracked in this same git repo — not separate repos.

---

## Key Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after MobX edits
flutter analyze
flutter test
flutter build apk --release
```

## Conventions
- Conventional Commits (`feat:`, `fix:`, `chore:`, …) — see `AGENTS.md`
- Version in `pubspec.yaml` (`X.Y.Z+build`), changelog in `CHANGELOG.md`
- Push to `origin main` after every completed task
