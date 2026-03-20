import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/animation_constants.dart';
import '../constants/layout_constants.dart';
import '../models/game_state.dart';
import '../providers/game_state_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../widgets/game_timer.dart';

/// Reveal overlay — slides up over the game screen when `isRevealing` is true.
///
/// Shows result icon, heading, explanation box, and Next / Results button.
/// Mounted as a [Stack] child inside [GameScreen].
class RevealBottomSheet extends ConsumerStatefulWidget {
  const RevealBottomSheet({
    super.key,
    required this.timerKey,
  });

  /// Used to call [GameTimerState.restart] when the player taps "Next".
  final GlobalKey<GameTimerState> timerKey;

  @override
  ConsumerState<RevealBottomSheet> createState() => _RevealBottomSheetState();
}

class _RevealBottomSheetState extends ConsumerState<RevealBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _offsetAnimation;
  bool _nextPressed = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: kEntryDuration,
    );

    // Approximate spring with easeOutBack — fast overshoot, then settle.
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // fully off-screen below
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: kSpringCurve,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // ── React to isRevealing changes ──────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSheet();
  }

  void _syncSheet() {
    final isRevealing = ref.read(gameStateProvider).isRevealing;
    if (isRevealing && !_slideController.isAnimating && _slideController.value == 0) {
      _slideController.forward();
    }
  }

  // ── Next / Results tap ────────────────────────────────────────────────────

  void _onNextTap() {
    final notifier = ref.read(gameStateProvider.notifier);

    notifier.nextQuestion();

    final newState = ref.read(gameStateProvider);

    if (newState.isGameOver) {
      Navigator.pushReplacementNamed(context, '/result');
    } else {
      // Slide sheet down, then restart timer for the next question.
      _slideController.reverse().then((_) {
        widget.timerKey.currentState?.restart();
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);

    // Drive slide in/out reactively via ref.listen (not a side effect in build).
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      if (next.isRevealing && _slideController.status == AnimationStatus.dismissed) {
        _slideController.forward();
      } else if (!next.isRevealing && _slideController.status == AnimationStatus.completed) {
        _slideController.reverse();
      }
    });

    // Don't render anything when fully hidden and not animating.
    return AnimatedBuilder(
      animation: _slideController,
      builder: (_, __) {
        if (_slideController.value == 0) return const SizedBox.shrink();

        return Stack(
          children: [
            // ── Backdrop ──────────────────────────────────────────────────
            GestureDetector(
              onTap: () {}, // absorb taps — do NOT dismiss
              child: FadeTransition(
                opacity: _slideController,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      color: AppColors.backdropOverlay,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom sheet panel ────────────────────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _offsetAnimation,
                child: _SheetPanel(
                  state: state,
                  isNextPressed: _nextPressed,
                  onNextTapDown: () => setState(() => _nextPressed = true),
                  onNextTapUp: () {
                    setState(() => _nextPressed = false);
                    _onNextTap();
                  },
                  onNextTapCancel: () => setState(() => _nextPressed = false),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-widgets (private)
// ═══════════════════════════════════════════════════════════════════════════════

class _SheetPanel extends StatelessWidget {
  const _SheetPanel({
    required this.state,
    required this.isNextPressed,
    required this.onNextTapDown,
    required this.onNextTapUp,
    required this.onNextTapCancel,
  });

  final GameState state;
  final bool isNextPressed;
  final VoidCallback onNextTapDown;
  final VoidCallback onNextTapUp;
  final VoidCallback onNextTapCancel;

  bool get _isCorrect =>
      state.selectedIndex != null &&
      state.selectedIndex == state.currentQuestion.correctIndex;

  bool get _isTimeout => state.selectedIndex == null;

  Color get _accentColor => _isCorrect ? AppColors.teal : AppColors.red;

  String get _heading {
    if (_isTimeout) return "Time's Up!";
    return _isCorrect ? 'Correct!' : 'Wrong!';
  }

  @override
  Widget build(BuildContext context) {
    final correctIdx = state.currentQuestion.correctIndex;
    final correctLetter = String.fromCharCode(65 + correctIdx);
    final isLastQuestion = state.currentIndex >= 9;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(kCardPadding, kCardPadding, kCardPadding, 32),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(kCardPadding)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Result icon ──────────────────────────────────────────────────
          Container(
            width: kResultIconSize,
            height: kResultIconSize,
            decoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isCorrect ? Icons.check : Icons.close,
              color: Colors.white,
              size: kIconSize,
            ),
          ),

          const SizedBox(height: 16),

          // ── Heading ──────────────────────────────────────────────────────
          Text(
            _heading,
            style: TextStyle(
              color: _accentColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // ── Explanation box ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(kButtonRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct: $correctLetter',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.currentQuestion.explanation,
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Next / Results button ────────────────────────────────────────
          GestureDetector(
            onTapDown: (_) => onNextTapDown(),
            onTapUp: (_) => onNextTapUp(),
            onTapCancel: onNextTapCancel,
            child: AnimatedScale(
              scale: isNextPressed ? 0.98 : 1.0,
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
                  isLastQuestion ? 'Results' : 'Next →',
                  style: const TextStyle(
                    color: AppColors.foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
