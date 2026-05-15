import 'package:flutter/material.dart';

/// Centralized StayEase color system.
///
/// Keep product colors here so every screen can adopt a new visual direction
/// through ThemeData and shared constants instead of one-off values.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = lightPrimary;
  static const Color secondary = lightSecondary;
  static const Color accent = lightAccent;

  // Light theme
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightPrimaryHover = Color(0xFF1D4ED8);
  static const Color lightSecondary = Color(0xFF60A5FA);
  static const Color lightAccent = Color(0xFF0EA5E9);
  static const Color lightBackground = Color(0xFFFAFBFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF4F7FB);
  static const Color lightBorder = Color(0xFFE5EAF1);
  static const Color lightBorderStrong = Color(0xFFD4DCE8);
  static const Color lightTextPrimary = Color(0xFF101828);
  static const Color lightTextSecondary = Color(0xFF667085);
  static const Color lightTextTertiary = Color(0xFF98A2B3);
  static const Color lightSuccess = Color(0xFF16A34A);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightWarning = Color(0xFFF59E0B);
  static const Color lightInfo = Color(0xFF0284C7);

  // Dark theme
  static const Color darkPrimary = Color(0xFF7DD3FC);
  static const Color darkPrimaryHover = Color(0xFF38BDF8);
  static const Color darkSecondary = Color(0xFF93C5FD);
  static const Color darkAccent = Color(0xFFBAE6FD);
  static const Color darkBackground = Color(0xFF070B12);
  static const Color darkSurface = Color(0xFF101722);
  static const Color darkSurfaceElevated = Color(0xFF151E2C);
  static const Color darkSurfaceMuted = Color(0xFF1D2736);
  static const Color darkBorder = Color(0xFF263244);
  static const Color darkBorderStrong = Color(0xFF344054);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF94A3B8);
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkInfo = Color(0xFF38BDF8);

  // Shared surfaces and overlays
  static const Color surfaceWhite = lightSurface;
  static const Color shadowLight = Color(0x1A101828);
  static const Color shadowMedium = Color(0x24101828);
  static const Color shadowDark = Color(0x66000000);
  static const Color shadowPremiumLight = Color(0x2A101828);
  static const Color glassLight = Color(0xD9FFFFFF);
  static const Color glassLightBorder = Color(0xB3FFFFFF);
  static const Color glassDark = Color(0x73101722);
  static const Color glassDarkBorder = Color(0x2EFFFFFF);

  // Compatibility aliases used by older screens.
  static const Color backgroundDark1 = darkBackground;
  static const Color backgroundDark2 = Color(0xFF111827);
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color bgTop = darkBackground;
  static const Color bgBottom = Color(0xFF111827);

  // Gradients
  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightSurface, lightBackground, Color(0xFFEFF6FF)],
    stops: [0.0, 0.58, 1.0],
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBackground, Color(0xFF0B1220), Color(0xFF111827)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightPrimary, lightSecondary],
  );

  static const LinearGradient premiumBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
  );

  static const LinearGradient glassHighlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xE6FFFFFF), Color(0xBFF4F7FB)],
  );

  static const LinearGradient darkGradient = darkBackgroundGradient;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color adaptiveBackground(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color adaptiveSurface(BuildContext context) =>
      isDark(context) ? darkBackground : lightBackground;

  static Color adaptiveSurfaceMuted(BuildContext context) =>
      isDark(context) ? darkSurfaceMuted : lightSurfaceMuted;

  static Color adaptiveBorder(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color adaptiveTextPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color adaptiveTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color adaptiveTextTertiary(BuildContext context) =>
      isDark(context) ? darkTextTertiary : lightTextTertiary;

  static LinearGradient adaptiveBackgroundGradient(BuildContext context) =>
      isDark(context) ? darkBackgroundGradient : lightBackgroundGradient;

  static Color adaptiveShadow(BuildContext context) =>
      isDark(context) ? shadowDark.withValues(alpha: 0.36) : shadowPremiumLight;

  static Color adaptiveGlass(BuildContext context) =>
      isDark(context) ? glassDark : glassLight;

  static Color adaptiveGlassBorder(BuildContext context) =>
      isDark(context) ? glassDarkBorder : lightBorderStrong;
}
