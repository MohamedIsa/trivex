import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/elo_record.dart';
import '../repositories/elo_repository.dart';

part 'elo_history_provider.g.dart';

/// Exposes the last-50 ELO history from the local Hive box.
///
/// Used by [EloSparkline] — no network call, resolves instantly.
@Riverpod(keepAlive: true)
Future<List<EloRecord>> eloHistory(EloHistoryRef ref) async {
  return ref.watch(eloRepositoryProvider).getHistory();
}
