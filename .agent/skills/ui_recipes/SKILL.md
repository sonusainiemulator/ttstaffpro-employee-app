# Premium UI Recipes Skill

This skill provides ready-to-use "recipes" for the premium UI redesign, based on `design_system.json`.

## 💎 The "Glass" Card
Use this for dashboard items or feature cards.
```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  ),
  child: child,
)
```

## 🌈 Primary Gradient Button
The standard branded button for the redesign.
```dart
AppButton(
  width: context.width(),
  text: "Submit",
  textStyle: boldTextStyle(color: white),
  color: context.primaryColor, // Use AppStore primary
  shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  onTap: () {
    // ...
  },
).paddingSymmetric(vertical: 16)
```

## 🌫️ Blurred Header
For a native, premium feel.
```dart
ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      color: Colors.white.withOpacity(0.8),
      child: AppBar(title: Text("Title"), backgroundColor: Colors.transparent),
    ),
  ),
)
```

## 📊 Shimmer Skeleton
Use this during `isLoading` states.
```dart
Shimmer.fromColors(
  baseColor: Color(0xFFF3F4F6),
  highlightColor: Colors.white,
  child: ListView.builder(
    itemCount: 5,
    itemBuilder: (_, __) => SkeletonItem(),
  ),
)
```

## 📐 Layout Constants
- **Padding**: `16.0` (Standard), `24.0` (Wide).
- **Radius**: `12.0` (Inputs), `20.0` (Cards).
- **Icon Size**: `24.0`.

## 🚀 Speed Hack: Rapid Prototyping
When building a new screen, always start with:
1. `Scaffold`
2. `SingleChildScrollView`
3. `Column`
4. Use `20.height` (provided by `nb_utils`) for consistent vertical spacing.
