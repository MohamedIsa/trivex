import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/game_config.dart';
import '../constants/animation_constants.dart';
import '../constants/layout_constants.dart';
import '../providers/elo_history_provider.dart';
import '../providers/game_state_notifier.dart';
import '../repositories/elo_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Result screen — round summary, ELO delta, action buttons (UI-006).
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  // ── Staggered entry animation controllers ─────────────────────────────────

  late final List<AnimationController> _entryControllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  /// Cached before save so the "previous" value is accurate.
  int _previousElo = 1000;
  bool _saved = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    // 6 sections with 100 ms stagger (100 ms – 600 ms).
    _entryControllers = List.generate(6, (i) {
      return AnimationController(vsync: this, duration: kEntryDuration);
    });

    _fadeAnimations = _entryControllers
        .map((c) => CurvedAnimation(parent: c, curve: kEntryCurve))
        .map((c) => Tween<double>(begin: 0, end: 1).animate(c))
        .toList();

    _slideAnimations = _entryControllers
        .map((c) => CurvedAnimation(parent: c, curve: kEntryCurve))
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(c),
        )
        .toList();

    // Fire staggered.
    for (var i = 0; i < _entryControllers.length; i++) {
      Future.delayed(kEntryStagger * (i + 1), () {
        if (mounted) _entryControllers[i].forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _persistElo();
  }

  Future<void> _persistElo() async {
    if (_saved) return;
    _saved = true;

    final eloRepo = ref.read(eloRepositoryProvider);
    _previousElo = eloRepo.getCurrentRating();

    final state = ref.read(gameStateProvider);
    final eloResult = state.eloResult;
    if (eloResult != null) {
      await eloRepo.saveResult(eloResult);
      ref.invalidate(eloHistoryProvider);
    }
  }

  @override
  void dispose() {
    for (final c in _entryControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _playAgain() {
    if (_navigating) return;
    _navigating = true;
    final state = ref.read(gameStateProvider);
    context.pushReplacement(
      '/loading',
      extra: GameConfig(topic: state.topic, difficulty: state.difficulty),
    );
  }

  void _newTopic() {
    if (_navigating) return;
    _navigating = true;
    context.go('/topic');
  }

  void _goHome() {
    if (_navigating) return;
    _navigating = true;
    context.go('/home');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);

    final playerScore = state.playerScore;
    final botScore = state.botScore;
    final eloResult = state.eloResult;
    final delta = eloResult?.delta ?? 0;
    final newElo = eloResult?.newRating ?? _previousElo;

    final isWin = playerScore > botScore;
    final isTie = playerScore == botScore;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kScreenPaddingH,
              vertical: 32,
            ),
            child: Column(
              children: [
                const Spacer(),

                // 0 — Heading
                _staggerWrap(
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
                _staggerWrap(
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
                _staggerWrap(
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
                _staggerWrap(
                  3,
                  child: _EloRow(
                    previousElo: _previousElo,
                    delta: delta,
                    newElo: newElo,
                  ),
                ),

                const Spacer(),

                // 4 — Action buttons
                _staggerWrap(
                  4,
                  child: Column(
                    children: [
                      // Play Again
                      _PrimaryButton(label: 'Play Again', onTap: _playAgain),
                      const SizedBox(height: 12),
                      // New Topic
                      _OutlinedButton(label: 'New Topic', onTap: _newTopic),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5 — Home link
                _staggerWrap(
                  5,
                  child: GestureDetector(
                    onTap: _goHome,
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
        ),
      ),
    );
  }

  Widget _staggerWrap(int index, {required Widget child}) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(position: _slideAnimations[index], child: child),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isWinner && !isTie ? [AppShadows.primaryGlowStrong] : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 36,
              fontWeight: FontWeight.bold,
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
