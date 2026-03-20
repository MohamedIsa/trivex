import 'package:freezed_annotation/freezed_annotation.dart';

part 'round_result.freezed.dart';

/// RoundResult — produced at the end of a game round and passed to UI-006.
@Freezed(fromJson: false, toJson: false)
class RoundResult with _$RoundResult {
  const RoundResult._();

  const factory RoundResult({
    required int playerScore,
    required int botScore,
    required int eloChange,
    required int newElo,
  }) = _RoundResult;

  factory RoundResult.fromJson(Map<String, dynamic> json) => RoundResult(
        playerScore: json['playerScore'] as int,
        botScore: json['botScore'] as int,
        eloChange: json['eloChange'] as int,
        newElo: json['newElo'] as int,
      );

  Map<String, dynamic> toJson() => {
        'playerScore': playerScore,
        'botScore': botScore,
        'eloChange': eloChange,
        'newElo': newElo,
      };
}
