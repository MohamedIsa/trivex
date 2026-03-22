import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:trivex/models/game_config.dart';
import 'package:trivex/screens/topic_screen.dart';
import 'package:trivex/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps [TopicScreen] inside a [MaterialApp.router] with [GoRouter].
///
/// [onPush] is called when a route other than /topic is built, allowing
/// tests to capture the [GoRouterState] (and its extras).
Future<GoRouter> _pumpTopicScreen(
  WidgetTester tester, {
  void Function(GoRouterState)? onPush,
}) async {
  final router = GoRouter(
    initialLocation: '/topic',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/topic',
        builder: (_, _) => const TopicScreen(),
      ),
      GoRoute(
        path: '/loading',
        builder: (_, state) {
          onPush?.call(state);
          return Scaffold(body: Text('route: ${state.uri}'));
        },
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TopicScreen', () {
    // ── Start button disabled when topic empty ────────────────────────────

    testWidgets(
      'empty topic field — Start button disabled (AppColors.card bg)',
      (tester) async {
        await _pumpTopicScreen(tester);

        // The Start button should display 'Start'.
        expect(find.text('Start'), findsOneWidget);

        // When disabled, the container has AppColors.card as background.
        final startContainer = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text('Start'),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final decoration = startContainer.decoration as BoxDecoration;
        expect(decoration.color, AppColors.card);
      },
    );

    // ── Type text → Start button becomes enabled ──────────────────────────

    testWidgets(
      'type topic text — Start button becomes enabled (AppColors.primary bg)',
      (tester) async {
        await _pumpTopicScreen(tester);

        await tester.enterText(find.byType(TextField), 'History');
        await tester.pumpAndSettle();

        final startContainer = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text('Start'),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final decoration = startContainer.decoration as BoxDecoration;
        expect(decoration.color, AppColors.primary);
      },
    );

    // ── Tap Easy chip → becomes selected ──────────────────────────────────

    testWidgets(
      'tap Easy chip — becomes selected (primary bg)',
      (tester) async {
        await _pumpTopicScreen(tester);

        await tester.tap(find.text('Easy'));
        await tester.pumpAndSettle();

        // Find the AnimatedContainer that is an ancestor of the 'Easy' text.
        final easyContainer = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text('Easy'),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final decoration = easyContainer.decoration as BoxDecoration;
        expect(decoration.color, AppColors.primary);
      },
    );

    // ── Tap Start with valid topic → navigates to /loading ────────────────

    testWidgets(
      'tap Start with valid topic — navigates to /loading with GameConfig',
      (tester) async {
        GoRouterState? pushedState;

        await _pumpTopicScreen(
          tester,
          onPush: (state) => pushedState = state,
        );

        await tester.enterText(find.byType(TextField), 'Science');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();

        expect(pushedState, isNotNull);
        final config = pushedState!.extra as GameConfig;
        expect(config.topic, 'Science');
        expect(config.difficulty, 'medium'); // default
        expect(config.count, 10); // default
      },
    );

    // ── Tap "15" count chip → chip selected, GameConfig.count is 15 ───────

    testWidgets(
      'tap "15" chip — becomes selected, GameConfig.count is 15',
      (tester) async {
        GoRouterState? pushedState;

        await _pumpTopicScreen(
          tester,
          onPush: (state) => pushedState = state,
        );

        // Tap the "15" count chip.
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        // Verify the "15" chip shows the active (primary) background.
        final chip15 = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text('15'),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final decoration = chip15.decoration as BoxDecoration;
        expect(decoration.color, AppColors.primary);

        // Enter text and tap Start to verify the config carries count: 15.
        await tester.enterText(find.byType(TextField), 'Geography');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();

        expect(pushedState, isNotNull);
        final config = pushedState!.extra as GameConfig;
        expect(config.count, 15);
      },
    );

    // ── Tap back arrow → pops to previous route ───────────────────────────

    testWidgets(
      'tap back arrow — pops to previous route',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: Text('Home')),
            ),
            GoRoute(
              path: '/topic',
              builder: (_, _) => const TopicScreen(),
            ),
          ],
        );
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Push /topic on top of /home.
        router.push('/topic');
        await tester.pumpAndSettle();

        // Tap the back arrow.
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Should see the home route's text.
        expect(find.text('Home'), findsOneWidget);
      },
    );

    // ── Tap "عربي" language chip → selected, GameConfig.language is 'ar' ──

    testWidgets(
      'tap "عربي" chip — becomes selected, GameConfig.language is "ar"',
      (tester) async {
        GoRouterState? pushedState;

        await _pumpTopicScreen(
          tester,
          onPush: (state) => pushedState = state,
        );

        // Tap the Arabic language chip.
        await tester.tap(find.text('عربي'));
        await tester.pumpAndSettle();

        // Verify the chip shows the active (primary) background.
        final arChip = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text('عربي'),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final decoration = arChip.decoration as BoxDecoration;
        expect(decoration.color, AppColors.primary);

        // Enter text and tap Start to verify config carries language: 'ar'.
        await tester.enterText(find.byType(TextField), 'تاريخ');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();

        expect(pushedState, isNotNull);
        final config = pushedState!.extra as GameConfig;
        expect(config.language, 'ar');
      },
    );
  });
}
