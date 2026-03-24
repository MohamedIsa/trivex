import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import 'package:trivex/models/elo_record.dart';
import 'package:trivex/providers/elo_history_provider.dart';
import 'package:trivex/providers/theme_mode_provider.dart';
import 'package:trivex/repositories/onboarding_repository.dart';
import 'package:trivex/screens/home_screen.dart';
import 'package:trivex/widgets/onboarding_overlay.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

late Directory _hiveDir;
late Box _prefsBox;

/// Must be called from [setUp] — runs outside the fake-async zone so that
/// real Hive file I/O completes normally.
Future<void> _initHive() async {
  _hiveDir = await Directory.systemTemp.createTemp('hive_onboarding_test_');
  Hive.init(_hiveDir.path);
  _prefsBox = await Hive.openBox(kPrefsBoxName);
}

Future<void> _tearDownHive() async {
  await Hive.close();
  if (_hiveDir.existsSync()) {
    _hiveDir.deleteSync(recursive: true);
  }
}

/// Pumps [HomeScreen] inside a [ProviderScope] with empty ELO history.
///
/// Uses `pump(Duration)` to advance past the staggered entry animations
/// instead of [WidgetTester.pumpAndSettle], which can hang when the overlay's
/// [Material] scrim is in the tree.
Future<void> _pumpHomeScreen(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomeScreen(),
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
  // Max entry delay = kEntryStagger*6 (600 ms) + kEntryDuration (500 ms).
  await tester.pump(const Duration(seconds: 2));
}

/// Pumps [OnboardingOverlay] in isolation (no HomeScreen, no entry-animation
/// timers, no Hive disk-write contention).
Future<VoidCallback> _pumpOverlay(WidgetTester tester) async {
  late VoidCallback onComplete;
  var completed = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            onComplete = () => setState(() => completed = true);
            if (completed) return const SizedBox.shrink();
            return OnboardingOverlay(onComplete: onComplete);
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return onComplete;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Onboarding overlay', () {
    setUp(_initHive);
    tearDown(_tearDownHive);

    // ── First launch (key absent) → overlay shown ─────────────────────────

    testWidgets(
      'first launch (key absent) — overlay shown',
      (tester) async {
        await _pumpHomeScreen(tester);

        expect(find.byType(OnboardingOverlay), findsOneWidget);
        expect(find.text('Pick a Topic'), findsOneWidget);
      },
    );

    // ── onboarding_complete = true → overlay NOT shown ────────────────────

    testWidgets(
      'onboarding_complete = true — overlay NOT shown',
      (tester) async {
        // runAsync escapes the fake-async zone so Hive disk I/O completes.
        await tester.runAsync(() async {
          await _prefsBox.put(kOnboardingCompleteKey, true);
        });

        await _pumpHomeScreen(tester);

        expect(find.byType(OnboardingOverlay), findsNothing);
      },
    );

    // ── "Next" advances from step 1 → 2 → 3 ─────────────────────────────

    testWidgets(
      '"Next" advances from step 1 → 2 → 3',
      (tester) async {
        await _pumpOverlay(tester);

        // Step 1 — "Pick a Topic"
        expect(find.text('Pick a Topic'), findsOneWidget);

        await tester.tap(find.text('Next'));
        await tester.pump();

        // Step 2 — "Beat the Bot"
        expect(find.text('Beat the Bot'), findsOneWidget);

        await tester.tap(find.text('Next'));
        await tester.pump();

        // Step 3 — "Your ELO Rating", button says "Got It"
        expect(find.text('Your ELO Rating'), findsOneWidget);
        expect(find.text('Got It'), findsOneWidget);
      },
    );

    // ── Tapping "Got It" on step 3 → onComplete fires ────────────────────

    testWidgets(
      'tapping "Got It" on step 3 — sets onboarding_complete to true',
      (tester) async {
        await _pumpOverlay(tester);

        // Advance to step 3.
        await tester.tap(find.text('Next'));
        await tester.pump();
        await tester.tap(find.text('Next'));
        await tester.pump();

        // Tap "Got It".
        await tester.tap(find.text('Got It'));
        await tester.pump();

        // Overlay removed (onComplete fired → StatefulBuilder hides it).
        expect(find.byType(OnboardingOverlay), findsNothing);
      },
    );

    // ── Tapping "Skip" → onComplete fires ─────────────────────────────────

    testWidgets(
      'tapping "Skip" — sets onboarding_complete to true',
      (tester) async {
        await _pumpOverlay(tester);

        // Overlay visible.
        expect(find.byType(OnboardingOverlay), findsOneWidget);

        // Tap "Skip".
        await tester.tap(find.text('Skip'));
        await tester.pump();

        // Overlay removed (onComplete fired → StatefulBuilder hides it).
        expect(find.byType(OnboardingOverlay), findsNothing);
      },
    );
  });
}
