# Open Core HR Project Map

This document provides a high-level map of the codebase for quick orientation.

## 📂 Directory Structure

| Directory | Purpose |
| :--- | :--- |
| `lib/api` | API routes (`api_routes.dart`), API service (`api_service.dart`), and networking utilities. |
| `lib/components` | Reusable UI components (buttons, headers, etc.). |
| `lib/db_models` | Local database models (Hive). |
| `lib/locale` | Localization files and language strings. |
| `lib/models` | Data models (JSON serializable). Organized by feature (Assets, Loan, etc.). |
| `lib/screens` | Main application screens. Organized by feature module. |
| `lib/service` | Business logic services (Map, Permissions, Modules). |
| `lib/store` | MobX stores for state management. |
| `lib/utils` | App constants, theme data (`app_theme.dart`), and providers. |
| `assets/` | Images, animations (Lottie), and JSON configs. |
| `.agent/skills/`| Specialized SOPs for 100x speed development. |

## 🔑 Key Files

- `lib/main.dart`: App entry point, Hive initialization, Global store setup, Firebase setup.
- `lib/routes.dart`: Route definitions for navigation.
- `lib/api/api_service.dart`: Centralized API call logic.
- `design_system.json`: The source of truth for UI/UX styles.
- `pubspec.yaml`: Project dependencies and package configuration.

## 🧠 Specialized AI Skills

Available in `.agent/skills/`:
- **Open Core HR**: General architecture and architecture standards.
- **Bug Prevention**: Critical stability checks for API and state.
- **State Management (MobX)**: Deep dive into MobX stores and UI observers.
- **UI Redesign System**: Guidelines for implementing the premium design system.
- **Hive Persistence**: Management of local database adapters and boxes.
- **Networking Patterns**: SOP for extending APIs and services.
- **Module Integration**: How to register and toggle new features.
- **Localization (i18n) SOP**: Workflow for multi-language support.
- **Premium UI Recipes**: Code snippets for glassmorphism, buttons, and layouts.
- **Dynamic Form Builder**: Documentation for the dynamic metadata-driven form system.

### 📦 Feature Module Skills

Detailed implementation guides for specific app modules (located in `.agent/skills/modules/`):
- **Attendance & Tracking**: Geofencing, QR code, and location logic.
- **Payroll & Financials**: Payslip downloading and EMI calculation logic.
- **HR Management**: Workflow for Leave, Expenses, and Document requests.
- **Asset & Inventory**: Serialization and tracking of company property.
- **Collaboration & Communication**: Tasks, Notices, Chat, and Agora Voice calls.

## 🚀 Common Command Cheatsheet

- **Update Models / Stores**: `dart run build_runner build --delete-conflicting-outputs`
- **Install Dependencies**: `flutter pub get`
- **Check for Outdated Packages**: `flutter pub outdated`
- **Analyze Code**: `flutter analyze`
