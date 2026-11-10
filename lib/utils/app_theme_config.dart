import 'package:flutter/material.dart';

import '../constants/dimensions.dart';

abstract final class AppThemeConfig {
  static ThemeData get light {
    final ColorScheme colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF196B58),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: const Color(0xFFF8F9F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9F5),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
      ),
    );
  }
}
