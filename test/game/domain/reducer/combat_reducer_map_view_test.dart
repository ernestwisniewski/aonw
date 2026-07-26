import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/combat/combat_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('previews a city target through a canonical map lookup', () {
    final attacker = _unit('attacker', 'player_1', 0, 0);
    const city = GameCity(
      id: 'city_2',
      ownerPlayerId: 'player_2',
      name: 'City',
      center: CityHex(col: 1, row: 0),
    );
    final state = GameState(
      activePlayerId: 'player_1',
      units: [attacker],
      cities: const [city],
      fogOfWar: _visibleCombatFog(),
      interaction: GameInteractionState(
        selection: GameSelection.unit(attacker),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'attacker',
        ),
      ),
    );
    final MapTileLookup mapTiles = WorldMapReadView(_worldMap());
    const command = AttackHexCommand('attacker', 1, 0);

    final preview = CombatReducer.selectAttackTarget(
      state,
      command,
      mapTiles,
      combatRuleset: _combatRuleset,
      context: _context,
    );

    final pending = preview.state.pendingAction as PendingAttackTargeting;
    expect(pending.defenderCol, 1);
    expect(pending.defenderRow, 0);
    expect(preview.state.units, state.units);
    expect(preview.state.selection?.unit, same(attacker));
    expect(preview.events, isEmpty);
    expect(preview.uiEffects, isEmpty);
  });

  test('resolves unit combat through a canonical map lookup', () {
    final attacker = _unit('attacker', 'player_1', 0, 0);
    final defender = _unit('defender', 'player_2', 1, 0);
    final state = GameState(
      activePlayerId: 'player_1',
      units: [attacker, defender],
      fogOfWar: _visibleCombatFog(),
      interaction: GameInteractionState(
        selection: GameSelection.unit(attacker),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'attacker',
        ),
      ),
    );
    final MapTileLookup mapTiles = WorldMapReadView(_worldMap());
    const command = AttackHexCommand('attacker', 1, 0);

    final preview = CombatReducer.selectAttackTarget(
      state,
      command,
      mapTiles,
      combatRuleset: _combatRuleset,
      context: _context,
    );
    final result = CombatReducer.attackHex(
      preview.state,
      command,
      mapTiles,
      combatRuleset: _combatRuleset,
      context: _context,
    );

    final updatedAttacker = result.state.unitById('attacker')!;
    final updatedDefender = result.state.unitById('defender')!;
    expect(result.state.pendingAction, isNull);
    expect(updatedAttacker.hitPoints, 5);
    expect(updatedAttacker.movementPoints, 0);
    expect(updatedDefender.hitPoints, 7);
    expect(result.events.whereType<UnitAttackedEvent>(), hasLength(1));
    expect(result.events.whereType<UnitGainedExperienceEvent>(), hasLength(2));
    final resolved = result.events.whereType<CombatResolvedEvent>().single;
    expect(
      resolved.outcome.steps.whereType<ModifierAppliedStep>().map(
        (step) => step.modifier,
      ),
      contains(
        const TerrainModifier(
          label: 'terrain.forest.defense',
          target: CombatStatTarget.defense,
          delta: 2,
        ),
      ),
    );
    expect(result.uiEffects.whereType<PlayCombatAnimationEffect>(), isEmpty);
    expect(result.state.selection?.unit, same(updatedAttacker));
    expect(result.state.selection?.tile?.col, 0);
    expect(result.state.selection?.tile?.row, 0);
    expect(result.state.selection?.tile?.resources, [ResourceType.wheat]);
    expect(mapTiles.tileAt(0, 0)?.resources, [
      ResourceType.oil,
      ResourceType.wheat,
    ]);
    expect(
      result.state.diplomacy.statusBetween('player_1', 'player_2'),
      DiplomaticRelationStatus.hostile,
    );
  });
}

const _context = GameCommandContext(
  actorPlayerId: 'player_1',
  combatSeedTurn: 4,
);

const _combatRuleset = CombatRuleset(
  varianceRange: 0,
  retreatThresholdPercent: 0,
  unitBaseStats: {
    GameUnitType.warrior: CombatStats(
      attack: 6,
      defense: 1,
      hp: 10,
      range: 1,
      mobility: 2,
    ),
  },
  terrainStatModifiers: {TerrainType.forest: CombatStats(defense: 2)},
);

GameUnit _unit(String id, String playerId, int col, int row) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: playerId,
    type: GameUnitType.warrior,
    col: col,
    row: row,
  );
}

FogOfWarState _visibleCombatFog() {
  final visible = {
    const HexCoordinate(col: 0, row: 0),
    const HexCoordinate(col: 1, row: 0),
  };
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(playerId: 'player_1', visibleHexes: visible),
      'player_2': PlayerFogOfWar(playerId: 'player_2', visibleHexes: visible),
    },
  );
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row += 1)
        for (var col = 0; col < 3; col += 1)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: [
              if (col == 1 && row == 0)
                TerrainType.forest
              else
                TerrainType.plains,
            ],
            resources: col == 0 && row == 0
                ? const [ResourceType.oil, ResourceType.wheat]
                : const [],
            height: 0,
          ),
    ],
  );
}
