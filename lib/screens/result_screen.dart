import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/game_config.dart';
import '../constants/animation_constants.dart';
import '../constants/layout_constants.dart';
import '../providers/elo_history_provider.dart';
import '../providers/game_state_notifier.dart';
import '../repositories/elo_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Result screen — round summary, ELO delta, action buttons (UI-006).
class ResultScreen extends HookConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Staggered entry animation controllers ───────────────────────────────

    final entryControllers = List.generate(
      6,
      (i) => useAnimationController(duration: kEntryDuration),
    );

    final fadeAnimations = useMemoized(
      () => entryControllers
          .map((c) => CurvedAnimation(parent: c, curve: kEntryCurve))
          .map((c) => Tween<double>(begin: 0, end: 1).animate(c))
          .toList(),
      entryControllers,
    );

    final slideAnimations = useMemoized(
      () => entryControllers
          .map((c) => CurvedAnimation(parent: c, curve: kEntryCurve))
          .map(
            (c) => Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(c),
          )
          .toList(),
      entryControllers,
    );

    // Fire staggered entry animations on first build.
    useEffect(() {
      for (var i = 0; i < entryControllers.length; i++) {
        Future.delayed(kEntryStagger * (i + 1), () {
          if (context.mounted) entryControllers[i].forward();
        });
      }
      return null;
    }, const []);

    // ── ELO persistence (runs once on mount) ────────────────────────────────

    final previousElo = useRef(1000);

    useEffect(() {
      final eloRepo = ref.read(eloRepositoryProvider);
      previousElo.value = eloRepo.getCurrentRating();

      final state = ref.read(gameStateNotifierProvider);
      final eloResult = state.eloResult;
      if (eloResult != null) {
        eloRepo.saveResult(eloResult).then((_) {
          ref.invalidate(eloHistoryProvider);
        });
      }
      return null;
    }, const []);

    // ── Navigation guard ────────────────────────────────────────────────────

    final navigating = useRef(false);

    void playAgain() {
      if (navigating.value) return;
      navigating.value = true;
      final state = ref.read(gameStateNotifierProvider);
      context.pushReplacement(
        '/loading',
        extra: GameConfig(
          topic: state.topic,
          difficulty: state.difficulty,
          count: state.questions.length,
        ),
      );
    }

    void newTopic() {
      if (navigating.value) return;
      navigating.value = true;
      context.go('/topic');
    }

    void goHome() {
      if (navigating.value) return;
      navigating.value = true;
      context.go('/home');
    }

    // ── Build ───────────────────────────────────────────────────────────────

    final state = ref.watch(gameStateNotifierProvider);

    final playerScore = state.playerScore;
    final botScore = state.botScore;
    final eloResult = state.eloResult;
    final delta = eloResult?.delta ?? 0;
    final newElo = eloResult?.newRating ?? previousElo.value;

    final isWin = playerScore > botScore;
    final isTie = playerScore == botScore;

    Widget staggerWrap(int index, {required Widget child}) {
      return FadeTransition(
        opacity: fadeAnimations[index],
        child: SlideTransition(
          position: slideAnimations[index],
          child: child,
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goHome();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kScreenPaddingH,
              vertical: 32,
            ),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),

                // 0 — Heading
                staggerWrap(
                  0,
                  child: const Text(
                    'Round Complete',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 1 — Score cards
                staggerWrap(
                  1,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ScoreCard(
                          label: 'You',
                          score: playerScore,
                          isWinner: isWin,
                          isTie: isTie,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ScoreCard(
                          label: 'Bot',
                          score: botScore,
                          isWinner: !isWin && !isTie,
                          isTie: isTie,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2 — Victory / Defeat / Draw
                staggerWrap(
                  2,
                  child: Text(
                    isTie
                        ? 'Draw'
                        : isWin
                        ? 'Victory'
                        : 'Defeat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isTie
                          ? AppColors.muted
                          : isWin
                          ? AppColors.teal
                          : AppColors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 3 — ELO row
                staggerWrap(
                  3,
                  child: _EloRow(
                    previousElo: previousElo.value,
                    delta: delta,
                    newElo: newElo,
                  ),
                ),

                const Spacer(),

                // 4 — Action buttons
                staggerWrap(
                  4,
                  child: Column(
                    children: [
                      // Play Again
                      _PrimaryButton(label: 'Play Again', onTap: playAgain),
                      const SizedBox(height: 12),
                      // New Topic
                      _OutlinedButton(label: 'New Topic', onTap: newTopic),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5 — Home link
                staggerWrap(
                  5,
                  child: GestureDetector(
                    onTap: goHome,
                    child: const SizedBox(
                      height: 48,
                      child: Center(
                        child: Text(
                          'Home',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-widgets (private)
// ═══════════════════════════════════════════════════════════════════════════════

// ── Score card ──────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.score,
    required this.isWinner,
    required this.isTie,
  });

  final String label;
  final int score;
  final bool isWinner;
  final bool isTie;

  @override
  Widget build(BuildContext context) {
    final borderColor = isTie
        ? AppColors.mutedFaint
        : isWinner
        ? AppColors.primary
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isWinner && !isTie ? [AppShadows.primaryGlowStrong] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$score',
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ELO change row ──────────────────────────────────────────────────────────

class _EloRow extends StatelessWidget {
  const _EloRow({
    required this.previousElo,
    required this.delta,
    required this.newElo,
  });

  final int previousElo;
  final int delta;
  final int newElo;

  Color get _deltaColor {
    if (delta > 0) return AppColors.teal;
    if (delta < 0) return AppColors.red;
    return AppColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    final deltaBgColor = _deltaColor.withValues(alpha: 0.2);
    final deltaText = delta > 0 ? '+$delta' : (delta == 0 ? '0' : '$delta');
    final deltaIcon = delta > 0
        ? Icons.trending_up
        : (delta < 0 ? Icons.trending_down : null);

    final line = Container(
      width: kBadgeSize,
      height: 2,
      color: AppColors.mutedSubtle,
    );

    return Container(
      padding: const EdgeInsets.all(kCardPadding),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.all(Radius.circular(kCardRadius)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Previous ELO
          Text(
            '$previousElo',
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          line,
          const SizedBox(width: 12),

          // Delta badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: deltaBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (deltaIcon != null) ...[
                  Icon(deltaIcon, color: _deltaColor, size: 18),
                  const SizedBox(width: 4),
                ],
                Text(
                  deltaText,
                  style: TextStyle(
                    color: _deltaColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
          line,
          const SizedBox(width: 12),

          // New ELO
          Text(
            '$newElo',
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// ── Primary button ──────────────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: kTapScale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(kButtonRadius),
            boxShadow: [AppShadows.primaryGlow],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Outlined button ─────────────────────────────────────────────────────────

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kButtonRadius),
          border: Border.all(color: AppColors.mutedMedium),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
