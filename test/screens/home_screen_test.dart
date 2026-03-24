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
import 'package:trivex/widgets/elo_sparkline.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

late Directory _hiveDir;

Future<void> _initHive() async {
  _hiveDir = await Directory.systemTemp.createTemp('hive_home_test_');
  Hive.init(_hiveDir.path);
  final box = await Hive.openBox(kPrefsBoxName);
  // Mark onboarding complete so the overlay doesn't interfere with existing
  // HomeScreen tests. Onboarding-specific tests live in a dedicated file.
  await box.put(kOnboardingCompleteKey, true);
}

Future<void> _tearDownHive() async {
  await Hive.close();
  if (_hiveDir.existsSync()) {
    _hiveDir.deleteSync(recursive: true);
  }
}

/// Builds a list of [count] fake EloRecords with ratings starting at [base].
List<EloRecord> _fakeHistory({int count = 10, int base = 1050}) {
  return List.generate(
    count,
    (i) => EloRecord(
      rating: base + i * 5,
      timestamp: DateTime(2026, 1, 1).add(Duration(days: i)),
    ),
  );
}

/// Pumps [HomeScreen] inside a [ProviderScope] with the given overrides.
///
/// Returns the [GoRouter] so callers can inspect navigation state.
Future<GoRouter> _pumpHomeScreen(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
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
      overrides: overrides,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return router;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HomeScreen', () {
    setUp(_initHive);
    tearDown(_tearDownHive);

    // ── Empty history — placeholder + default ELO ─────────────────────────

    testWidgets(
      'empty history — placeholder text visible, "1000" ELO shown',
      (tester) async {
        await _pumpHomeScreen(
          tester,
          overrides: [
            eloHistoryProvider.overrideWith((_) async => <EloRecord>[]),
          ],
        );
        await tester.pumpAndSettle();

        // Placeholder text inside EloSparkline when < 2 data points.
        expect(find.textContaining('Play your first round'), findsOneWidget);

        // Default ELO of 1000 shown.
        expect(find.text('1000'), findsOneWidget);
      },
    );

    // ── 10 records — sparkline present + correct ELO ──────────────────────

    testWidgets(
      '10 records — EloSparkline present, ELO matches last record',
      (tester) async {
        final records = _fakeHistory(count: 10, base: 1050);

        await _pumpHomeScreen(
          tester,
          overrides: [
            eloHistoryProvider.overrideWith((_) async => records),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.byType(EloSparkline), findsOneWidget);
        // Last record: 1050 + 9*5 = 1095.
        expect(find.text('1095'), findsOneWidget);
      },
    );

    // ── Tap Play → navigates to /topic ────────────────────────────────────

    testWidgets(
      'tap Play button — navigates to /topic',
      (tester) async {
        await _pumpHomeScreen(
          tester,
          overrides: [
            eloHistoryProvider.overrideWith((_) async => <EloRecord>[]),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Play'));
        await tester.pumpAndSettle();

        expect(find.text('route: /topic'), findsOneWidget);
      },
    );

    // ── Loading state — CircularProgressIndicator visible ─────────────────

    testWidgets(
      'loading state — CircularProgressIndicator visible',
      (tester) async {
        // Override with a future that takes a long time, keeping state as
        // AsyncLoading. We'll flush entry timers manually so no leaks.
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
              eloHistoryProvider.overrideWith(
                (_) => Future<List<EloRecord>>.delayed(
                  const Duration(seconds: 10),
                  () => [],
                ),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        // First frame — provider is still loading.
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Advance past all staggered entry-animation timers AND the 10s
        // future so the test tears down cleanly with no pending timers.
        await tester.pump(const Duration(seconds: 11));
        await tester.pumpAndSettle();
      },
    );
  });
}
