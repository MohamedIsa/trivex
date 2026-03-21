import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trivex/models/game_config.dart';
import 'package:trivex/screens/loading_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _config = GameConfig(topic: 'History', difficulty: 'medium');

/// Pumps [LoadingScreen] inside a [MaterialApp] whose initial route carries
/// [config] as arguments.
///
/// After this returns the widget tree is rendered **but** the post-frame
/// callback that triggers `_fetchQuestions` has **not yet fired**.
/// Call `tester.pump()` once more to let the callback execute.
Future<void> _pumpLoadingScreen(
  WidgetTester tester, {
  GameConfig config = _config,
  void Function(RouteSettings)? onRoute,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(
              settings: RouteSettings(name: '/loading', arguments: config),
              builder: (_) => const LoadingScreen(),
            );
          }
          onRoute?.call(settings);
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => Scaffold(body: Text('route: ${settings.name}')),
          );
        },
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LoadingScreen', () {
    // ── Shows error + Try Again on fetch failure ──────────────────────────

    testWidgets(
      'fetch failure — error message visible, Try Again button appears',
      (tester) async {
        await _pumpLoadingScreen(tester);

        // Trigger the post-frame callback → _fetchQuestions starts.
        await tester.pump();

        // The HTTP fetch fails (no server in tests). The pulse animation
        // stops on error, so pumpAndSettle finishes.
        await tester.pumpAndSettle(const Duration(seconds: 6));

        expect(find.text('Try Again'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      },
    );

    // ── Tap Cancel → pops to previous route ───────────────────────────────

    testWidgets(
      'tap Cancel — pops to previous route',
      (tester) async {
        // Build a two-page stack so there's something to pop to.
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              initialRoute: '/topic',
              onGenerateRoute: (settings) {
                if (settings.name == '/topic') {
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const Scaffold(body: Text('Topic')),
                  );
                }
                if (settings.name == '/loading') {
                  return MaterialPageRoute(
                    settings: RouteSettings(
                      name: '/loading',
                      arguments: _config,
                    ),
                    builder: (_) => const LoadingScreen(),
                  );
                }
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const Scaffold(),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Push /loading on top.
        final nav = tester.state<NavigatorState>(find.byType(Navigator));
        nav.pushNamed('/loading');
        // Let the push animation + post-frame callback fire.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Let the HTTP call fail so the pulse animation stops and we
        // can settle.
        await tester.pumpAndSettle(const Duration(seconds: 6));

        // Error state shows Cancel button.
        final cancelFinder = find.text('Cancel');
        expect(cancelFinder, findsWidgets);
        await tester.tap(cancelFinder.last);
        await tester.pumpAndSettle();

        expect(find.text('Topic'), findsOneWidget);
      },
    );

    // ── Shows generating text while loading ───────────────────────────────

    testWidgets(
      'loading state — "Generating questions…" text visible',
      (tester) async {
        await _pumpLoadingScreen(tester);

        // Before the post-frame callback fires, the screen is in its
        // initial state: _error is null, _fetching is false. The build
        // method shows _buildLoading() because _error == null.
        // The "Generating questions…" subtitle is part of _buildLoading.
        expect(find.text('Generating questions…'), findsOneWidget);
      },
    );

    // ── Missing config shows error ────────────────────────────────────────

    testWidgets(
      'missing GameConfig — shows "Missing game configuration." error',
      (tester) async {
        // Push LoadingScreen without GameConfig arguments.
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              onGenerateRoute: (settings) {
                if (settings.name == '/') {
                  return MaterialPageRoute(
                    settings: const RouteSettings(name: '/loading'),
                    builder: (_) => const LoadingScreen(),
                  );
                }
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const Scaffold(),
                );
              },
            ),
          ),
        );

        // Trigger the post-frame callback. _fetchQuestions sees null config
        // and sets _error synchronously. The pulse animation keeps running
        // so we can't use pumpAndSettle.
        await tester.pump();
        await tester.pump();

        expect(find.text('Missing game configuration.'), findsOneWidget);
      },
    );
  });
}
