import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

export 'app_colors.dart';
export 'app_dimensions.dart';
export 'app_text_styles.dart';

abstract final class WakaTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: WakaColors.background,
      colorScheme: const ColorScheme.dark(
        primary: WakaColors.accent,
        secondary: WakaColors.gold,
        surface: WakaColors.surface,
      ),
      textTheme: const TextTheme(
        headlineLarge: WakaTextStyles.headlineLarge,
        headlineMedium: WakaTextStyles.headlineMedium,
        titleLarge: WakaTextStyles.titleLarge,
        titleMedium: WakaTextStyles.titleMedium,
        bodyLarge: WakaTextStyles.bodyLarge,
        bodyMedium: WakaTextStyles.bodyMedium,
        labelMedium: WakaTextStyles.labelMedium,
      ),
    );
  }
}
