# Localization (i18n) SOP Skill

This skill provides the standard workflow for adding multi-language support to new features.

## 🌍 The Locale System

The app utilizes `BaseLanguage` abstractions located in `lib/locale`.

### Step 1: Add to BaseLanguage
Open `lib/locale/languages.dart` and add the new abstract getter:
```dart
abstract class BaseLanguage {
  // ...
  String get lblMyNewFeatureTitle;
}
```

### Step 2: Implement in Language Files
Add the translation to EVERY file in `lib/locale/`:
- `LanguageEn.dart` (English)
- `LanguageAr.dart` (Arabic)
- ...etc.

```dart
@override
String get lblMyNewFeatureTitle => "My New Feature";
```

### Step 3: Use in UI
Access the translated string via the global `language` variable:
```dart
Text(language.lblMyNewFeatureTitle, style: boldTextStyle())
```

## 🛠️ Best Practices
1. **No Hardcoded Strings**: Never use raw strings like `Text("Hello")`. Always add them to the localization system.
2. **Contextual Prefixing**: Use prefixes to keep the language files organized:
   - `lbl...`: Labels
   - `hint...`: Input Hints
   - `msg...`: Snackbar/Alert messages
   - `error...`: Error strings
3. **Plurals & Interpolation**: For dynamic strings, use methods instead of getters:
   ```dart
   String itemsFound(int count) => "$count items found";
   ```

## 🚀 Pro-Tip: Right-to-Left (RTL)
The app supports Arabic. When designing UI, ensure you use `Directionality.of(context)` check or use `nb_utils` responsive padding if layout needs mirroring.
