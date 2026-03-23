import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/animation_constants.dart';
import '../constants/layout_constants.dart';
import '../providers/game_state_notifier.dart';
import '../state/game_phase.dart';
import '../theme/app_colors.dart';
import '../widgets/game_timer.dart';
import '../widgets/reveal_bottom_sheet.dart';

/// Game screen — core question loop .
///
/// Fixed top bar with Q number + live scores, a colour-shifting timer bar,
/// question text with slide-in animation, and four answer tiles that change
/// style on reveal.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _timerController = GameTimerController();

  /// Scale factor when a tile is being tapped.
  int? _pressedIndex;

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _onTileTap(int index) {
    final phase = ref.read(gameStateNotifierProvider);
    if (phase is! PlayingPhase) return;

    // Haptic on answer selection.
    HapticFeedback.mediumImpact();

    final controller = _timerController.controller;
    final remaining = controller != null
        ? ((1.0 - controller.value) *
                phase.round.currentQuestion.timeLimit)
            .round()
        : 0;

    _timerController.cancel();
    ref
        .read(gameStateNotifierProvider.notifier)
        .selectAnswer(index, timeLeft: remaining);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(gameStateNotifierProvider);

    // Extract the active round from Playing or Revealing phases.
    final GameRound round;
    final bool isRevealing;
    final int? selectedIndex;

    switch (phase) {
      case PlayingPhase(round: final r):
        round = r;
        isRevealing = false;
        selectedIndex = null;
      case RevealingPhase(round: final r, selectedIndex: final si):
        round = r;
        isRevealing = true;
        selectedIndex = si;
      default:
        // Guard: idle / loading / finished — show nothing.
        return const Scaffold(backgroundColor: AppColors.background);
    }

    final textDirection =
        round.language == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return PopScope(
      canPop: phase is IdlePhase || phase is FinishedPhase,
      child: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Stack(
              children: [
                // ── Game content layer ────────────────────────────────────────
                Column(
                  children: [
                    // ── Top bar ──────────────────────────────────────────────
                    _TopBar(round: round),

                    // ── Timer bar ────────────────────────────────────────────
                    GameTimer(
                      timerController: _timerController,
                      duration: Duration(
                        seconds: round.currentQuestion.timeLimit,
                      ),
                    ),
                    _TimerBar(timerController: _timerController),

                    // ── Question + Tiles (scrollable) ─────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kScreenPaddingH,
                          vertical: kScreenPaddingH,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question text — slides in on each new question.
                            _QuestionText(
                              round: round,
                              isRevealing: isRevealing,
                            ),

                            const SizedBox(height: 32),

                            // Answer tiles
                            _AnswerTileList(
                              round: round,
                              isRevealing: isRevealing,
                              selectedIndex: selectedIndex,
                              pressedIndex: _pressedIndex,
                              onTapDown: (i) =>
                                  setState(() => _pressedIndex = i),
                              onTapUp: (i) {
                                setState(() => _pressedIndex = null);
                                _onTileTap(i);
                              },
                              onTapCancel: () =>
                                  setState(() => _pressedIndex = null),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Reveal overlay ────────────────────────────────────────────────
                RevealBottomSheet(timerController: _timerController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-widgets (private, same file)
// ═══════════════════════════════════════════════════════════════════════════════

// ── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.round});

  final GameRound round;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kScreenPaddingH,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            label:
                'Question ${round.currentIndex + 1} of ${round.questions.length}',
            child: Text(
              'Q ${round.currentIndex + 1} / ${round.questions.length}',
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Semantics(
            label:
                'Your score: ${round.playerScore}, Bot score: ${round.botScore}',
            child: Row(
              children: [
                Text(
                  'You ${round.playerScore}',
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  ' · ',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                Text(
                  'Bot ${round.botScore}',
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timer bar ───────────────────────────────────────────────────────────────

class _TimerBar extends StatelessWidget {
  const _TimerBar({required this.timerController});

  final GameTimerController timerController;

  Color _barColor(double remaining) {
    if (remaining > 0.6) return AppColors.primary;
    if (remaining > 0.3) return AppColors.muted;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final controller = timerController.controller;

    // If the controller isn't ready yet, draw the full-width bar.
    if (controller == null) {
      return SizedBox(
        height: kTimerBarHeight,
        child: Container(color: AppColors.primary),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) {
          final remaining = 1.0 - controller.value;
          final seconds = (remaining * controller.duration!.inSeconds).ceil();
          return Semantics(
            label: 'Time remaining: $seconds seconds',
            child: SizedBox(
              height: kTimerBarHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(color: AppColors.card),
                  FractionallySizedBox(
                    widthFactor: remaining,
                    child: Container(color: _barColor(remaining)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Question text ───────────────────────────────────────────────────────────

class _QuestionText extends StatelessWidget {
  const _QuestionText({required this.round, required this.isRevealing});

  final GameRound round;
  final bool isRevealing;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: kRevealSlide,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: AnimatedOpacity(
        key: ValueKey(round.currentIndex),
        opacity: isRevealing ? 0.5 : 1.0,
        duration: kButtonTransition,
        child: Text(
          round.currentQuestion.question,
          softWrap: true,
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

// ── Answer tile list ────────────────────────────────────────────────────────

class _AnswerTileList extends StatelessWidget {
  const _AnswerTileList({
    required this.round,
    required this.isRevealing,
    required this.selectedIndex,
    required this.pressedIndex,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  final GameRound round;
  final bool isRevealing;
  final int? selectedIndex;
  final int? pressedIndex;
  final ValueChanged<int> onTapDown;
  final ValueChanged<int> onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isRevealing,
      child: Column(
        children: [
          for (int i = 0; i < round.currentQuestion.options.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _AnswerTile(
              index: i,
              round: round,
              isRevealing: isRevealing,
              selectedIndex: selectedIndex,
              isPressed: pressedIndex == i,
              onTapDown: () => onTapDown(i),
              onTapUp: () => onTapUp(i),
              onTapCancel: onTapCancel,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Answer tile ─────────────────────────────────────────────────────────────

class _AnswerTile extends HookWidget {
  const _AnswerTile({
    required this.index,
    required this.round,
    required this.isRevealing,
    required this.selectedIndex,
    required this.isPressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  static const _labels = ['A', 'B', 'C', 'D'];

  final int index;
  final GameRound round;
  final bool isRevealing;
  final int? selectedIndex;
  final bool isPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    final isCorrectTile = index == round.currentQuestion.correctIndex;
    final isSelectedWrong = selectedIndex == index && !isCorrectTile;

    // ── Shake animation for wrong answer ────────────────────────────────
    final shakeCtrl = useAnimationController(duration: kShakeDuration);
    final shakeOffset = useMemoized(
      () => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 6, end: -6), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
      ]).animate(CurvedAnimation(parent: shakeCtrl, curve: Curves.easeInOut)),
      [shakeCtrl],
    );

    // Trigger shake + haptic when this tile is the selected-wrong tile on
    // reveal. Only fire once per reveal (check controller is dismissed).
    useEffect(() {
      if (isRevealing && isSelectedWrong && shakeCtrl.isDismissed) {
        HapticFeedback.lightImpact();
        shakeCtrl.forward(from: 0);
      }
      if (isRevealing &&
          isCorrectTile &&
          selectedIndex != null &&
          selectedIndex == round.currentQuestion.correctIndex) {
        HapticFeedback.heavyImpact();
      }
      return null;
    }, [isRevealing, round.currentIndex]);

    // ── Resolve reveal colours ──────────────────────────────────────────
    Color bg;
    Color borderColor;
    Color textColor;
    Color badgeColor;
    Color badgeTextColor;

    if (!isRevealing) {
      bg = AppColors.card;
      borderColor = AppColors.border;
      textColor = AppColors.foreground;
      badgeColor = AppColors.primary;
      badgeTextColor = AppColors.foreground;
    } else if (isCorrectTile) {
      bg = AppColors.teal;
      borderColor = AppColors.teal;
      textColor = AppColors.background;
      badgeColor = AppColors.background;
      badgeTextColor = AppColors.foreground;
    } else if (isSelectedWrong) {
      bg = AppColors.red;
      borderColor = AppColors.red;
      textColor = AppColors.foreground;
      badgeColor = AppColors.background;
      badgeTextColor = AppColors.foreground;
    } else {
      bg = AppColors.cardDimmed;
      borderColor = AppColors.border;
      textColor = AppColors.mutedHalf;
      badgeColor = AppColors.mutedFaint;
      badgeTextColor = AppColors.foregroundHalf;
    }

    // ── Scale on tap ────────────────────────────────────────────────────
    final scale = (!isRevealing && isPressed) ? 0.98 : 1.0;

    return Semantics(
      label:
          'Option ${_labels[index]}: ${round.currentQuestion.options[index]}',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) => onTapUp(),
        onTapCancel: onTapCancel,
        child: AnimatedScale(
          scale: scale,
          duration: kTapScale,
          child: AnimatedBuilder(
            animation: shakeOffset,
            builder: (_, child) => Transform.translate(
              offset: Offset(shakeOffset.value, 0),
              child: child,
            ),
            child: Container(
              constraints: const BoxConstraints(minHeight: kMinTapTarget),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(kCardRadius),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  // Badge
                  Container(
                    width: kBadgeSize,
                    height: kBadgeSize,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _labels[index],
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Option text
                  Expanded(
                    child: Text(
                      round.currentQuestion.options[index],
                      softWrap: true,
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
