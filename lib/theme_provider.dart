import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_preference_mode';
const _kThemeColorKey = 'theme_preference_color';

class ThemeSettings {
  final ThemeMode mode;
  final Color color;

  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.color = const Color(0xFF1565C0), // Default Blue
  });

  ThemeSettings copyWith({
    ThemeMode? mode,
    Color? color,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      color: color ?? this.color,
    );
  }
}

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    _loadSettings();
    return const ThemeSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Mode
    final modeString = prefs.getString(_kThemeModeKey);
    ThemeMode mode = ThemeMode.system;
    if (modeString != null) {
      mode = ThemeMode.values.firstWhere(
        (e) => e.name == modeString,
        orElse: () => ThemeMode.system,
      );
    }
    
    // Load Color
    final colorInt = prefs.getInt(_kThemeColorKey);
    Color color = const Color(0xFF1565C0);
    if (colorInt != null) {
      color = Color(colorInt);
    }

    state = ThemeSettings(mode: mode, color: color);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, mode.name);
  }

  Future<void> setColor(Color color) async {
    state = state.copyWith(color: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeColorKey, color.value);
  }
}

final themeProvider = NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(() {
  return ThemeSettingsNotifier();
});
