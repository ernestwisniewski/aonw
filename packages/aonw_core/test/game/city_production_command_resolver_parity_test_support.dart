part of 'city_production_command_resolver_parity_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

typedef _ProductionStates = ({
  PersistentGameState persistent,
  DomainState domain,
});

typedef _ProductionResults = ({
  PersistentCityProductionResult persistent,
  DomainCityProductionResult domain,
});

_ProductionStates _productionStates({
  required GameCity primary,
  ResearchState research = ResearchState.empty,
  WonderRegistry wonderRegistry = WonderRegistry.empty,
}) {
  final cities = [
    primary,
    _parityProductionCity(id: 'city_2', ownerPlayerId: _otherPlayerId),
  ];
  return (
    persistent: PersistentGameState.snapshot(
      playerColors: const {_playerId: 1, _otherPlayerId: 2},
      playerCountries: const {
        _playerId: PlayerCountry.poland,
        _otherPlayerId: PlayerCountry.france,
      },
      playerGold: const {_playerId: 17, _otherPlayerId: 11},
      cities: cities,
      research: research,
      wonderRegistry: wonderRegistry,
      runtimeState: GameRuntimeState.snapshot(
        submittedPlayerIds: const {_otherPlayerId},
        timeoutStreaksByPlayerId: const {_otherPlayerId: 2},
        turnStartedAt: DateTime.utc(2026, 7, 18),
      ),
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
      cities: cities,
      research: research,
      wonderRegistry: wonderRegistry,
    ),
  );
}

_ProductionResults _startBoth(
  _ProductionStates states, {
  String actorPlayerId = _playerId,
}) {
  const command = StartCityProjectCommand('city_1', CityProjectType.research);
  return (
    persistent: const PersistentCityProductionResolver().startCityProject(
      state: states.persistent,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: CityRulesets.standard,
      paceBalance: PaceBalance.standard60,
    ),
    domain: const DomainCityProductionResolver().startCityProject(
      state: states.domain,
      command: command,
      actorPlayerId: actorPlayerId,
      cityRuleset: CityRulesets.standard,
      paceBalance: PaceBalance.standard60,
    ),
  );
}

_ProductionResults _startBuildingBoth(
  _ProductionStates states, {
  String actorPlayerId = _playerId,
}) {
  const command = StartBuildingCommand('city_1', CityBuildingType.workshop);
  final mapTiles = _parityProductionMapTiles();
  return (
    persistent: const PersistentCityProductionResolver().startBuilding(
      state: states.persistent,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: CityRulesets.standard,
      technologyRuleset: TechnologyRulesets.standard,
      paceBalance: PaceBalance.standard60,
    ),
    domain: const DomainCityProductionResolver().startBuilding(
      state: states.domain,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: CityRulesets.standard,
      technologyRuleset: TechnologyRulesets.standard,
      paceBalance: PaceBalance.standard60,
    ),
  );
}

_ProductionResults _startWonderBoth(
  _ProductionStates states, {
  String actorPlayerId = _playerId,
  MapTileLookup? mapTiles,
  WonderRuleset wonderRuleset = WonderRuleset.standard,
  PaceBalance paceBalance = PaceBalance.standard60,
}) {
  const command = StartWonderCommand('city_1', WonderType.greatLibrary);
  final resolvedMapTiles = mapTiles ?? _parityProductionMapTiles();
  return (
    persistent: const PersistentCityProductionResolver().startWonder(
      state: states.persistent,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: resolvedMapTiles,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
    ),
    domain: const DomainCityProductionResolver().startWonder(
      state: states.domain,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: resolvedMapTiles,
      wonderRuleset: wonderRuleset,
      paceBalance: paceBalance,
    ),
  );
}

_ProductionResults _specializeBoth(
  _ProductionStates states, {
  String actorPlayerId = _playerId,
}) {
  const command = SetCitySpecializationCommand(
    'city_1',
    CitySpecializationType.industry,
  );
  return (
    persistent: const PersistentCityProductionResolver().setCitySpecialization(
      state: states.persistent,
      command: command,
      actorPlayerId: actorPlayerId,
    ),
    domain: const DomainCityProductionResolver().setCitySpecialization(
      state: states.domain,
      command: command,
      actorPlayerId: actorPlayerId,
    ),
  );
}

ResearchState _paritySpecializationResearch() {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(
        unlockedTechnologyIds: const {
          TechnologyId.agriculture,
          TechnologyId.specialization,
        },
        activeTechnologyId: TechnologyId.craftsmanship,
        progressByTechnologyId: const {TechnologyId.craftsmanship: 13},
        scienceOverflow: 5,
      ),
      _otherPlayerId: PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.agriculture},
        scienceOverflow: 2,
      ),
    },
  );
}

ResearchState _parityBuildingResearch() {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(
        unlockedTechnologyIds: const {
          TechnologyId.agriculture,
          TechnologyId.craftsmanship,
        },
        activeTechnologyId: TechnologyId.trade,
        progressByTechnologyId: const {TechnologyId.trade: 7},
        scienceOverflow: 3,
      ),
      _otherPlayerId: PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.agriculture},
        scienceOverflow: 2,
      ),
    },
  );
}

ResearchState _parityWonderResearch() {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(
        unlockedTechnologyIds: const {
          TechnologyId.agriculture,
          TechnologyId.writing,
        },
        activeTechnologyId: TechnologyId.trade,
        progressByTechnologyId: const {TechnologyId.trade: 7},
        scienceOverflow: 3,
      ),
      _otherPlayerId: PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.agriculture},
        scienceOverflow: 2,
      ),
    },
  );
}

MapTileLookup _parityProductionMapTiles({
  TerrainType hostTerrain = TerrainType.grassland,
}) {
  return WorldMapReadView(
    WorldMap(
      cols: 5,
      rows: 5,
      tiles: [
        for (var row = 0; row < 5; row++)
          for (var col = 0; col < 5; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: col == 1 && row == 1
                  ? [hostTerrain]
                  : const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}

const _parityCustomWonderRuleset = WonderRuleset(
  wonders: {
    WonderType.greatLibrary: WonderDefinition(
      type: WonderType.greatLibrary,
      productionCost: 20,
      unlockTech: TechnologyId.writing,
      requirements: [
        WonderHostTerrainRequirement({TerrainType.desert}),
      ],
    ),
  },
);

void _expectAcceptedProductionParity(
  _ProductionStates before,
  _ProductionResults results,
) {
  expect(results.persistent.accepted, isTrue);
  expect(results.domain.accepted, isTrue);
  expect(results.persistent.reason, isNull);
  expect(results.domain.reason, isNull);
  expect(results.persistent.events, isEmpty);
  expect(results.persistent.state.cities, results.domain.state.cities);
  expect(identical(results.persistent.state, before.persistent), isFalse);
  expect(identical(results.domain.state, before.domain), isFalse);
  expect(
    identical(
      results.persistent.state.runtimeState,
      before.persistent.runtimeState,
    ),
    isTrue,
  );
  expect(
    identical(
      results.persistent.state.cities.last,
      before.persistent.cities.last,
    ),
    isTrue,
  );
  expect(
    identical(results.domain.state.cities.last, before.domain.cities.last),
    isTrue,
  );
}

void _expectRejectedProductionParity(
  _ProductionStates before,
  _ProductionResults results, {
  required String reason,
}) {
  expect(results.persistent.accepted, isFalse);
  expect(results.domain.accepted, isFalse);
  expect(results.persistent.reason, reason);
  expect(results.domain.reason, reason);
  expect(results.persistent.events, isEmpty);
  expect(identical(results.persistent.state, before.persistent), isTrue);
  expect(identical(results.domain.state, before.domain), isTrue);
}

GameCity _parityProductionCity({
  String id = 'city_1',
  String ownerPlayerId = _playerId,
  CityProductionQueue? productionQueue,
  int productionOverflow = 0,
  Set<CityBuildingType> buildings = const {},
  CitySpecializationType? specialization,
}) {
  return GameCity.snapshot(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: id == 'city_1'
        ? const CityHex(col: 1, row: 1)
        : const CityHex(col: 3, row: 3),
    productionQueue: productionQueue,
    productionOverflow: productionOverflow,
    buildings: buildings,
    specialization: specialization,
  );
}
