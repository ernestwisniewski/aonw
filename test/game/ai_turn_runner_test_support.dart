part of 'ai_turn_runner_test.dart';

AiContext _context({required int turn}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: _mapData,
    turn: turn,
    rng: AiRng.fromTurn(turn: turn, playerId: 'player_1', baseSeed: 7),
  );
}
