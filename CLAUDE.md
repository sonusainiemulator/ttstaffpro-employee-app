# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**TT Staff Pro** — Flutter-based employee HRMS app (package: `open_core_hr`) connecting to a Laravel backend at `https://ttstaffpro.in/api/V1/`. Current version: `5.0.3+6`.

---

## Commands

```bash
# Run app
flutter run

# Run on specific device
flutter run -d <device-id>

# Build
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release --obfuscate --split-debug-info=./coverage/html

# Generate MobX code (required after changing any @observable/@action/@computed fields)
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs

# Lint
flutter analyze

# Tests
flutter test
flutter test test/specific_test.dart
```

**Important:** After modifying any MobX store (`*.dart` with `part '*.g.dart'`), you must regenerate the `.g.dart` file or the app will fail to compile.

---

## Architecture

### State Management — MobX + Provider

Global singleton stores are instantiated in [lib/main.dart](lib/main.dart) and accessed directly throughout the app:

```dart
AppStore appStore = AppStore();                        // theme, language, user status
GlobalAttendanceStore globalAttendanceStore = ...;     // check-in/out logic
FormBuilderStore formBuilderStore = ...;
PayrollStore payrollStore = ...;
AssetStore assetStore = ...;
ApiService apiService = ApiService();                  // legacy HTTP client
SharedHelper sharedHelper = SharedHelper();            // SharedPreferences helpers
ModuleService moduleService = ModuleService();         // feature-flag checks
MapHelper mapHelper = MapHelper();
PermissionService permissionService = PermissionService();
```

Every store has a corresponding `*.g.dart` generated file. Stores live in [lib/store/](lib/store/) (primary) and [lib/stores/](lib/stores/) (legacy location for `leave_store.dart`).

`LeaveStore` and `AssetStore` are also provided via `MultiProvider` in `MyApp` for screens that use `Provider.of<>`.

### Two API Layers (use Dio for all new work)

**New (preferred) — Dio-based repository pattern** in [lib/api/dio_api/](lib/api/dio_api/):
- `DioApiClient` — singleton Dio client with 30s timeouts, auto-auth, JSON headers
- `BaseRepository` — extend this for all new repositories; provides `safeApiCall`, `safeApiCallList`, `safeApiCallWithResponse`
- Repositories in [lib/api/dio_api/repositories/](lib/api/dio_api/repositories/) — one file per domain (attendance, payroll, leave, loan, assets, etc.)
- Interceptors: `AuthInterceptor` (injects Bearer token), `ErrorInterceptor`, `NetworkInterceptor`

**Legacy — `ApiService`** in [lib/api/api_service.dart](lib/api/api_service.dart):
- Uses `network_utils.dart` (`postRequest`/`getRequest` with `http` package)
- Do not add new methods here; migrate to Dio repositories when touching existing methods

All API route strings are defined as constants in [lib/api/api_routes.dart](lib/api/api_routes.dart). Add new endpoints there.

### Module Feature Flags

Every feature screen should be gated by `moduleService.is<Feature>ModuleEnabled()`. Module settings are fetched from the server and cached in SharedPreferences (`appModuleSettingsPref`). The nav bar conditionally shows Leave and Expense tabs based on these flags. See [lib/service/module_service.dart](lib/service/module_service.dart).

### Navigation

The app uses a flat named-route map ([lib/routes.dart](lib/routes.dart) — currently empty) plus `nb_utils` `.launch()` extension for imperative navigation. Bottom navigation lives in [lib/screens/navigation_screen.dart](lib/screens/navigation_screen.dart) with 4 tabs: Home, Leave (conditional), Expense (conditional), Account.

Authentication flow: `SplashScreen` → `LoginScreen` (or `OrgChooseScreen` in SaaS mode) → `PermissionScreen` → `NavigationScreen`.

### Offline / Local DB (Hive)

Hive boxes are opened at startup in `main()`. Registered adapters and their box names:
- `noticeBoardBox` — `NoticeModel`
- `leaveTypeBox` — `LeaveTypeModel`
- `expenseTypeBox` — `ExpenseTypeModel`
- `documentTypeBox` — `DocumentTypeModel`
- Asset boxes (5–13) — `AssetModel`, `AssetAssignmentModel`, `AssetDocumentModel`, and related info models

DB model source files live in [lib/db_models/](lib/db_models/) (domain and client models for offline sync).

### SaaS vs Non-SaaS Mode

`getIsSaaSMode()` reads from SharedPreferences (`isSaaSModePref`). In SaaS mode, the user first selects their organization (`OrgChooseScreen`), which sets the tenant and base URL. Logout routes to `OrgChooseScreen` in SaaS mode, `LoginScreen` otherwise.

The base URL is stored in SharedPreferences key `baseurl`; `DioApiClient` reads it on each instantiation. Tenant identification uses an `X-Tenant-ID` header (not a subdomain).

### Localization

`BaseLanguage` ([lib/locale/languages.dart](lib/locale/languages.dart)) is the abstract class for all UI strings. `language` is a global variable set in `AppStore.setLanguage()`. Always use `language.lblSomething` for user-facing strings — never hardcode English text.

### Theme

`AppThemeData.lightTheme` / `darkTheme` in [lib/utils/app_theme.dart](lib/utils/app_theme.dart). Primary color is user-selectable and stored in SharedPreferences (`appColorPrimaryPref`). Access via `appStore.appColorPrimary`. Font: Poppins (Google Fonts).

---

## Key Patterns

**Creating a new feature screen:**
1. Add route constant (if needed) in `api_routes.dart`
2. Create a repository extending `BaseRepository` in `lib/api/dio_api/repositories/`
3. Create a MobX store if state is complex; run `build_runner` after
4. Add a module guard: `if (moduleService.isMyModuleEnabled()) ...`
5. Gate the feature in `HomeScreen._buildModulesList()` and any nav entry points
6. Use `language.lbl...` for all strings

**SharedPreferences access:** Use `nb_utils` helpers — `getStringAsync(key)`, `getBoolAsync(key)`, `setValue(key, value)`. All pref keys are constants in [lib/utils/app_constants.dart](lib/utils/app_constants.dart).

**Date formatting:** Use the global formatters from `main.dart`:
- `formatter` — `dd-MM-yyyy`
- `dateTimeFormatter` — `dd-MM-yyyy hh:mm a`
- `formDateFormatter` — `yyyy-MM-dd` (for API payloads)
- `timeFormat` — `hh:mm a`
