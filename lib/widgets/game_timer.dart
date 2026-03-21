import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/animation_constants.dart';
import '../providers/game_state_notifier.dart';

// ---------------------------------------------------------------------------
// Controller — shared handle for cancel / restart / reading the animation.
// ---------------------------------------------------------------------------

/// Lightweight object that exposes [cancel] and [restart] for the game timer.
///
/// Created by the parent ([GameScreen]) and passed to [GameTimer],
/// [_TimerBar], and [RevealBottomSheet].
class GameTimerController {
  /// The [AnimationController] driving the countdown.
  ///
  /// Set by [GameTimer] during its first build via [useEffect].
  AnimationController? controller;

  /// Stops the timer without calling [GameStateNotifier.timeExpired].
  void cancel() => controller?.stop();

  /// Resets the countdown and starts it running again.
  ///
  /// If [duration] is provided the controller's duration is updated first.
  void restart({Duration? duration}) {
    if (duration != null) controller?.duration = duration;
    controller?.reset();
    controller?.forward();
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A countdown timer that integrates with [gameStateNotifierProvider].
///
/// - Uses [useAnimationController] internally — automatic disposal.
/// - On completion, [GameStateNotifier.timeExpired] is called automatically.
/// - Call [GameTimerController.cancel] the moment the player selects an
///   answer to prevent a spurious timeout.
/// - Call [GameTimerController.restart] at the start of every new question.
class GameTimer extends HookConsumerWidget {
  const GameTimer({
    super.key,
    required this.timerController,
    this.duration = kTimerDuration,
  });

  /// Shared controller object used by the game screen and reveal sheet.
  final GameTimerController timerController;

  /// The countdown duration for the current question.
  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController(duration: duration);

    // Wire up the shared controller handle and start the timer.
    useEffect(() {
      timerController.controller = controller;

      void onStatus(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          ref.read(gameStateNotifierProvider.notifier).timeExpired();
        }
      }

      controller.addStatusListener(onStatus);
      controller.forward();
      return () => controller.removeStatusListener(onStatus);
    }, [controller]);

    // GameTimer has no visual output of its own — the parent wraps
    // timerController.controller in AnimatedBuilder to draw the timer bar.
    return const SizedBox.shrink();
  }
}
