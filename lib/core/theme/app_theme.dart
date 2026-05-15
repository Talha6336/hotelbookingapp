import 'package:flutter/material.dart';

import 'app_colors.dart';

export 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String? _fontFamily = null;
  static const double _radiusMedium = 16;
  static const double _radiusLarge = 24;

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.lightPrimary,
          brightness: Brightness.light,
          primary: AppColors.lightPrimary,
          onPrimary: Colors.white,
          secondary: AppColors.lightSecondary,
          onSecondary: Colors.white,
          tertiary: AppColors.lightAccent,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          error: AppColors.lightError,
          onError: Colors.white,
        ).copyWith(
          surfaceContainerHighest: AppColors.lightSurfaceMuted,
          outline: AppColors.lightBorder,
          outlineVariant: AppColors.lightBorderStrong,
        );

    return _baseTheme(colorScheme).copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: _appBarTheme(
        backgroundColor: AppColors.lightSurface.withValues(alpha: 0.94),
        foregroundColor: AppColors.lightTextPrimary,
        iconColor: AppColors.lightTextPrimary,
      ),
      cardTheme: _cardTheme(
        color: AppColors.lightSurfaceElevated,
        shadowColor: AppColors.shadowLight,
        borderColor: AppColors.lightBorder,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        shadowColor: AppColors.lightPrimary.withValues(alpha: 0.22),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: AppColors.lightSurfaceMuted,
        textColor: AppColors.lightTextPrimary,
        hintColor: AppColors.lightTextTertiary,
        borderColor: AppColors.lightBorder,
        focusedBorderColor: AppColors.lightPrimary,
      ),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(
        backgroundColor: AppColors.lightSurface.withValues(alpha: 0.96),
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightTextTertiary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 8,
        focusElevation: 10,
        hoverElevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextSecondary,
        size: 22,
      ),
      snackBarTheme: _snackBarTheme(
        backgroundColor: AppColors.lightTextPrimary,
        contentColor: Colors.white,
      ),
      textTheme: _textTheme(
        primary: AppColors.lightTextPrimary,
        secondary: AppColors.lightTextSecondary,
        tertiary: AppColors.lightTextTertiary,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.darkPrimary,
          brightness: Brightness.dark,
          primary: AppColors.darkPrimary,
          onPrimary: AppColors.darkBackground,
          secondary: AppColors.darkSecondary,
          onSecondary: AppColors.darkBackground,
          tertiary: AppColors.darkAccent,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          error: AppColors.darkError,
          onError: AppColors.darkBackground,
        ).copyWith(
          surfaceContainerHighest: AppColors.darkSurfaceMuted,
          outline: AppColors.darkBorder,
          outlineVariant: AppColors.darkBorderStrong,
        );

    return _baseTheme(colorScheme).copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: _appBarTheme(
        backgroundColor: AppColors.darkBackground.withValues(alpha: 0.92),
        foregroundColor: AppColors.darkTextPrimary,
        iconColor: AppColors.darkTextPrimary,
      ),
      cardTheme: _cardTheme(
        color: AppColors.darkSurfaceElevated,
        shadowColor: AppColors.shadowDark,
        borderColor: AppColors.darkBorder,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkBackground,
        shadowColor: AppColors.darkPrimary.withValues(alpha: 0.18),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: AppColors.darkSurfaceMuted,
        textColor: AppColors.darkTextPrimary,
        hintColor: AppColors.darkTextTertiary,
        borderColor: AppColors.darkBorder,
        focusedBorderColor: AppColors.darkPrimary,
      ),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(
        backgroundColor: AppColors.darkSurface.withValues(alpha: 0.96),
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextTertiary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkBackground,
        elevation: 8,
        focusElevation: 10,
        hoverElevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkTextSecondary,
        size: 22,
      ),
      snackBarTheme: _snackBarTheme(
        backgroundColor: AppColors.darkSurfaceElevated,
        contentColor: AppColors.darkTextPrimary,
      ),
      textTheme: _textTheme(
        primary: AppColors.darkTextPrimary,
        secondary: AppColors.darkTextSecondary,
        tertiary: AppColors.darkTextTertiary,
      ),
    );
  }

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static AppBarTheme _appBarTheme({
    required Color backgroundColor,
    required Color foregroundColor,
    required Color iconColor,
  }) {
    return AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: iconColor, size: 22),
      titleTextStyle: TextStyle(
        color: foregroundColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }

  static CardThemeData _cardTheme({
    required Color color,
    required Color shadowColor,
    required Color borderColor,
  }) {
    return CardThemeData(
      color: color,
      elevation: 2,
      shadowColor: shadowColor,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusLarge),
        side: BorderSide(color: borderColor),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme({
    required Color backgroundColor,
    required Color foregroundColor,
    required Color shadowColor,
  }) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return backgroundColor.withValues(alpha: 0.42);
          }
          if (states.contains(WidgetState.pressed)) {
            return backgroundColor.withValues(alpha: 0.88);
          }
          return backgroundColor;
        }),
        foregroundColor: WidgetStatePropertyAll(foregroundColor),
        shadowColor: WidgetStatePropertyAll(shadowColor),
        overlayColor: WidgetStatePropertyAll(
          foregroundColor.withValues(alpha: 0.08),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusMedium),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color textColor,
    required Color hintColor,
    required Color borderColor,
    required Color focusedBorderColor,
  }) {
    final borderRadius = BorderRadius.circular(_radiusMedium);

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      labelStyle: TextStyle(color: hintColor, fontSize: 14),
      floatingLabelStyle: TextStyle(
        color: focusedBorderColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: hintColor,
      suffixIconColor: hintColor,
      enabledBorder: border(borderColor),
      focusedBorder: border(focusedBorderColor, width: 1.4),
      errorBorder: border(AppColors.lightError),
      focusedErrorBorder: border(AppColors.lightError, width: 1.4),
      disabledBorder: border(borderColor.withValues(alpha: 0.5)),
    );
  }

  static BottomNavigationBarThemeData _bottomNavigationBarTheme({
    required Color backgroundColor,
    required Color selectedItemColor,
    required Color unselectedItemColor,
  }) {
    return BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      unselectedItemColor: unselectedItemColor,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      showUnselectedLabels: true,
    );
  }

  static SnackBarThemeData _snackBarTheme({
    required Color backgroundColor,
    required Color contentColor,
  }) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      contentTextStyle: TextStyle(
        color: contentColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusMedium),
      ),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    );
  }

  static TextTheme _textTheme({
    required Color primary,
    required Color secondary,
    required Color tertiary,
  }) {
    return TextTheme(
      displayLarge: TextStyle(
        color: primary,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.08,
      ),
      displayMedium: TextStyle(
        color: primary,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
      headlineLarge: TextStyle(
        color: primary,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        color: primary,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      titleSmall: TextStyle(
        color: secondary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: secondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        color: tertiary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: primary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      labelMedium: TextStyle(
        color: secondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      labelSmall: TextStyle(
        color: tertiary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}
