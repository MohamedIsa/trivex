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
}
