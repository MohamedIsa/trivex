import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:trivex/constants/category_constants.dart';
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
    // ── Start button disabled when nothing selected ───────────────────────

    testWidgets(
      'no selection — Start button disabled (AppColors.card bg)',
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

    // ── Tap category chip → selected, others deselected ───────────────────

    testWidgets(
      'tapping a category chip — it becomes selected, others deselected',
      (tester) async {
        await _pumpTopicScreen(tester);

        // Tap the first category chip (Science).
        final scienceLabel = '${kCategories[0].emoji}  ${kCategories[0].label}';
        await tester.tap(find.text(scienceLabel));
        await tester.pumpAndSettle();

        // Science chip should be primary.
        final scienceContainer = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text(scienceLabel),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final sciDecor = scienceContainer.decoration as BoxDecoration;
        expect(sciDecor.color, AppColors.primary);

        // History chip should NOT be primary.
        final historyLabel = '${kCategories[1].emoji}  ${kCategories[1].label}';
        final historyContainer = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text(historyLabel),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final hisDecor = historyContainer.decoration as BoxDecoration;
        expect(hisDecor.color, isNot(AppColors.primary));

        // Now tap History — it becomes selected, Science deselects.
        await tester.tap(find.text(historyLabel));
        await tester.pumpAndSettle();

        final sciAfter = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text(scienceLabel),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final sciDecorAfter = sciAfter.decoration as BoxDecoration;
        expect(sciDecorAfter.color, isNot(AppColors.primary));

        final hisAfter = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text(historyLabel),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final hisDecorAfter = hisAfter.decoration as BoxDecoration;
        expect(hisDecorAfter.color, AppColors.primary);
      },
    );

    // ── Tap category → Start enabled, passes correct topic ─────────────────

    testWidgets(
      'tap category + Start — navigates to /loading with category as topic',
      (tester) async {
        GoRouterState? pushedState;

        await _pumpTopicScreen(
          tester,
          onPush: (state) => pushedState = state,
        );

        // Tap "Science" category.
        final scienceLabel = '${kCategories[0].emoji}  ${kCategories[0].label}';
        await tester.tap(find.text(scienceLabel));
        await tester.pumpAndSettle();

        // Start should now be enabled.
        final startContainer = tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text('Start'),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final decoration = startContainer.decoration as BoxDecoration;
        expect(decoration.color, AppColors.primary);

        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();

        expect(pushedState, isNotNull);
        final config = pushedState!.extra as GameConfig;
        expect(config.topic, 'Science');
        expect(config.difficulty, 'medium');
        expect(config.count, 10);
      },
    );

    // ── Custom Topic → text field appears ──────────────────────────────────

    testWidgets(
      'tapping "Custom Topic" → text field appears',
      (tester) async {
        await _pumpTopicScreen(tester);

        // No TextField should be visible initially.
        expect(find.byType(TextField), findsNothing);

        // Tap the "Custom Topic" chip.
        await tester.tap(find.text('✏️  Custom Topic'));
        await tester.pumpAndSettle();

        // TextField should now be visible.
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    // ── Custom topic selected + empty text → Start disabled ────────────────

    testWidgets(
      'custom topic selected + empty text → Start button disabled',
      (tester) async {
        await _pumpTopicScreen(tester);

        await tester.tap(find.text('✏️  Custom Topic'));
        await tester.pumpAndSettle();

        // Start should still be disabled.
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

    // ── Custom topic selected + non-empty text → Start enabled ─────────────

    testWidgets(
      'custom topic selected + non-empty text → Start button enabled',
      (tester) async {
        await _pumpTopicScreen(tester);

        await tester.tap(find.text('✏️  Custom Topic'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'The Roman Empire');
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
      'tap Start with custom topic — navigates to /loading with GameConfig',
      (tester) async {
        GoRouterState? pushedState;

        await _pumpTopicScreen(
          tester,
          onPush: (state) => pushedState = state,
        );

        // Select Custom Topic and type a topic.
        await tester.tap(find.text('✏️  Custom Topic'));
        await tester.pumpAndSettle();

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

        // Select a category and tap Start to verify the config carries count: 15.
        final geoLabel = '${kCategories[2].emoji}  ${kCategories[2].label}';
        await tester.tap(find.text(geoLabel));
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

        // Scroll the language chips into view then tap Arabic.
        await tester.scrollUntilVisible(find.text('عربي'), 100);
        await tester.pumpAndSettle();

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

        // Select a category and tap Start to verify config carries language: 'ar'.
        // Scroll back up to find the category chip.
        await tester.scrollUntilVisible(
          find.text('${kCategories[1].emoji}  ${kCategories[1].label}'),
          -100,
        );
        await tester.pumpAndSettle();

        final histLabel = '${kCategories[1].emoji}  ${kCategories[1].label}';
        await tester.tap(find.text(histLabel));
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
