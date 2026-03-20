import 'package:hive/hive.dart';

part 'elo_record.g.dart';

@HiveType(typeId: 0)
class EloRecord extends HiveObject {
  @HiveField(0)
  final int rating;

  @HiveField(1)
  final DateTime timestamp;

  EloRecord({required this.rating, required this.timestamp});
}
