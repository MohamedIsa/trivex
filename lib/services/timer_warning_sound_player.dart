import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timer_warning_sound_player.g.dart';

/// Asset path for the timer tick sound (relative to `assets/`).
const String kTimerWarningAsset = 'sounds/timer_warning.wav';

/// Normal tick interval during the question countdown.
const Duration kTickIntervalNormal = Duration(seconds: 1);

/// Fast tick interval during the danger zone (≤ [kTimerWarningSeconds]).
const Duration kTickIntervalFast = Duration(milliseconds: 350);

/// [AudioContext] that forces sound through the alarm stream on Android and
/// ignores the silent switch on iOS, so the timer tick is always
/// audible regardless of device ringer/silent mode.
final _kAudioContext = AudioContext(
  android: AudioContextAndroid(
    usageType: AndroidUsageType.alarm,
    contentType: AndroidContentType.sonification,
    audioFocus: AndroidAudioFocus.gain,
  ),
  iOS: AudioContextIOS(
    category: AVAudioSessionCategory.playback,
  ),
);

/// Plays a repeating tick sound at a configurable interval.
///
/// Provided via Riverpod so tests can override with a fake that records calls
/// without touching real audio hardware or the asset bundle.
class TimerWarningSoundPlayer {
  TimerWarningSoundPlayer() : _player = AudioPlayer() {
    _player.setAudioContext(_kAudioContext);
  }

  final AudioPlayer _player;
  Timer? _tickTimer;

  /// Play the tick sound once (fire-and-forget).
  void play() {
    _player.play(AssetSource(kTimerWarningAsset));
  }

  /// Start repeating the tick at [interval].
  ///
  /// Cancels any currently running tick loop before starting a new one.
  /// Plays immediately, then repeats at [interval].
  void startTicking(Duration interval) {
    stopTicking();
    play();
    _tickTimer = Timer.periodic(interval, (_) => play());
  }

  /// Stop the repeating tick.
  void stopTicking() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// Release native resources.
  Future<void> dispose() async {
    stopTicking();
    await _player.dispose();
  }
}

@riverpod
TimerWarningSoundPlayer timerWarningSoundPlayer(Ref ref) {
  final player = TimerWarningSoundPlayer();
  ref.onDispose(player.dispose);
  return player;
}
