import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:test/test.dart';

void main() {
  test(
    'orders economy, diplomacy, and victory while persisting both holds',
    _characterizesVictoryTail,
  );
  test('returns a full movement delta when no units move', _keepsNoOpDelta);
  test('rejects turn players outside canonical participants', () {
    expect(
      () => CanonicalTurnPipelineRequest.simultaneousFinalize(
        snapshot: _victoryInput(),
        playerIds: const ['outsider'],
        savedAt: _finalizedAt,
        mapView: _mapData(),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'playerIds')
            .having((error) => error.invalidValue, 'invalidValue', const [
              'outsider',
            ]),
      ),
    );
  });
  test('rejects skipped players outside the finalized scope', () {
    expect(
      () => CanonicalTurnPipelineRequest.simultaneousFinalize(
        snapshot: _victoryInput(),
        playerIds: const ['p1'],
        skippedPlayerIds: const ['p2'],
        savedAt: _finalizedAt,
        mapView: _mapData(),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'skippedPlayerIds')
            .having((error) => error.invalidValue, 'invalidValue', const [
              'p2',
            ]),
      ),
    );
  });
}

void _characterizesVictoryTail() {
  final result = CanonicalTurnPipeline.simultaneousFinalize(
    CanonicalTurnPipelineRequest.simultaneousFinalize(
      snapshot: _victoryInput(),
      playerIds: const ['p1', 'p2'],
      savedAt: _finalizedAt,
      mapView: _mapData(),
    ),
  );

  expect(result.snapshot.domain.dominationHoldTurnsByPlayerId, {'p1': 1});
  expect(result.snapshot.domain.culturalVictoryHoldTurnsByPlayerId, {'p1': 3});
  expect(result.events.map((event) => event.runtimeType), [
    AllPlayersSubmittedEvent,
    ResearchPointsGainedEvent,
    ResearchPointsGainedEvent,
    DiplomaticProposalExpiredEvent,
    DominationThresholdReachedEvent,
    TurnEndedEvent,
    TurnEndedEvent,
  ]);
  expect(
    result.events.whereType<DominationThresholdReachedEvent>().single.playerId,
    'p1',
  );
  expect(result.snapshot.domain.diplomacy.pendingProposals, isEmpty);
}

void _keepsNoOpDelta() {
  final result = CanonicalTurnPipeline.simultaneousFinalize(
    CanonicalTurnPipelineRequest.simultaneousFinalize(
      snapshot: _adapter.toCanonical(
        save: _save(),
        state: const PersistentGameState(),
        eventLogOffset: 101,
      ),
      playerIds: const ['p1', 'p2'],
      savedAt: _finalizedAt,
      mapView: _mapData(),
    ),
  );

  expect(result.movementDelta, isNotNull);
  expect(result.movementDelta!.beforeUnits, isEmpty);
  expect(result.movementDelta!.afterUnits, isEmpty);
}

CanonicalGameSnapshot _victoryInput() {
  final victory = VictoryRules.standard.copyWith(
    dominationControlPercent: 60,
    dominationHoldTurns: 3,
    culturalRequiredArtifacts: 2,
  );
  return _adapter.toCanonical(
    save: _save().copyWith(
      matchRules: MatchRules.standard.copyWith(victory: victory),
    ),
    state: PersistentGameState.snapshot(
      cities: const [
        GameCity(
          id: 'city_p1',
          ownerPlayerId: 'p1',
          name: 'City one',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 1, row: 0)],
        ),
        GameCity(
          id: 'city_p2',
          ownerPlayerId: 'p2',
          name: 'City two',
          center: CityHex(col: 2, row: 0),
        ),
      ],
      artifacts: const [
        WorldArtifact(
          id: 'artifact_1',
          type: WorldArtifactType.ancientImperialCrown,
          location: WorldArtifactLocation.stored(cityId: 'city_p1'),
        ),
        WorldArtifact(
          id: 'artifact_2',
          type: WorldArtifactType.astronomersTablets,
          location: WorldArtifactLocation.stored(cityId: 'city_p1'),
        ),
      ],
      runtimeState: GameRuntimeState.snapshot(
        diplomacy: DiplomacyState.empty.addProposal(
          const DiplomaticProposal(
            id: 'proposal_1',
            fromPlayerId: 'p1',
            toPlayerId: 'p2',
            kind: DiplomaticProposalKind.friendship,
            createdTurn: 1,
            expiresOnTurn: 2,
          ),
        ),
        culturalVictoryHoldTurnsByPlayerId: const {'p1': 2},
      ),
    ),
    eventLogOffset: 97,
  );
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    schemaVersion: gameSaveCurrentSchemaVersion,
    name: 'Canonical tail fixture',
    mapName: 'turn_map',
    mapSource: MapSource.saved,
    turn: 1,
    playerStates: const {
      'p1': PlayerTurnState.finished,
      'p2': PlayerTurnState.finished,
    },
    savedAt: DateTime.utc(2026, 7, 17, 9),
    camera: CameraState.zero,
    players: const [
      Player(id: 'p1', name: 'Player one', colorValue: 0xFF000001),
      Player(id: 'p2', name: 'Player two', colorValue: 0xFF000002),
    ],
    gameMode: GameMode.multiplayer,
  );
}

MapData _mapData() {
  return MapData(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 1,
        ),
    ],
  );
}

const _adapter = LegacyGameSnapshotAdapter();
final _finalizedAt = DateTime.utc(2026, 7, 17, 10);
