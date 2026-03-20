import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_state_notifier.dart';

/// A 15-second countdown controller that integrates with [gameStateProvider].
///
/// - The [AnimationController] ticks from 0.0 → 1.0 over 15 seconds at 60 fps.
/// - UI-004 reads [controller] inside an `AnimatedBuilder` and renders the
///   remaining fraction as `1 - controller.value`.
/// - On completion, [GameStateNotifier.timeExpired] is called automatically.
/// - Call [cancel] the moment the player selects an answer to prevent a
///   spurious [timeExpired] call.
/// - Call [restart] at the start of every new question.
class GameTimer extends ConsumerStatefulWidget {
  const GameTimer({super.key});

  @override
  ConsumerState<GameTimer> createState() => GameTimerState();
}

class GameTimerState extends ConsumerState<GameTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    controller.addStatusListener(_onStatus);

    // Start immediately when the widget is first mounted.
    controller.forward();
  }

  @override
  void dispose() {
    controller.removeStatusListener(_onStatus);
    controller.dispose();
    super.dispose();
  }

  // ── Public API used by Game screen ────────────────────────────────────────

  /// Stops the timer without calling [timeExpired].
  ///
  /// Call this as soon as the player taps an answer.
  void cancel() {
    controller.stop();
  }

  /// Resets the countdown to 15 s and starts it running again.
  ///
  /// Call this when [GameStateNotifier.nextQuestion] advances to a new question.
  void restart() {
    controller.reset();
    controller.forward();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      ref.read(gameStateProvider.notifier).timeExpired();
    }
  }

  @override
  Widget build(BuildContext context) {
    // GameTimer has no visual output of its own — UI-004 accesses the
    // [controller] directly via a GlobalKey<GameTimerState> and wraps it
    // in AnimatedBuilder to draw the timer bar.
    return const SizedBox.shrink();
  }
}
