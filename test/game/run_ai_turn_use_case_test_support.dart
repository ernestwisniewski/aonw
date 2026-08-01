part of 'run_ai_turn_use_case_test.dart';

List<Player> _defaultPlayers(AiStrategyId aiStrategyId) {
  return [
    const Player(id: 'player_1', name: 'Alice', colorValue: 0xFF2563EB),
    Player(
      id: 'player_2',
      name: 'AI Random',
      colorValue: 0xFFDC2626,
      kind: PlayerKind.ai,
      ai: AiPlayer(
        strategyId: aiStrategyId,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.aggressive,
        seed: 123,
      ),
    ),
  ];
}
