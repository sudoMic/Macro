import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _keyTheme = 'theme_mode';
  static const _keyRest = 'rest_seconds';

  ThemeMode _themeMode = ThemeMode.light;
  int _restSeconds = 120;
  bool _autoStartTimer = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  int get restSeconds => _restSeconds;
  bool get autoStartTimer => _autoStartTimer;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyTheme) ?? 'light';
    _themeMode = switch (saved) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    _restSeconds = prefs.getInt(_keyRest) ?? 120;
    _autoStartTimer = prefs.getBool('auto_start_timer') ?? true;
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      _ => 'light',
    });
    notifyListeners();
  }

  Future<void> setRestSeconds(int seconds) async {
    _restSeconds = seconds.clamp(10, 600);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRest, _restSeconds);
    notifyListeners();
  }

  Future<void> setAutoStartTimer(bool value) async {
    _autoStartTimer = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_start_timer', value);
    notifyListeners();
  }
}
