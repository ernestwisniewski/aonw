part of 'city_founding_command_resolver_parity_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';
const _founderId = 'settler_1';
const _controlledHexes = [CityHex(col: 2, row: 1), CityHex(col: 1, row: 2)];

typedef _FoundingStates = ({
  PersistentGameState persistent,
  DomainState domain,
  PersistedInteractionState interaction,
});

typedef _FoundingResults = ({
  CityFoundingCommandResult kernel,
  PersistentCityFoundingResult persistent,
  DomainCityFoundingResult domain,
});

_FoundingStates _parityStates({required CityFoundingDraft cityFoundingDraft}) {
  final units = [
    _paritySentinel('before'),
    _parityFounder(),
    _paritySentinel('after'),
  ];
  final cities = [
    GameCity.snapshot(
      id: 'sentinel_city',
      ownerPlayerId: _otherPlayerId,
      name: 'Sentinel',
      center: const CityHex(col: 6, row: 6),
    ),
  ];
  final interaction = PersistedInteractionState(
    cityFoundingDraft: cityFoundingDraft,
    pendingAction: const PendingResearchSelection(
      ownerPlayerId: _otherPlayerId,
    ),
  );
  final runtime = GameRuntimeState.snapshot(
    cityFoundingDraft: interaction.cityFoundingDraft,
    pendingAction: interaction.pendingAction,
    submittedPlayerIds: const {_otherPlayerId},
    timeoutStreaksByPlayerId: const {_otherPlayerId: 2},
    mapObjectiveHoldStatesByObjectiveId: const {
      'objective_1': MapObjectiveHoldState(
        objectiveId: 'objective_1',
        playerId: _playerId,
        holdTurns: 2,
      ),
    },
    turnStartedAt: DateTime.utc(2026, 7, 18),
  );
  return (
    persistent: PersistentGameState.snapshot(
      playerColors: const {_playerId: 1, _otherPlayerId: 2},
      playerCountries: const {
        _playerId: PlayerCountry.poland,
        _otherPlayerId: PlayerCountry.france,
      },
      playerGold: const {_playerId: 17, _otherPlayerId: 11},
      units: units,
      cities: cities,
      runtimeState: runtime,
    ),
    domain: DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: const [
        Player(
          id: _playerId,
          name: 'One',
          colorValue: 1,
          country: PlayerCountry.poland,
        ),
        Player(
          id: _otherPlayerId,
          name: 'Two',
          colorValue: 2,
          country: PlayerCountry.france,
        ),
      ],
      playerGold: const {_playerId: 17, _otherPlayerId: 11},
      units: units,
      cities: cities,
      mapObjectiveHoldStatesByObjectiveId:
          runtime.mapObjectiveHoldStatesByObjectiveId,
    ),
    interaction: interaction,
  );
}

_FoundingResults _resolveParity(
  _FoundingStates states, {
  String actorPlayerId = _playerId,
}) {
  final command = FoundCityCommand(
    _founderId,
    controlledHexes: _controlledHexes,
  );
  final mapTiles = _parityMap();
  return (
    kernel: CityFoundingCommandResolver.foundCity(
      units: states.domain.units,
      cities: states.domain.cities,
      cityFoundingDraft: states.interaction.cityFoundingDraft,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    ),
    persistent: const PersistentCityFoundingResolver().foundCity(
      state: states.persistent,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    ),
    domain: const DomainCityFoundingResolver().foundCity(
      state: states.domain,
      interaction: states.interaction,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    ),
  );
}

void _expectAcceptedParity(_FoundingStates before, _FoundingResults results) {
  expect(results.kernel.accepted, isTrue);
  expect(results.persistent.accepted, isTrue);
  expect(results.domain.accepted, isTrue);
  expect(results.kernel.reason, isNull);
  expect(results.persistent.reason, isNull);
  expect(results.domain.reason, isNull);
  expect(results.persistent.events, isEmpty);
  expect(results.persistent.state.units, results.kernel.units);
  expect(results.domain.state.units, results.kernel.units);
  expect(
    results.persistent.state.runtimeState.cityFoundingDraft,
    results.domain.interaction.cityFoundingDraft,
  );
  expect(
    identical(results.persistent.state.cities, before.persistent.cities),
    isTrue,
  );
  expect(identical(results.domain.state.cities, before.domain.cities), isTrue);
  expect(
    identical(
      results.persistent.state.units.first,
      before.persistent.units.first,
    ),
    isTrue,
  );
  expect(
    identical(results.domain.state.units.last, before.domain.units.last),
    isTrue,
  );
  expect(results.kernel.units[1].movementPoints, 0);
  expect(results.kernel.units[1].queuedPath, isNull);
  expect(
    results.kernel.units[1].cityFoundingJob,
    CityFoundingJob(
      center: const CityHex(col: 1, row: 1),
      controlledHexes: _controlledHexes,
      remainingTurns: 1,
      totalTurns: 1,
    ),
  );
  expect(
    results.persistent.state,
    before.persistent.copyWith(
      units: results.persistent.state.units,
      runtimeState: before.persistent.runtimeState.copyWith(
        cityFoundingDraft:
            results.persistent.state.runtimeState.cityFoundingDraft,
      ),
    ),
  );
  expect(
    results.domain.state,
    before.domain.copyWith(units: results.domain.state.units),
  );
}

GameUnit _parityFounder() {
  return GameUnit(
    id: _founderId,
    ownerPlayerId: _playerId,
    type: GameUnitType.settler,
    name: 'Founder',
    col: 1,
    row: 1,
    movementPoints: 3,
    queuedPath: QueuedMovePath(
      targetCol: 2,
      targetRow: 1,
      steps: const [
        UnitMovementStep(col: 2, row: 1, enterCost: 1, cumulativeCost: 1),
      ],
    ),
  );
}

GameUnit _paritySentinel(String id) {
  return GameUnit(
    id: id,
    ownerPlayerId: _otherPlayerId,
    type: GameUnitType.scout,
    name: id,
    col: 7,
    row: 7,
    movementPoints: 1,
  );
}

CityFoundingDraft _parityDraft(String unitId) {
  return CityFoundingDraft(
    unitId: unitId,
    ownerPlayerId: _playerId,
    center: const CityHex(col: 1, row: 1),
    controlledHexes: _controlledHexes,
  );
}

MapTileLookup _parityMap() {
  return WorldMapReadView(
    WorldMap(
      cols: 8,
      rows: 8,
      tiles: [
        for (var row = 0; row < 8; row++)
          for (var col = 0; col < 8; col++)
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
