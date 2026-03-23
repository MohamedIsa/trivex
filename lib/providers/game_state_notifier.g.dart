// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gameStateNotifierHash() => r'50bf14339cf0e25b5bb5bbf244a5ad579e44c667';

/// Central game-state manager backed by the [GamePhase] sealed union.
///
/// Consumed by the Game screen, Reveal sheet, Result screen, and Loading
/// screen.  The timer drives [timeExpired].
/// ELO calculation runs inside [nextQuestion] when the last question is
/// revealed.
///
/// Copied from [GameStateNotifier].
@ProviderFor(GameStateNotifier)
final gameStateNotifierProvider =
    NotifierProvider<GameStateNotifier, GamePhase>.internal(
  GameStateNotifier.new,
  name: r'gameStateNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gameStateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GameStateNotifier = Notifier<GamePhase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
