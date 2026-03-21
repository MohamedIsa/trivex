import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import '../constants/animation_constants.dart';
import '../constants/layout_constants.dart';
import '../providers/game_state_notifier.dart';
import '../theme/app_colors.dart';
import '../widgets/game_timer.dart';
import '../widgets/reveal_bottom_sheet.dart';

/// Game screen — core question loop (UI-004).
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

  void _onTileTap(int index, GameState state) {
    if (state.isRevealing || state.isGameOver) return;

    final controller = _timerController.controller;
    final remaining = controller != null
        ? ((1.0 - controller.value) * state.currentQuestion.timeLimit).round()
        : 0;

    _timerController.cancel();
    ref
        .read(gameStateNotifierProvider.notifier)
        .selectAnswer(index, timeLeft: remaining);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateNotifierProvider);

    // Guard: if questions haven't been loaded yet, show nothing.
    if (state.questions.isEmpty) {
      return const Scaffold(backgroundColor: AppColors.background);
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Game content layer ────────────────────────────────────────
              Column(
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  _TopBar(state: state),

                  // ── Timer bar ────────────────────────────────────────────
                  GameTimer(
                    timerController: _timerController,
                    duration: Duration(
                      seconds: state.currentQuestion.timeLimit,
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
                          _QuestionText(state: state),

                          const SizedBox(height: 32),

                          // Answer tiles
                          _AnswerTileList(
                            state: state,
                            pressedIndex: _pressedIndex,
                            onTapDown: (i) =>
                                setState(() => _pressedIndex = i),
                            onTapUp: (i) {
                              setState(() => _pressedIndex = null);
                              _onTileTap(i, state);
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

              // ── Reveal overlay (UI-005) ─────────────────────────────────
              RevealBottomSheet(timerController: _timerController),
            ],
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
  const _TopBar({required this.state});

  final GameState state;

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
          Text(
            'Q ${state.currentIndex + 1} / ${state.questions.length}',
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text(
                'You ${state.playerScore}',
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
                'Bot ${state.botScore}',
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
          return SizedBox(
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
          );
        },
      ),
    );
  }
}

// ── Question text ───────────────────────────────────────────────────────────

class _QuestionText extends StatelessWidget {
  const _QuestionText({required this.state});

  final GameState state;

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
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: AnimatedOpacity(
        key: ValueKey(state.currentIndex),
        opacity: state.isRevealing ? 0.5 : 1.0,
        duration: kButtonTransition,
        child: Text(
          state.currentQuestion.question,
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
    required this.state,
    required this.pressedIndex,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  final GameState state;
  final int? pressedIndex;
  final ValueChanged<int> onTapDown;
  final ValueChanged<int> onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: state.isRevealing,
      child: Column(
        children: [
          for (int i = 0; i < state.currentQuestion.options.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _AnswerTile(
              index: i,
              state: state,
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

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.index,
    required this.state,
    required this.isPressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  static const _labels = ['A', 'B', 'C', 'D'];

  final int index;
  final GameState state;
  final bool isPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    final isCorrectTile = index == state.currentQuestion.correctIndex;
    final isSelectedWrong = state.selectedIndex == index && !isCorrectTile;

    // ── Resolve reveal colours ──────────────────────────────────────────
    Color bg;
    Color borderColor;
    Color textColor;
    Color badgeColor;
    Color badgeTextColor;

    if (!state.isRevealing) {
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
    final scale = (!state.isRevealing && isPressed) ? 0.98 : 1.0;

    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: scale,
        duration: kTapScale,
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
                  state.currentQuestion.options[index],
                  softWrap: true,
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
