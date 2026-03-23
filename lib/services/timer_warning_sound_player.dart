import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timer_warning_sound_player.g.dart';

/// Asset path for the timer warning beep (relative to `assets/`).
const String kTimerWarningAsset = 'sounds/timer_warning.wav';

/// Thin wrapper around [AudioPlayer] that plays the timer-warning beep.
///
/// Provided via Riverpod so tests can override with a fake that records calls
/// without touching real audio hardware or the asset bundle.
class TimerWarningSoundPlayer {
  TimerWarningSoundPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  /// Play the warning beep once (fire-and-forget).
  void play() {
    _player.play(AssetSource(kTimerWarningAsset));
  }

  /// Release native resources.
  Future<void> dispose() => _player.dispose();
}

@riverpod
TimerWarningSoundPlayer timerWarningSoundPlayer(Ref ref) {
  final player = TimerWarningSoundPlayer();
  ref.onDispose(player.dispose);
  return player;
}
