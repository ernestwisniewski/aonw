import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/runtime/game_runtime_state.dart';
import 'package:aonw_core/game/domain/stability/persistent_stability_processor.dart';
import 'package:aonw_core/game/domain/stability/stability_band.dart';
import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

MapData _singleTileMap() => MapData(
  cols: 1,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.grassland],
      resources: [],
      height: 0,
    ),
  ],
);

void main() {
  test('advances war-weariness only for the acting players', () {
    const state = PersistentGameState(playerWarWeariness: {'a': 5, 'b': 5});

    final result = PersistentStabilityProcessor.advanceForPlayers(
      state: state,
      playerIds: const ['a'],
      mapData: _singleTileMap(),
    );

    expect(result.state.playerWarWeariness['a'], 4);
    expect(result.state.playerWarWeariness['b'], 5);
  });

  test('failed city attacks still accrue war weariness for the attacker', () {
    final state = PersistentGameState(
      runtimeState: GameRuntimeState(
        diplomacy: DiplomacyState.empty.setStatus(
          'a',
          'b',
          DiplomaticRelationStatus.war,
        ),
      ),
    );

    final result = PersistentStabilityProcessor.advanceForPlayers(
      state: state,
      playerIds: const ['a'],
      mapData: _singleTileMap(),
      turnEvents: const [
        CityAttackedEvent(
          attackerUnitId: 'u1',
          attackerOwnerPlayerId: 'a',
          cityId: 'city_b',
          cityOwnerPlayerId: 'b',
        ),
        CityAttackedEvent(
          attackerUnitId: 'u2',
          attackerOwnerPlayerId: 'a',
          cityId: 'city_b',
          cityOwnerPlayerId: 'b',
        ),
        CityAttackedEvent(
          attackerUnitId: 'u3',
          attackerOwnerPlayerId: 'a',
          cityId: 'city_b',
          cityOwnerPlayerId: 'b',
        ),
      ],
    );

    expect(result.state.playerWarWeariness['a'], 2);
  });

  test('a truce signed this turn accelerates war-weariness decay', () {
    final state = PersistentGameState(
      playerWarWeariness: const {'a': 5},
      runtimeState: GameRuntimeState(
        diplomacy: DiplomacyState.empty.setStatus(
          'a',
          'b',
          DiplomaticRelationStatus.truce,
          turn: 7,
          reason: DiplomaticRelationChangeReason.proposalAccepted,
        ),
      ),
    );

    final signedThisTurn = PersistentStabilityProcessor.advanceForPlayers(
      state: state,
      playerIds: const ['a'],
      mapData: _singleTileMap(),
      turn: 7,
    );
    final signedEarlier = PersistentStabilityProcessor.advanceForPlayers(
      state: state,
      playerIds: const ['a'],
      mapData: _singleTileMap(),
      turn: 8,
    );

    expect(signedThisTurn.state.playerWarWeariness['a'], 3);
    expect(signedEarlier.state.playerWarWeariness['a'], 4);
  });

  test('caches a standing-adjusted net so a map-control leader pays more', () {
    const state = PersistentGameState(
      playerGold: {'b': 0},
      cities: [
        GameCity(
          id: 'city-a',
          ownerPlayerId: 'a',
          name: 'A',
          center: CityHex(col: 0, row: 0),
        ),
      ],
    );

    final result = PersistentStabilityProcessor.advanceForPlayers(
      state: state,
      playerIds: const ['a', 'b'],
      mapData: _singleTileMap(),
    );

    final rawNet = result.breakdownsByPlayerId['a']!.net;
    final cachedNet = result.state.playerStabilityNet['a']!;
    expect(cachedNet, lessThan(rawNet));
  });

  test('emits a band change only when an existing snapshot crosses a band', () {
    const state = PersistentGameState(playerStabilityNet: {'a': -4});

    final result = PersistentStabilityProcessor.advanceForPlayers(
      state: state,
      playerIds: const ['a'],
      mapData: _singleTileMap(),
    );

    expect(
      result.events,
      contains(
        isA<StabilityBandChangedEvent>()
            .having((event) => event.playerId, 'playerId', 'a')
            .having(
              (event) => event.previousBand,
              'previousBand',
              StabilityBand.unrest,
            )
            .having((event) => event.newBand, 'newBand', StabilityBand.content),
      ),
    );

    final initial = PersistentStabilityProcessor.advanceForPlayers(
      state: const PersistentGameState(),
      playerIds: const ['a'],
      mapData: _singleTileMap(),
    );
    expect(initial.events, isEmpty);
  });
}
