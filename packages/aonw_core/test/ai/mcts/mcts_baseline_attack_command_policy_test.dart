import 'package:aonw_core/ai/mcts/mcts_baseline_attack_command_policy.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsBaselineAttackCommandPolicy city pressure', () {
    test('allows an effective attack against a pressure-target city', () {
      final fixture = _fixture(pressureTarget: true);

      expect(
        const MctsBaselineAttackCommandPolicy().canAppendPressureAttack(
          fixture.command,
          view: fixture.view,
          context: fixture.context,
          attackedTargets: const {},
        ),
        isTrue,
      );
    });

    test('rejects the same attack when the city is not a pressure target', () {
      final fixture = _fixture(pressureTarget: false);

      expect(
        const MctsBaselineAttackCommandPolicy().canAppendPressureAttack(
          fixture.command,
          view: fixture.view,
          context: fixture.context,
          attackedTargets: const {},
        ),
        isFalse,
      );
    });
  });
}

({AttackHexCommand command, GameView view, AiContext context}) _fixture({
  required bool pressureTarget,
}) {
  final mapData = WorldMap(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        WorldTile(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
  final view = GameView.fromDomainState(
    DomainState.snapshot(
      units: [
        GameUnit.produced(
          id: 'tank_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.tank,
          col: 0,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'enemy_city',
          ownerPlayerId: 'player_2',
          name: 'Enemy City',
          center: CityHex(col: 1, row: 0),
        ),
      ],
    ),
    forPlayerId: 'player_1',
    turn: 20,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
    pressureTargetPlayerIds: pressureTarget ? const ['player_2'] : const [],
    ignoreFogOfWar: true,
    ignoreDynamicFogOfWar: true,
  );
  final context = AiContext(
    ruleset: view.ruleset,
    mapData: mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 17,
    ),
  );

  return (
    command: const AttackHexCommand('tank_1', 1, 0),
    view: view,
    context: context,
  );
}
