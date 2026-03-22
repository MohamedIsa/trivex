import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:trivex/models/game_config.dart';
import 'package:trivex/repositories/question_cache_repository.dart';
import 'package:trivex/screens/loading_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _config = GameConfig(topic: 'History', difficulty: 'medium', count: 10);

/// Pumps [LoadingScreen] inside a [MaterialApp.router] with [GoRouter].
///
/// The screen receives [config] via its constructor parameter (mirroring
/// the real [GoRoute] builder that casts `state.extra`).
///
/// After this returns the widget tree is rendered **but** the post-frame
/// callback that triggers `_fetchQuestions` has **not yet fired**.
/// Call `tester.pump()` once more to let the callback execute.
Future<GoRouter> _pumpLoadingScreen(
  WidgetTester tester, {
  GameConfig? config = _config,
  void Function(String)? onRoute,
}) async {
  final router = GoRouter(
    initialLocation: '/loading',
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) => LoadingScreen(gameConfig: config),
      ),
      GoRoute(
        path: '/game',
        builder: (_, _) {
          onRoute?.call('/game');
          return const Scaffold(body: Text('route: /game'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return router;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = Directory.systemTemp.createTempSync('hive_loading_test_');
    Hive.init(hiveDir.path);
    await Hive.openBox(QuestionCacheRepository.boxName);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

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
        final router = GoRouter(
          initialLocation: '/topic',
          routes: [
            GoRoute(
              path: '/topic',
              builder: (_, _) => const Scaffold(body: Text('Topic')),
            ),
            GoRoute(
              path: '/loading',
              builder: (_, _) => const LoadingScreen(gameConfig: _config),
            ),
            GoRoute(
              path: '/game',
              builder: (_, _) => const Scaffold(),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // Push /loading on top.
        router.push('/loading');
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
        // Push LoadingScreen without GameConfig.
        final router = GoRouter(
          initialLocation: '/loading',
          routes: [
            GoRoute(
              path: '/loading',
              builder: (_, _) => const LoadingScreen(),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(routerConfig: router),
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

    // ── Happy path — fetch succeeds, navigates to /game ───────────────────

    testWidgets(
      'QuestionService succeeds — navigates to /game with question list',
      (tester) async {
        String? navigatedTo;

        await http.runWithClient(
          () async {
            await _pumpLoadingScreen(
              tester,
              onRoute: (route) => navigatedTo = route,
            );

            // Trigger the post-frame callback → _fetchQuestions starts.
            await tester.pump();

            // Let the async fetch complete and navigation settle.
            await tester.pumpAndSettle();
          },
          () => MockClient(
            (_) async => http.Response(
              jsonEncode({
                'questions': List.generate(
                  5,
                  (i) => {
                    'id': 'q${i + 1}',
                    'question': 'Question ${i + 1}',
                    'options': ['Alpha', 'Bravo', 'Charlie', 'Delta'],
                    'correctIndex': 0,
                    'explanation': 'Because ${i + 1}.',
                  },
                ),
              }),
              200,
              headers: {
                'content-type': 'application/json; charset=utf-8',
              },
            ),
          ),
        );

        expect(navigatedTo, '/game');
        expect(find.text('route: /game'), findsOneWidget);
      },
    );
  });
}
