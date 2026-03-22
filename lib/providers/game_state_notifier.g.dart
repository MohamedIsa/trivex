// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gameStateNotifierHash() => r'0cd609f6bb2e23e20e5ab2e2f4e7c31eff4892aa';

/// Central game-state manager.
///
/// Consumed by the Game screen (UI-004) and Reveal screen (UI-005).
/// The timer (GAME-003) drives [timeExpired].
/// ELO calculation (ELO-001) reads [state] after [isGameOver] becomes true.
///
/// Copied from [GameStateNotifier].
@ProviderFor(GameStateNotifier)
final gameStateNotifierProvider =
    NotifierProvider<GameStateNotifier, GameState>.internal(
  GameStateNotifier.new,
  name: r'gameStateNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$gameStateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GameStateNotifier = Notifier<GameState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
