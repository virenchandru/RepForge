import 'package:flutter/material.dart';

abstract final class AppColors {
  static const warmCream = Color(0xFFF2E7D8);
  static const charcoalBrown = Color(0xFF332B29);
  static const deepBrick = Color(0xFF773C35);
  static const mutedCoral = Color(0xFFC77D65);

  static const _surfaceBorder = Color(0xFFE5D8CA);
}

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.warmCream,
    colorScheme: const ColorScheme.light(
      primary: AppColors.deepBrick,
      onPrimary: Colors.white,
      secondary: AppColors.mutedCoral,
      onSecondary: AppColors.charcoalBrown,
      tertiary: AppColors.mutedCoral,
      onTertiary: AppColors.charcoalBrown,
      surface: Colors.white,
      onSurface: AppColors.charcoalBrown,
      error: Color(0xFFB3261E),
      onError: Colors.white,
    ),
    textTheme: const TextTheme().apply(
      bodyColor: AppColors.charcoalBrown,
      displayColor: AppColors.charcoalBrown,
      fontFamily: 'Roboto',
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors._surfaceBorder),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.deepBrick,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.deepBrick),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.charcoalBrown,
        side: const BorderSide(color: AppColors._surfaceBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors._surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors._surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.deepBrick, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.mutedCoral.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? AppColors.deepBrick
            : AppColors.charcoalBrown;
        return TextStyle(color: color, fontWeight: FontWeight.w600);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? AppColors.deepBrick
            : AppColors.charcoalBrown;
        return IconThemeData(color: color);
      }),
    ),
  );
}
