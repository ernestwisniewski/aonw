import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('StabilityTurnProcessor parity', () {
    test('matches the persistent adapter for a mixed turn', () {
      final state = _state();
      final persistent = PersistentStabilityProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['c', 'a', 'a', ''],
        mapData: _map,
        turnEvents: _turnEvents,
        turn: 9,
      );
      final neutral = StabilityTurnProcessor.advanceForPlayers(
        knownPlayerIds: state.knownPlayerIds,
        playerIds: const ['c', 'a', 'a', ''],
        playerWarWearinessByPlayerId: state.playerWarWeariness,
        playerStabilityNetByPlayerId: state.playerStabilityNet,
        cities: state.cities,
        artifacts: state.artifacts,
        research: state.research,
        wonderRegistry: state.wonderRegistry,
        diplomacy: state.runtimeState.diplomacy,
        mapData: _map,
        turnEvents: _turnEvents,
        turn: 9,
      );

      expect(
        persistent.state.playerWarWeariness,
        neutral.warWearinessByPlayerId,
      );
      expect(
        persistent.state.playerStabilityNet,
        neutral.stabilityNetByPlayerId,
      );
      expect(persistent.inputsByPlayerId, neutral.inputsByPlayerId);
      expect(persistent.breakdownsByPlayerId, neutral.breakdownsByPlayerId);
      expect(_eventJson(persistent.events), _eventJson(neutral.events));
      expect(neutral.inputsByPlayerId.keys, ['a', 'b', 'c']);
      expect(neutral.warWearinessByPlayerId['b'], 6);
      expect(neutral.warWearinessByPlayerId['a'], 7);
      expect(neutral.warWearinessByPlayerId['c'], 1);
      expect(neutral.inputsByPlayerId['a']?.wonderSources, 4);
    });

    test('orders band events and owns all result collections', () {
      final result = StabilityTurnProcessor.advanceForPlayers(
        knownPlayerIds: const ['b', 'a'],
        playerIds: const [],
        playerWarWearinessByPlayerId: const {},
        playerStabilityNetByPlayerId: const {'b': -4, 'a': -4},
        cities: const [],
        artifacts: const [],
        research: ResearchState.empty,
        wonderRegistry: WonderRegistry.empty,
        diplomacy: DiplomacyState.empty,
        mapData: _map,
      );

      expect(
        result.events.whereType<StabilityBandChangedEvent>().map(
          (event) => event.playerId,
        ),
        ['a', 'b'],
      );
      expect(
        () => result.warWearinessByPlayerId['a'] = 1,
        throwsUnsupportedError,
      );
      expect(
        () => result.stabilityNetByPlayerId['a'] = 1,
        throwsUnsupportedError,
      );
      expect(() => result.inputsByPlayerId.clear(), throwsUnsupportedError);
      expect(() => result.breakdownsByPlayerId.clear(), throwsUnsupportedError);
      expect(
        () => result.events.add(const TurnEndedEvent(playerId: 'a')),
        throwsUnsupportedError,
      );
    });
  });
}

PersistentGameState _state() {
  var diplomacy = DiplomacyState.empty.setStatus(
    'a',
    'b',
    DiplomaticRelationStatus.war,
  );
  diplomacy = diplomacy.setStatus(
    'b',
    'c',
    DiplomaticRelationStatus.truce,
    turn: 9,
    reason: DiplomaticRelationChangeReason.proposalAccepted,
  );
  return PersistentGameState.snapshot(
    playerColors: const {'c': 3, 'b': 2, 'a': 1},
    playerWarWeariness: const {'a': 5, 'b': 6, 'c': 3},
    playerStabilityNet: const {'a': 100, 'b': -100, 'c': -100},
    cities: const [
      GameCity(
        id: 'city_a',
        ownerPlayerId: 'a',
        name: 'A',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
        buildings: {CityBuildingType.townHall},
        wonders: {WonderType.grandCathedral},
      ),
      GameCity(
        id: 'city_b',
        ownerPlayerId: 'b',
        foundingOwnerPlayerId: 'a',
        name: 'B',
        center: CityHex(col: 2, row: 0),
      ),
    ],
    artifacts: const [
      WorldArtifact(
        id: 'artifact_a',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.stored(cityId: 'city_a'),
      ),
    ],
    research: ResearchState(
      players: {
        'a': PlayerResearchState(
          unlockedTechnologyIds: {TechnologyId.civilService},
        ),
      },
    ),
    wonderRegistry: WonderRegistry(
      completedBy: {WonderType.grandCathedral: 'a'},
    ),
    runtimeState: GameRuntimeState.snapshot(diplomacy: diplomacy),
  );
}

List<Map<String, dynamic>> _eventJson(Iterable<GameEvent> events) {
  return events.map(GameEventSerializer.toJson).toList();
}

const _turnEvents = <GameEvent>[
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
  DiplomaticProposalRespondedEvent(
    proposalId: 'truce_bc',
    fromPlayerId: 'b',
    toPlayerId: 'c',
    kind: DiplomaticProposalKind.truce,
    accepted: true,
  ),
];

final _map = MapData(
  cols: 3,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.grassland],
      resources: [ResourceType.silk],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 2,
      row: 0,
      terrains: [TerrainType.grassland],
      resources: [],
      height: 0,
    ),
  ],
);
