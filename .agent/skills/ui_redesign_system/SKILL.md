# UI Redesign System Skill

This skill is the definitive guide for redesigning the Open Core HR app into a premium, state-of-the-art mobile experience.

## 🎨 Token Application

The `design_system.json` file is your source of truth. Use its tokens for every UI decision.

### 1. Colors (Premium Palette)
- **Primary**: Use `#696CFF` (Brand Primary). It should dominate actions and branding.
- **Surface**: Use `#F7F8FA` for backgrounds and pure `#FFFFFF` for cards.
- **Success/Error**: Use the HSL-tailored greens and reds from the `colorPalette`.

### 2. Premium Gradients
For a "wow" factor, use the component gradients:
- **Primary Action**: `linear-gradient(135deg, #696CFF 0%, #8B7EFF 100%)`
- **Success Alert**: `linear-gradient(135deg, #22D97A 0%, #2DD4BF 100%)`

### 3. Glassmorphism & Elevation
- **Cards**: Use `borderRadius: 20` and `shadow: "md"` (Shadow Color: `#000000`, Opacity: `0.1`).
- **Overlays**: Use `rgba(255, 255, 255, 0.9)` for a frosted glass effect on headers/bottom sheets.

## ✨ Micro-animations

A premium feel comes from small, delightful motions.
- **Button Press**: scale down to `0.96` over `fast` (150ms) duration.
- **Card Entrance**: Use a staggered fade-in + slide-up effect (`translateY: 20 -> 0`).
- **Loading**: Use the `shimmerLoading` patterns defined in the JSON.

## 📐 Typography Hierarchy

- **Headings**: Use `LufgaMedium` or `Bold`. Size: `24` or `28` for screen titles.
- **Body**: Use `Inter Regular`. Size: `14` (Base).
- **Subtext**: Size: `12` (Small), Color: `neutral.500`.

## 🛠️ Redesign Checklist

1.  [ ] **Global Theme**: Update `app_theme.dart` to use `696CFF` as the primary swatch.
2.  [ ] **Component Sweep**: Replace standard `ElevatedButton` with a custom `PremiumButton` that supports gradients and scales on tap.
3.  [ ] **Navigation**: Implement the `tabBar` design (Height: `60`, active color: `#696CFF`).
4.  [ ] **Spacing**: strictly use the 4px grid (Spacing tokens 1-24).

## 🚀 Pro-Tip: "The Glass Effect"
When redesigning headers, use `BackdropFilter` with `ImageFilter.blur` to create a premium blurred background effect that makes the app feel native and high-end.
