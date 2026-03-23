import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// Hive box name used for lightweight user preferences.
const String kPrefsBoxName = 'prefs';

/// Hive key storing the theme mode string: "system", "dark", or "light".
const String kThemeModeKey = 'theme_mode';

/// Riverpod notifier that manages the user's theme preference.
///
/// Persists the choice in Hive under [kThemeModeKey] inside the
/// [kPrefsBoxName] box.  Defaults to [ThemeMode.system] when the key is
/// absent (first launch).
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  Box get _box => Hive.box(kPrefsBoxName);

  @override
  ThemeMode build() {
    final stored = _box.get(kThemeModeKey) as String?;
    return _fromString(stored);
  }

  /// Cycles through system → light → dark → system and persists.
  void cycle() {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    _box.put(kThemeModeKey, _toString(next));
    state = next;
  }

  /// Sets the theme mode directly and persists.
  void setMode(ThemeMode mode) {
    _box.put(kThemeModeKey, _toString(mode));
    state = mode;
  }

  // ── Mapping helpers ───────────────────────────────────────────────────

  static ThemeMode _fromString(String? value) => switch (value) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };

  static String _toString(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      };
}
