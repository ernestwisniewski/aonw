part of '../persistent_resource_trade_resolver_characterization_test.dart';

const _importerId = 'player_1';
const _exporterId = 'player_2';
const _resolver = PersistentResourceTradeResolver();

const _requestedHorsesTrade = ResourceTradeAgreement(
  id: 'requested_horses_trade',
  exporterPlayerId: _exporterId,
  importerPlayerId: _importerId,
  resource: ResourceType.horses,
  goldPerTurn: 2,
  remainingTurns: 4,
);

const _offeredIronTrade = ResourceTradeAgreement(
  id: 'offered_iron_trade',
  exporterPlayerId: _importerId,
  importerPlayerId: _exporterId,
  resource: ResourceType.iron,
  goldPerTurn: 0,
  remainingTurns: 4,
);

const _unrelatedTrade = ResourceTradeAgreement(
  id: 'unrelated_trade',
  exporterPlayerId: 'player_3',
  importerPlayerId: 'player_4',
  resource: ResourceType.coal,
  goldPerTurn: 7,
  remainingTurns: 9,
);

const _expiredRequestedHorsesTrade = ResourceTradeAgreement(
  id: 'expired_requested_horses_trade',
  exporterPlayerId: _exporterId,
  importerPlayerId: _importerId,
  resource: ResourceType.horses,
  goldPerTurn: 3,
  remainingTurns: 0,
);

const _otherImporterIronTrade = ResourceTradeAgreement(
  id: 'other_importer_iron_trade',
  exporterPlayerId: _importerId,
  importerPlayerId: 'player_3',
  resource: ResourceType.iron,
  goldPerTurn: 0,
  remainingTurns: 4,
);

const _otherImporterHorsesTrade = ResourceTradeAgreement(
  id: 'other_importer_horses_trade',
  exporterPlayerId: _exporterId,
  importerPlayerId: 'player_3',
  resource: ResourceType.horses,
  goldPerTurn: 2,
  remainingTurns: 4,
);

PersistentGameState _tradeState({
  int importerGold = 10,
  bool includeImporterGold = true,
  bool exporterRevealsHorses = true,
  bool atWar = false,
  List<ResourceTradeAgreement> agreements = const [],
}) {
  final diplomacy = atWar
      ? DiplomacyState.empty.setStatus(
          _importerId,
          _exporterId,
          DiplomaticRelationStatus.war,
        )
      : DiplomacyState.empty.addContact(_importerId, _exporterId);
  return PersistentGameState.snapshot(
    playerColors: const {
      _importerId: 0xFF112233,
      _exporterId: 0xFF445566,
      'sentinel': 0xFF778899,
    },
    playerCountries: const {
      _importerId: PlayerCountry.poland,
      _exporterId: PlayerCountry.japan,
      'sentinel': PlayerCountry.egypt,
    },
    playerGold: {
      if (includeImporterGold) _importerId: importerGold,
      _exporterId: 23,
      'sentinel': 97,
    },
    playerWarWeariness: const {_importerId: 2, _exporterId: 3, 'sentinel': 5},
    playerStabilityNet: const {_importerId: 4, _exporterId: 6, 'sentinel': 8},
    cities: const [
      GameCity(
        id: 'importer_city',
        ownerPlayerId: _importerId,
        name: 'Iron City',
        center: CityHex(col: 0, row: 0),
      ),
      GameCity(
        id: 'exporter_city',
        ownerPlayerId: _exporterId,
        name: 'Horse City',
        center: CityHex(col: 2, row: 0),
      ),
    ],
    research: _tradeResearch(exporterRevealsHorses: exporterRevealsHorses),
    runtimeState: GameRuntimeState.snapshot(
      submittedPlayerIds: const {'sentinel'},
      timeoutStreaksByPlayerId: const {'sentinel': 2},
      afkPlayerIds: const {'sentinel'},
      kickedPlayerIds: const {'removed_player'},
      intendedAttacks: const [
        IntendedAttack(
          attackerUnitId: 'sentinel_attacker',
          defenderCol: 2,
          defenderRow: 0,
          declaredAtTick: 41,
          declaringPlayerId: 'sentinel',
        ),
      ],
      diplomacy: diplomacy,
      dominationHoldTurnsByPlayerId: const {'sentinel': 3},
      culturalVictoryHoldTurnsByPlayerId: const {'sentinel': 4},
      mapObjectiveHoldStatesByObjectiveId: const {
        'sentinel_objective': MapObjectiveHoldState(
          objectiveId: 'sentinel_objective',
          playerId: 'sentinel',
          holdTurns: 2,
        ),
      },
      resourceTradeAgreements: agreements,
      turnStartedAt: DateTime.utc(2026, 7, 1, 12),
    ),
  );
}

ResearchState _tradeResearch({required bool exporterRevealsHorses}) {
  return ResearchState(
    players: {
      _importerId: PlayerResearchState(
        unlockedTechnologyIds: const {TechnologyId.ironWorking},
      ),
      _exporterId: PlayerResearchState(
        unlockedTechnologyIds: {
          if (exporterRevealsHorses) TechnologyId.animalHusbandry,
        },
      ),
    },
  );
}

MapTileLookup _tradeMap() {
  return WorldMapReadView(
    WorldMap(
      cols: 3,
      rows: 1,
      tiles: [
        for (var col = 0; col < 3; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: 0),
            terrains: const [TerrainType.plains],
            resources: switch (col) {
              0 => const [ResourceType.iron],
              2 => const [ResourceType.horses],
              _ => const [],
            },
            height: 0,
          ),
      ],
    ),
  );
}

void _expectRejectedTrade(
  PersistentResourceTradeResult result,
  PersistentGameState input,
  String reason,
) {
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(result.state, same(input));
  expect(result.state.runtimeState, same(input.runtimeState));
  expect(
    result.state.runtimeState.resourceTradeAgreements,
    same(input.runtimeState.resourceTradeAgreements),
  );
  expect(result.state.playerGold, same(input.playerGold));
  expect(result.state.cities, same(input.cities));
  expect(result.state.research, same(input.research));
}

void _expectOnlyTradeAgreementsChanged(
  PersistentResourceTradeResult result,
  PersistentGameState input,
  List<ResourceTradeAgreement> expectedAgreements,
) {
  expect(result.accepted, isTrue);
  expect(result.reason, isNull);
  expect(result.state, isNot(same(input)));
  expect(result.state.runtimeState, isNot(same(input.runtimeState)));
  expect(result.state.runtimeState.resourceTradeAgreements, expectedAgreements);
  expect(
    result.state,
    input.copyWith(
      runtimeState: input.runtimeState.copyWith(
        resourceTradeAgreements: expectedAgreements,
      ),
    ),
  );
  expect(result.state.playerColors, same(input.playerColors));
  expect(result.state.playerCountries, same(input.playerCountries));
  expect(result.state.playerGold, same(input.playerGold));
  expect(result.state.playerWarWeariness, same(input.playerWarWeariness));
  expect(result.state.playerStabilityNet, same(input.playerStabilityNet));
  expect(result.state.units, same(input.units));
  expect(result.state.cities, same(input.cities));
  expect(result.state.artifacts, same(input.artifacts));
  expect(result.state.fieldImprovements, same(input.fieldImprovements));
  expect(result.state.fogOfWar, same(input.fogOfWar));
  expect(result.state.research, same(input.research));
  expect(result.state.wonderRegistry, same(input.wonderRegistry));
  expect(
    result.state.runtimeState.submittedPlayerIds,
    same(input.runtimeState.submittedPlayerIds),
  );
  expect(
    result.state.runtimeState.timeoutStreaksByPlayerId,
    same(input.runtimeState.timeoutStreaksByPlayerId),
  );
  expect(
    result.state.runtimeState.afkPlayerIds,
    same(input.runtimeState.afkPlayerIds),
  );
  expect(
    result.state.runtimeState.kickedPlayerIds,
    same(input.runtimeState.kickedPlayerIds),
  );
  expect(
    result.state.runtimeState.diplomacy,
    same(input.runtimeState.diplomacy),
  );
  expect(
    result.state.runtimeState.intendedAttacks,
    same(input.runtimeState.intendedAttacks),
  );
  expect(
    result.state.runtimeState.dominationHoldTurnsByPlayerId,
    same(input.runtimeState.dominationHoldTurnsByPlayerId),
  );
  expect(
    result.state.runtimeState.culturalVictoryHoldTurnsByPlayerId,
    same(input.runtimeState.culturalVictoryHoldTurnsByPlayerId),
  );
  expect(
    result.state.runtimeState.mapObjectiveHoldStatesByObjectiveId,
    same(input.runtimeState.mapObjectiveHoldStatesByObjectiveId),
  );
  expect(
    result.state.runtimeState.turnStartedAt,
    input.runtimeState.turnStartedAt,
  );
  expect(
    () =>
        result.state.runtimeState.resourceTradeAgreements.add(_unrelatedTrade),
    throwsUnsupportedError,
  );
}
