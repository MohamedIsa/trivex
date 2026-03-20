/// RoundResult — produced at the end of a game round and passed to UI-006.
class RoundResult {
  final int playerScore;
  final int botScore;
  final int eloChange;
  final int newElo;

  const RoundResult({
    required this.playerScore,
    required this.botScore,
    required this.eloChange,
    required this.newElo,
  });

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
