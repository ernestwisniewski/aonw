import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_founding_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';
const _founderId = 'settler_1';
const _controlledHexes = [CityHex(col: 2, row: 1), CityHex(col: 1, row: 2)];

void main() {
  test('empty payload is rejected without consulting the local draft', () {
    final founder = _settler();
    final draft = CityFoundingDraft(
      unitId: _founderId,
      ownerPlayerId: _otherPlayerId,
      center: const CityHex(col: 0, row: 0),
      controlledHexes: const [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
    );
    final mapTiles = _mapTiles();
    final command = FoundCityCommand(_founderId, controlledHexes: const []);

    final localInput = GameState(
      activePlayerId: _playerId,
      units: [founder],
      interaction: GameInteractionState(cityFoundingDraft: draft),
    );
    final local = CityFoundingReducer.confirmCityFounding(
      localInput,
      command,
      mapTiles,
    );
    final persistentInput = PersistentGameState(
      units: [founder],
      runtimeState: GameRuntimeState(cityFoundingDraft: draft),
    );
    final authoritative = const PersistentCityFoundingResolver().foundCity(
      state: persistentInput,
      command: command,
      actorPlayerId: _playerId,
      mapTiles: mapTiles,
    );

    expect(local.events, isEmpty);
    expect(local.state, same(localInput));
    expect(authoritative.accepted, isFalse);
    expect(authoritative.reason, 'city_controlled_hexes_invalid');
    expect(authoritative.state, same(persistentInput));
  });

  test('accepted payload preserves unrelated interaction on both paths', () {
    final founder = _settler();
    final unrelatedDraft = _draft(
      unitId: 'settler_2',
      ownerPlayerId: _otherPlayerId,
    );
    const pending = PendingResearchSelection(ownerPlayerId: _otherPlayerId);
    final movePreview = _movePreview();
    final mapTiles = _mapTiles();
    final command = FoundCityCommand(
      _founderId,
      controlledHexes: _controlledHexes,
    );

    final local = CityFoundingReducer.confirmCityFounding(
      GameState(
        activePlayerId: _playerId,
        units: [founder],
        interaction: GameInteractionState(
          selection: GameSelection.unit(founder),
          movePreview: movePreview,
          cityFoundingDraft: unrelatedDraft,
          pendingAction: pending,
          moveCommandActive: true,
        ),
      ),
      command,
      mapTiles,
    );
    final persistentInput = PersistentGameState(
      units: [founder],
      runtimeState: GameRuntimeState(
        cityFoundingDraft: unrelatedDraft,
        pendingAction: pending,
      ),
    );
    final authoritative = const PersistentCityFoundingResolver().foundCity(
      state: persistentInput,
      command: command,
      actorPlayerId: _playerId,
      mapTiles: mapTiles,
    );

    expect(local.events, isEmpty);
    expect(local.state.cityFoundingDraft, same(unrelatedDraft));
    expect(local.state.pendingAction, same(pending));
    expect(local.state.movePreview, same(movePreview));
    expect(local.state.moveCommandActive, isTrue);
    expect(local.state.selection?.unit, same(local.state.units.single));
    expect(local.state.units.single, isNot(same(founder)));
    expect(authoritative.accepted, isTrue);
    expect(authoritative.state.runtimeState, persistentInput.runtimeState);
    expect(authoritative.state.runtimeState.cityFoundingDraft, unrelatedDraft);
    expect(authoritative.state.runtimeState.pendingAction, pending);
  });

  test('accepted payload structurally shares untouched local interaction', () {
    final unrelatedDraft = _draft(unitId: 'settler_2');
    final input = GameState(
      activePlayerId: _playerId,
      units: [_settler()],
      interaction: GameInteractionState(
        cityFoundingDraft: unrelatedDraft,
        pendingAction: const PendingResearchSelection(
          ownerPlayerId: _otherPlayerId,
        ),
        movePreview: _movePreview(),
        moveCommandActive: true,
      ),
    );

    final result = CityFoundingReducer.confirmCityFounding(
      input,
      FoundCityCommand(_founderId, controlledHexes: _controlledHexes),
      _mapTiles(),
    );

    expect(result.state.interaction, same(input.interaction));
  });

  test('early rejection preserves state identity on both paths', () {
    final founder = _settler(ownerPlayerId: _otherPlayerId);
    final draft = _draft(ownerPlayerId: _otherPlayerId);
    final selection = GameSelection.unit(founder);
    final movePreview = _movePreview();
    const pending = PendingResearchSelection(ownerPlayerId: _playerId);
    final mapTiles = _mapTiles();
    final command = FoundCityCommand(
      _founderId,
      controlledHexes: _controlledHexes,
    );

    final localInput = GameState(
      activePlayerId: _playerId,
      units: [founder],
      interaction: GameInteractionState(
        selection: selection,
        movePreview: movePreview,
        cityFoundingDraft: draft,
        pendingAction: pending,
        moveCommandActive: true,
      ),
    );
    final local = CityFoundingReducer.confirmCityFounding(
      localInput,
      command,
      mapTiles,
    );
    final persistentInput = PersistentGameState(
      units: [founder],
      runtimeState: GameRuntimeState(cityFoundingDraft: draft),
    );
    final authoritative = const PersistentCityFoundingResolver().foundCity(
      state: persistentInput,
      command: command,
      actorPlayerId: _playerId,
      mapTiles: mapTiles,
    );

    expect(local.events, isEmpty);
    expect(local.state, same(localInput));
    expect(authoritative.accepted, isFalse);
    expect(authoritative.reason, 'city_founder_not_controlled');
    expect(authoritative.state, same(persistentInput));
    expect(authoritative.state.runtimeState.cityFoundingDraft, same(draft));
  });

  test('actorless local flow accepts when active player id is empty', () {
    final founder = _settler();
    final result = CityFoundingReducer.confirmCityFounding(
      GameState(activePlayerId: '', units: [founder]),
      FoundCityCommand(_founderId, controlledHexes: _controlledHexes),
      _mapTiles(),
    );

    expect(result.state.units.single.cityFoundingJob, isNotNull);
  });

  test('only actorless flow is blocked by inactive local turn state', () {
    final founder = _settler();
    final state = GameState(
      activePlayerId: _playerId,
      activePlayerCanAct: false,
      units: [founder],
    );
    final command = FoundCityCommand(
      _founderId,
      controlledHexes: _controlledHexes,
    );

    final actorless = CityFoundingReducer.confirmCityFounding(
      state,
      command,
      _mapTiles(),
    );
    final explicitActor = CityFoundingReducer.confirmCityFounding(
      state,
      command,
      _mapTiles(),
      context: const GameCommandContext(actorPlayerId: _playerId),
    );

    expect(actorless.state, same(state));
    expect(explicitActor.state.units.single.cityFoundingJob, isNotNull);
  });
}

GameUnit _settler({String ownerPlayerId = _playerId}) {
  return GameUnit.produced(
    id: _founderId,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.settler,
    col: 1,
    row: 1,
  );
}

CityFoundingDraft _draft({
  String unitId = _founderId,
  String ownerPlayerId = _playerId,
}) {
  return CityFoundingDraft(
    unitId: unitId,
    ownerPlayerId: ownerPlayerId,
    center: const CityHex(col: 1, row: 1),
    controlledHexes: _controlledHexes,
  );
}

UnitMovementPlan _movePreview() {
  return UnitMovementPlan(
    unitId: _founderId,
    targetCol: 2,
    targetRow: 1,
    totalCost: 1,
    availableMovementPoints: 3,
    steps: const [
      UnitMovementStep(col: 1, row: 1, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 2, row: 1, enterCost: 1, cumulativeCost: 1),
    ],
  );
}

MapTileLookup _mapTiles() {
  return WorldMapReadView(
    WorldMap(
      cols: 4,
      rows: 4,
      tiles: [
        for (var row = 0; row < 4; row++)
          for (var col = 0; col < 4; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}
