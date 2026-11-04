import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'design_system.dart';

class AppThemeData {
  AppThemeData._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final primary = appStore.appColorPrimary;
    AppDesignSystem.setPrimaryColor(primary);
    return _withPlatformTransitions(
      AppDesignSystem.buildTheme(primary: primary, brightness: brightness),
    );
  }

  static ThemeData _withPlatformTransitions(ThemeData theme) {
    return theme.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
