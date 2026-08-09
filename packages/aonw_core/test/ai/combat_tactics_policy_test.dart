import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('effective combat aggression composes all AI profile multipliers', () {
    final mapData = WorldMap(
      cols: 1,
      rows: 1,
      tiles: [
        WorldTile(
          col: 0,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
      ],
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
      persona: AiPersona.aggressive,
      difficulty: AiDifficulty.hard,
    );
    final expected =
        context.effectiveWeights.aggression *
        context.civProfile.belligerence *
        context.difficultyProfile.combatRiskMultiplier;

    expect(
      AiCombatTactics.effectiveAggression(context),
      closeTo(expected, 1e-9),
    );
  });
}
