import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/elo_record.dart';
import '../repositories/elo_repository.dart';

/// Exposes the last-50 ELO history from the local Hive box.
///
/// Used by [EloSparkline] — no network call, resolves instantly.
final eloHistoryProvider = FutureProvider<List<EloRecord>>((ref) {
  return ref.watch(eloRepositoryProvider).getHistory();
});
