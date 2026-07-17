/// Defines how players participate in a match.
enum GameMode {
  hotSeat,
  multiplayer;

  bool get isMultiplayer => this == GameMode.multiplayer;
}
