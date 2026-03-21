import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
class RevealBottomSheet extends HookConsumerWidget {
  const RevealBottomSheet({super.key, required this.timerController});

  /// Shared controller for restarting the timer when the player taps "Next".
  final GameTimerController timerController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slideController = useAnimationController(duration: kEntryDuration);

    final offsetAnimation = useMemoized(
      () => Tween<Offset>(
        begin: const Offset(0, 1), // fully off-screen below
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: slideController, curve: kSpringCurve),
      ),
      [slideController],
    );

    final nextPressed = useState(false);

    // Sync sheet on first build if already revealing.
    useEffect(() {
      final isRevealing = ref.read(gameStateNotifierProvider).isRevealing;
      if (isRevealing &&
          !slideController.isAnimating &&
          slideController.value == 0) {
        slideController.forward();
      }
      return null;
    }, const []);

    // ── Next / Results tap ──────────────────────────────────────────────────

    void onNextTap() {
      final notifier = ref.read(gameStateNotifierProvider.notifier);

      notifier.nextQuestion();

      final newState = ref.read(gameStateNotifierProvider);

      if (newState.isGameOver) {
        context.pushReplacement('/result');
      } else {
        // Slide sheet down, then restart timer for the next question.
        final nextTimeLimit = newState.currentQuestion.timeLimit;
        slideController.reverse().then((_) {
          timerController.restart(
            duration: Duration(seconds: nextTimeLimit),
          );
        });
      }
    }

    // ── Build ───────────────────────────────────────────────────────────────

    // Drive slide in/out reactively via ref.listen (not a side effect in build).
    // _SheetPanel watches the provider directly (ConsumerWidget) so
    // state is always fresh — we no longer capture it here.
    ref.listen<GameState>(gameStateNotifierProvider, (previous, next) {
      if (next.isRevealing && !(previous?.isRevealing ?? false)) {
        slideController.forward();
      } else if (!next.isRevealing &&
          slideController.status == AnimationStatus.completed) {
        slideController.reverse();
      }
    });

    // Don't render anything when fully hidden and not animating.
    return AnimatedBuilder(
      animation: slideController,
      builder: (_, _) {
        if (slideController.value == 0) return const SizedBox.shrink();

        return Stack(
          children: [
            // ── Backdrop ──────────────────────────────────────────────────
            GestureDetector(
              onTap: () {}, // absorb taps — do NOT dismiss
              child: FadeTransition(
                opacity: slideController,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(color: AppColors.backdropOverlay),
                  ),
                ),
              ),
            ),

            // ── Bottom sheet panel ────────────────────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: RepaintBoundary(
                child: SlideTransition(
                  position: offsetAnimation,
                  child: _SheetPanel(
                    isNextPressed: nextPressed.value,
                    onNextTapDown: () => nextPressed.value = true,
                    onNextTapUp: () {
                      nextPressed.value = false;
                      onNextTap();
                    },
                    onNextTapCancel: () => nextPressed.value = false,
                  ),
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

class _SheetPanel extends ConsumerWidget {
  const _SheetPanel({
    required this.isNextPressed,
    required this.onNextTapDown,
    required this.onNextTapUp,
    required this.onNextTapCancel,
  });

  final bool isNextPressed;
  final VoidCallback onNextTapDown;
  final VoidCallback onNextTapUp;
  final VoidCallback onNextTapCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateNotifierProvider);

    final isCorrect = state.selectedIndex != null &&
        state.selectedIndex == state.currentQuestion.correctIndex;
    final isTimeout = state.selectedIndex == null;
    final accentColor = isCorrect ? AppColors.teal : AppColors.red;
    final heading = isTimeout
        ? "Time's Up!"
        : isCorrect
            ? 'Correct!'
            : 'Wrong!';

    final correctIdx = state.currentQuestion.correctIndex;
    final correctLetter = String.fromCharCode(65 + correctIdx);
    final isLastQuestion = state.currentIndex >= state.questions.length - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        kCardPadding,
        kCardPadding,
        kCardPadding,
        32,
      ),
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
              color: accentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCorrect ? Icons.check : Icons.close,
              color: Colors.white,
              size: kIconSize,
            ),
          ),

          const SizedBox(height: 16),

          // ── Heading ──────────────────────────────────────────────────────
          Text(
            heading,
            style: TextStyle(
              color: accentColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // ── Explanation box ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.all(Radius.circular(kButtonRadius)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct: $correctLetter',
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
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
