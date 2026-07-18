import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/unit/unit_attachment_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detaches a troop and recomputes fog through canonical map lookup', () {
    final commander = GameUnit(
      id: 'commander_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.commander,
      name: GameUnitType.commander.defaultNameToken,
      col: 1,
      row: 1,
      army: const [ArmyTroop(type: TroopType.warrior, count: 2)],
    );
    final enemy = GameUnit(
      id: 'scout_2',
      ownerPlayerId: 'player_2',
      type: GameUnitType.scout,
      name: GameUnitType.scout.defaultNameToken,
      col: 4,
      row: 1,
    );
    final movePreview = UnitMovementPlan(
      unitId: commander.id,
      targetCol: 2,
      targetRow: 1,
      totalCost: 1,
      availableMovementPoints: commander.movementPoints,
      steps: const [
        UnitMovementStep(col: 2, row: 1, enterCost: 1, cumulativeCost: 1),
      ],
    );
    final cityFoundingDraft = CityFoundingDraft(
      unitId: commander.id,
      ownerPlayerId: commander.ownerPlayerId,
      center: const CityHex(col: 1, row: 1),
    );
    const pendingAction = PendingResearchSelection(ownerPlayerId: 'player_1');
    final state = GameState(
      activePlayerId: 'player_1',
      units: [commander, enemy],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 1, row: 1),
              const HexCoordinate(col: 2, row: 1),
            },
          ),
        },
      ),
      interaction: GameInteractionState(
        selection: GameSelection.unit(commander),
        movePreview: movePreview,
        cityFoundingDraft: cityFoundingDraft,
        pendingAction: pendingAction,
        moveCommandActive: true,
      ),
    );
    final MapTileLookup mapTiles = WorldMapReadView(_worldMap());

    final result = UnitAttachmentReducer.detachTroop(
      state,
      const DetachTroopCommand('commander_1', TroopType.warrior),
      mapTiles,
    );

    final updatedCommander = result.state.unitById('commander_1')!;
    final detached = result.state.unitById('commander_1_warrior_1')!;
    expect(updatedCommander.troopCount(TroopType.warrior), 1);
    expect((detached.col, detached.row), (2, 1));
    expect(result.state.selection?.unit, same(updatedCommander));
    expect(result.state.selection?.tile?.col, 1);
    expect(result.state.selection?.tile?.row, 1);
    expect(result.state.movePreview, isNull);
    expect(result.state.cityFoundingDraft, isNull);
    expect(result.state.moveCommandActive, isFalse);
    expect(result.state.pendingAction, same(pendingAction));
    expect(
      result.state.fogOfWar.isVisible(
        'player_1',
        const HexCoordinate(col: 4, row: 1),
      ),
      isTrue,
    );
    expect(
      result.state.runtimeState.diplomacy.hasContact('player_1', 'player_2'),
      isTrue,
    );
  });

  test('rejects detachment when the source unit is outside the map', () {
    final commander = GameUnit(
      id: 'commander_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.commander,
      name: GameUnitType.commander.defaultNameToken,
      col: 5,
      row: 1,
      army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
    );
    final state = GameState(activePlayerId: '', units: [commander]);
    final MapTileLookup mapTiles = WorldMapReadView(_worldMap());

    final result = UnitAttachmentReducer.detachTroop(
      state,
      const DetachTroopCommand('commander_1', TroopType.warrior),
      mapTiles,
    );

    expect(result.state, same(state));
  });
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 5,
    rows: 4,
    tiles: [
      for (var row = 0; row < 4; row += 1)
        for (var col = 0; col < 5; col += 1)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
