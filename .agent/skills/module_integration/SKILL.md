# Module Integration Skill

This skill documents how to properly add and register a new feature module into the Open Core HR ecosystem.

## 🧱 Module Architecture

Modules are toggleable features. Their visibility is controlled by the backend via `ModuleService`.

### Step 1: Backend Flag
Ensure your `ModuleSettingsModel` in `lib/models/Settings/module_settings_model.dart` has a boolean flag for the new module.

### Step 2: Register in ModuleService
Add a check in `lib/service/module_service.dart`:
```dart
bool isMyNewModuleEnabled() {
  var modules = getModuleSettings();
  if (modules == null) return false;
  return modules.isMyNewModuleEnabled ?? false;
}
```

### Step 3: Conditional UI
In the Dashboard or Sidebar, wrap the entrance to your module:
```dart
if (moduleService.isMyNewModuleEnabled())
  ModuleCard(
    title: "My Feature",
    onTap: () => MyFeatureScreen().launch(context),
  ),
```

### Step 4: Routing
Add the screen to the named routes in `lib/routes.dart` if deep-linking or structured navigation is required.

## 🧩 Structure of a Module Folder
When creating a new module, follow this organization:
- `lib/screens/MyModule/` (UI Screens)
- `lib/screens/MyModule/Widgets/` (Module-specific components)
- `lib/models/MyModule/` (Data models)
- `lib/store/my_module_store.dart` (State)

## 🚀 Pro-Tip: "Graceful Degraded Mode"
If a module is disabled while a user is on the screen, the `ApiService` should return a clear error or the UI should show a "Module Disabled" empty state using `server_unreachable_screen.dart` patterns.
