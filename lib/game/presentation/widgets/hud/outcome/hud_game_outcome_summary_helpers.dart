part of 'hud_game_outcome_summary.dart';

HudGameOutcomeTone _tone({
  required String? activePlayerId,
  required String? winnerPlayerId,
}) {
  if (winnerPlayerId == null) return HudGameOutcomeTone.draw;
  if (activePlayerId == null || activePlayerId.isEmpty) {
    return HudGameOutcomeTone.complete;
  }
  return winnerPlayerId == activePlayerId
      ? HudGameOutcomeTone.victory
      : HudGameOutcomeTone.defeat;
}

String _playerName(GameSave save, String playerId) {
  return save.playerById(playerId)?.name ?? playerId;
}

GameOutcome? _authoritativeMultiplayerOutcome({
  required GameSave gameSave,
  required WireMatch? match,
}) {
  if (match == null || match.id != gameSave.id || match.state != 'finished') {
    return null;
  }
  final condition = match.outcomeCondition?.trim().toLowerCase();
  final winnerPlayerId = match.winnerPlayerId?.trim();
  final validWinnerPlayerId =
      winnerPlayerId != null &&
          winnerPlayerId.isNotEmpty &&
          match.players.any((player) => player.id == winnerPlayerId)
      ? winnerPlayerId
      : null;
  return switch (condition) {
    'conquest' when validWinnerPlayerId != null => GameOutcome.conquest(
      validWinnerPlayerId,
    ),
    'domination' when validWinnerPlayerId != null => GameOutcome.domination(
      validWinnerPlayerId,
    ),
    'cultural' when validWinnerPlayerId != null => GameOutcome.cultural(
      validWinnerPlayerId,
    ),
    'score' when validWinnerPlayerId != null => GameOutcome.score(
      winnerPlayerId: validWinnerPlayerId,
      scoreByPlayerId: const {},
    ),
    'resignation' when validWinnerPlayerId != null => GameOutcome.resignation(
      validWinnerPlayerId,
    ),
    'draw' => GameOutcome.draw(scoreByPlayerId: const {}),
    _ => null,
  };
}
