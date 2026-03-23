import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:trivex/providers/theme_mode_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

late Directory _tempDir;
late Box _prefsBox;

/// Initialises Hive in a temp directory and opens the prefs box.
Future<void> _initHive() async {
  _tempDir = await Directory.systemTemp.createTemp('hive_theme_test_');
  Hive.init(_tempDir.path);
  _prefsBox = await Hive.openBox(kPrefsBoxName);
}

/// Tears down Hive and removes the temp directory.
Future<void> _tearDownHive() async {
  await _prefsBox.clear();
  await Hive.close();
  if (_tempDir.existsSync()) {
    _tempDir.deleteSync(recursive: true);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ThemeModeNotifier', () {
    setUp(_initHive);
    tearDown(_tearDownHive);

    // ── Defaults ──────────────────────────────────────────────────────────

    test('defaults to ThemeMode.system when Hive key is absent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mode = container.read(themeModeNotifierProvider);
      expect(mode, ThemeMode.system);
    });

    // ── Stored value ──────────────────────────────────────────────────────

    test('returns ThemeMode.dark when stored value is "dark"', () async {
      await _prefsBox.put(kThemeModeKey, 'dark');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeNotifierProvider), ThemeMode.dark);
    });

    test('returns ThemeMode.light when stored value is "light"', () async {
      await _prefsBox.put(kThemeModeKey, 'light');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeNotifierProvider), ThemeMode.light);
    });

    // ── cycle() ───────────────────────────────────────────────────────────

    test('cycle() rotates system → light → dark → system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeNotifierProvider.notifier);

      // system → light
      notifier.cycle();
      expect(container.read(themeModeNotifierProvider), ThemeMode.light);
      expect(_prefsBox.get(kThemeModeKey), 'light');

      // light → dark
      notifier.cycle();
      expect(container.read(themeModeNotifierProvider), ThemeMode.dark);
      expect(_prefsBox.get(kThemeModeKey), 'dark');

      // dark → system
      notifier.cycle();
      expect(container.read(themeModeNotifierProvider), ThemeMode.system);
      expect(_prefsBox.get(kThemeModeKey), 'system');
    });

    // ── setMode() ─────────────────────────────────────────────────────────

    test('setMode() persists and updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeNotifierProvider.notifier);

      notifier.setMode(ThemeMode.dark);
      expect(container.read(themeModeNotifierProvider), ThemeMode.dark);
      expect(_prefsBox.get(kThemeModeKey), 'dark');

      notifier.setMode(ThemeMode.system);
      expect(container.read(themeModeNotifierProvider), ThemeMode.system);
      expect(_prefsBox.get(kThemeModeKey), 'system');
    });
  });
}
