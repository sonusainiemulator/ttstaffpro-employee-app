# Bug Prevention & Stability Skill

This skill ensures that all code written for the Open Core HR app is robust, bug-free, and handles edge cases gracefully.

## 🛡️ Critical Checkpoints

### 1. API Response Validation
Never assume an API call returns data in the expected format without validation.
- **Wrong**: `data['values'][0]`
- **Right**:
```dart
if (!checkSuccessCase(response) || response?.data['values'] == null || (response!.data['values'] as List).isEmpty) {
  return [];
}
```

### 2. Identifier Consistency
The project uses `open_core_hr` as its library identification. If you see imports starting with anything else, it will break the build.
- **Action**: Always ensure `pubspec.yaml` name matches the imports. If renaming, a global search and replace of the package name in imports is mandatory.

### 3. Hive Box Management
Ensure boxes are open before use.
- **Standard**: Check `main.dart` for `await Hive.openBox(...)`. If you add a new box, register the adapter and open it there.
- **Types**: Assign unique `typeId` to new `@HiveType` models to avoid serialisation conflicts.

### 4. UI Memory Leaks
- ALWAYS dispose of `TextEditingController`, `ScrollController`, and `Stream` subscriptions in the `dispose()` method of `StatefulWidget`.
- With MobX, ensure `ReactionDisposer` are called when screens are popped.

### 5. Layout Stability
- Use `MediaQuery` to handle different screen sizes.
- Avoid hardcoded heights/widths for containers unless they are meant to be fixed (e.g., icons).
- Use `SafeArea` to avoid overlapping with system status bars or notches.

---

## 🚀 Performance Tips
- Use `const` constructors where possible.
- Wrap only relevant parts of the UI with `Observer`.
- Avoid heavy logic inside the `build()` method.

## 🔍 Debugging Workflow
1.  **Network**: Check `log` output in terminal. `network_utils.dart` logs every request and response.
2.  **State**: Use `log` inside MobX actions to trace data mutations.
3.  **UI**: Use the Flutter Inspector to find "overflowing" widgets.
