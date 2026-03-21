// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'elo_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eloHistoryHash() => r'a5fc5b5f22e30a77ab009fc2ad6d7331e3a7e3ea';

/// Exposes the last-50 ELO history from the local Hive box.
///
/// Used by [EloSparkline] — no network call, resolves instantly.
///
/// Copied from [eloHistory].
@ProviderFor(eloHistory)
final eloHistoryProvider = FutureProvider<List<EloRecord>>.internal(
  eloHistory,
  name: r'eloHistoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$eloHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EloHistoryRef = FutureProviderRef<List<EloRecord>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
