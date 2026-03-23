import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import 'package:trivex/models/elo_record.dart';
import 'package:trivex/providers/elo_history_provider.dart';
import 'package:trivex/providers/theme_mode_provider.dart';
import 'package:trivex/screens/home_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

late Directory _tempDir;

Future<void> _initHive() async {
  _tempDir = await Directory.systemTemp.createTemp('hive_theme_widget_');
  Hive.init(_tempDir.path);
  await Hive.openBox(kPrefsBoxName);
}

Future<void> _tearDownHive() async {
  await Hive.box(kPrefsBoxName).clear();
  await Hive.close();
  if (_tempDir.existsSync()) {
    _tempDir.deleteSync(recursive: true);
  }
}

/// Pumps [HomeScreen] with Hive prefs box available.
Future<void> _pumpHomeScreen(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: '/topic',
        builder: (_, _) => const Scaffold(body: Text('route: /topic')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        eloHistoryProvider.overrideWith((_) async => <EloRecord>[]),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  await tester.pumpAndSettle();
}

/// Taps the widget matched by [finder] inside [tester.runAsync] so the
/// Hive I/O triggered by the theme toggle completes outside the fake zone.
Future<void> _tapAsync(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() async {
    await tester.tap(finder);
    // Allow the fire-and-forget Hive write inside cycle() to flush.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Theme toggle on HomeScreen', () {
    setUp(_initHive);
    tearDown(_tearDownHive);

    // ── Toggle icon cycles correctly ──────────────────────────────────────

    testWidgets(
      'tap toggle cycles icon: auto → light → dark → auto',
      (tester) async {
        await _pumpHomeScreen(tester);

        // Initial state — system (brightness_auto icon).
        expect(find.byIcon(Icons.brightness_auto), findsOneWidget);

        // Tap 1 → light.
        await _tapAsync(tester, find.byIcon(Icons.brightness_auto));
        expect(find.byIcon(Icons.light_mode), findsOneWidget);

        // Tap 2 → dark.
        await _tapAsync(tester, find.byIcon(Icons.light_mode));
        expect(find.byIcon(Icons.dark_mode), findsOneWidget);

        // Tap 3 → back to system.
        await _tapAsync(tester, find.byIcon(Icons.dark_mode));
        expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
      },
    );

    // ── Tooltip accessibility ─────────────────────────────────────────────

    testWidgets(
      'toggle shows correct tooltip per mode',
      (tester) async {
        await _pumpHomeScreen(tester);

        expect(find.byTooltip('Theme: System'), findsOneWidget);

        await _tapAsync(tester, find.byTooltip('Theme: System'));
        expect(find.byTooltip('Theme: Light'), findsOneWidget);

        await _tapAsync(tester, find.byTooltip('Theme: Light'));
        expect(find.byTooltip('Theme: Dark'), findsOneWidget);
      },
    );

    // ── Persistence across rebuilds ───────────────────────────────────────

    testWidgets(
      'persisted "dark" is restored on next pump',
      (tester) async {
        // Hive writes must run outside the fake async zone.
        await tester.runAsync(() async {
          await Hive.box(kPrefsBoxName).put(kThemeModeKey, 'dark');
        });

        await _pumpHomeScreen(tester);

        expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      },
    );

    // ── Toggle persists to Hive ───────────────────────────────────────────

    testWidgets(
      'tapping toggle persists new mode to Hive',
      (tester) async {
        await _pumpHomeScreen(tester);

        await _tapAsync(tester, find.byIcon(Icons.brightness_auto));
        expect(Hive.box(kPrefsBoxName).get(kThemeModeKey), 'light');

        await _tapAsync(tester, find.byIcon(Icons.light_mode));
        expect(Hive.box(kPrefsBoxName).get(kThemeModeKey), 'dark');
      },
    );
  });
}
