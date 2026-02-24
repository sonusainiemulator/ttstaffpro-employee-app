---
description: Guide for adding new features or redesigning existing screens.
---

### Adding a New Feature

1. **Model**
   - Create the Dart model in `lib/models`.
   - Add `@HiveType` if persistence is needed.
   - Run build runner: `dart run build_runner build --delete-conflicting-outputs`.

2. **API**
   - Add endpoint to `lib/api/api_routes.dart`.
   - Add fetch/post method to `lib/api/api_service.dart`.

3. **Store**
   - Create a MobX store in `lib/store`.
   - Add observables and actions for the new feature.
   - Register the store in `lib/main.dart` if it needs to be global.

4. **UI**
   - Create screen in `lib/screens`.
   - Use `design_system.json` for styling.
   - Add route in `lib/routes.dart`.

### Redesigning a Screen (The "Premium" Way)

1. **Review Design Tokens**
   - Check `design_system.json` for "colorPalette" and "components".
   - Use `696CFF` as the primary brand color.

2. **Update Widget Styles**
   - Replace standard `Material` widgets with custom implementations using `BoxDecoration`, `LinearGradient`, and `BoxShadow` from the design system.
   - Use `borderRadius: 20` for cards.
   - Add `Observer` to reactively update UI elements.

3. **Incorporate Micro-animations**
   - Add subtle hover/press effects using standard Flutter `AnimatedContainer` or `ScaleTransition`.
   - Check `assets/animations` for relevant Lottie files.
