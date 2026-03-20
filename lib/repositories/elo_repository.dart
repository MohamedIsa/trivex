import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/elo_record.dart';
import '../services/elo_service.dart';

/// Persists ELO history via a Hive box named `'elo_history'`.
///
/// The box must be opened before constructing this class — see `main()`.
class EloRepository {
  static const String boxName = 'elo_history';
  static const int _maxRecords = 50;
  static const int _defaultRating = 1000;

  Box<EloRecord> get _box => Hive.box<EloRecord>(boxName);

  /// Appends a new [EloRecord] derived from [result] and caps the box at
  /// [_maxRecords] entries. The write is **awaited** to guarantee persistence
  /// before navigation.
  Future<void> saveResult(EloResult result) async {
    final record = EloRecord(
      rating: result.newRating,
      timestamp: DateTime.now(),
    );
    await _box.add(record);

    // Trim oldest entries to keep at most 50 records.
    while (_box.length > _maxRecords) {
      await _box.deleteAt(0);
    }
  }

  /// Returns the most recent ELO rating, or `1000` if no history exists.
  int getCurrentRating() {
    if (_box.isEmpty) return _defaultRating;
    return _box.getAt(_box.length - 1)!.rating;
  }

  /// Returns up to the last 50 [EloRecord] entries (most recent last).
  List<EloRecord> getHistory() {
    return _box.values.toList();
  }
}

/// Riverpod provider for [EloRepository].
final eloRepositoryProvider = Provider<EloRepository>((ref) {
  return EloRepository();
});
