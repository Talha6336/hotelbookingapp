import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Start with system theme by default
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return false; // UI handles system check
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // This triggers the whole app to rebuild instantly!
  }
}
