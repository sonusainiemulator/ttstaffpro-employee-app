# Open Core HR Mobile - Architectural Skill

This skill provides a comprehensive understanding of the Open Core HR Mobile application architecture, patterns, and standards. Use this as your primary reference for long-term development, feature extension, and UI/UX redesign.

## 🏗️ Core Architecture

The app follows a **Reactive Service-Oriented Architecture** using **MobX** for state management and **Hive** for local persistence.

### 1. Layers
- **UI (Screens & Components)**: Located in `lib/screens` and `lib/components`. Uses `Observer` widgets to react to store changes.
- **State Management (Stores)**: Located in `lib/store` and `lib/stores`. Contains the reactive state and business logic.
- **Service Layer**: Located in `lib/service`. Contains business logic, permissions handling, and helper functions.
- **API Layer**: Located in `lib/api`. Handles networking via a custom `http` wrapper in `network_utils.dart` and endpoint definitions in `api_routes.dart`.
- **Data Models**: Located in `lib/models`. Uses `json_serializable` and `hive_generator` for data serialization and persistence.

### 2. State Management (MobX)
- Stores are usually global instance or provided via `Provider`.
- Use `@observable` for state, `@computed` for derived state, and `@action` for modifications.
- Refer to `lib/main.dart` to see how stores like `AppStore`, `PayrollStore`, and `AssetStore` are initialized and provided.

### 3. Networking (The "Open Core" Pattern)
- **Base URL**: Defined in `APIRoutes.baseURL`. This must be updated for live deployment.
- **Headers**: Automatically built in `network_utils.dart` via `buildHeader()`. Supports `Bearer` tokens and `X-Tenant-ID` for SaaS mode.
- **Success Handling**: Always use `checkSuccessCase(response)` to validate API results.

### 4. Persistence (Hive)
- Boxes are opened in `main.dart`.
- Adapters are registered for each model type.
- Type IDs for Hive are managed in `lib/main.dart` (ensure no overlaps when adding new models).

---

## 🎨 Design System & UI/UX

The app is being transitioned to a modern, premium design system defined in `design_system.json`.

### Principles:
1.  **Vibrant & Modern**: Use the palette in `colorPalette.primary` (primarily `#696CFF`).
2.  **Glassmorphism & Gradients**: Use subtle gradients for cards and buttons as defined in the "components" section of `design_system.json`.
3.  **Typography**: Default to "Inter" / "Lufga" as specified.
4.  **Micro-animations**: Use Lottie (`assets/animations`) and built-in transitions.

### Key Components:
- **Buttons**: Use defined `primary`, `secondary`, and `fab` styles.
- **Cards**: Support `elevated`, `outlined`, and `colored` variants.
- **Inputs**: Use `filled` or `outlined` with the focus border color `#696CFF`.

---

## 🛠️ Coding Standards

- **Naming**: Use PascalCase for classes, camelCase for variables/functions, and snake_case for assets.
- **Imports**: ALWAYS use absolute imports relative to the package name (e.g., `import 'package:open_core_hr/...'`).
- **Identifier**: The package name in `pubspec.yaml` should be `open_core_hr` to match the imports.
- **Models**: Use `fromJson` and `toJson` for all data models. Ensure they include `@HiveType` if they need to be persisted.

---

## 🐛 Bug Prevention

- **Null Safety**: Strict adherence to Dart null safety.
- **API Robustness**: Always wrap API calls in `try-catch` and handle offline scenarios via `isNetworkAvailable()`.
- **UI Overflow**: Use `SingleChildScrollView`, `Flexible`, or `Expanded` to prevent layout overflows on different screen sizes.
- **Loading States**: Always manifest loading states in the UI when fetching data.

---

## 🚀 Pro-Tips for Gemini Agents
- **Context**: When asked to add a feature, check the corresponding `Store` first. If it doesn't exist, create it.
- **Refactoring**: When redesigning a screen, refer to `design_system.json` for EXACT values of padding, radius, and color.
- **Errors**: Check `lib/api/network_utils.dart` to understand how the app handles 401 (Logout) and 400 (Bad Request) errors.
