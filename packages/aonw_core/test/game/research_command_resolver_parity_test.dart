import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';
const _agriculture = SelectTechnologyCommand(
  _playerId,
  TechnologyId.agriculture,
);

void main() {
  group('SelectTechnologyResolver', () {
    test('accepts available technology and owns only research update', () {
      final research = _research();

      final result = SelectTechnologyResolver.selectTechnology(
        research: research,
        cities: const [],
        fieldImprovements: const [],
        command: _agriculture,
        actorPlayerId: _playerId,
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      expect(identical(result.research, research), isFalse);
      expect(
        result.research.forPlayer(_playerId).activeTechnologyId,
        TechnologyId.agriculture,
      );
      expect(
        identical(
          result.research.forPlayer(_otherPlayerId),
          research.forPlayer(_otherPlayerId),
        ),
        isTrue,
      );
    });

    test('rejects before reading economy inputs and preserves identity', () {
      final research = _research();
      final neverReadCities = _ThrowingIterable<GameCity>();
      final neverReadImprovements = _ThrowingIterable<FieldImprovement>();

      final wrongActor = SelectTechnologyResolver.selectTechnology(
        research: research,
        cities: neverReadCities,
        fieldImprovements: neverReadImprovements,
        command: const SelectTechnologyCommand(_playerId, TechnologyId.storage),
        actorPlayerId: _otherPlayerId,
      );
      final unavailable = SelectTechnologyResolver.selectTechnology(
        research: research,
        cities: neverReadCities,
        fieldImprovements: neverReadImprovements,
        command: const SelectTechnologyCommand(_playerId, TechnologyId.storage),
        actorPlayerId: _playerId,
      );

      expect(wrongActor.accepted, isFalse);
      expect(wrongActor.reason, 'technology_player_not_controlled');
      expect(identical(wrongActor.research, research), isTrue);
      expect(unavailable.accepted, isFalse);
      expect(unavailable.reason, 'technology_not_available');
      expect(identical(unavailable.research, research), isTrue);
    });
  });

  group('research persistent/domain parity', () {
    test('accepts available technology with exact branch isolation', () {
      final persistent = _persistentState();
      final domain = _domainState();

      final persistentResult = const PersistentResearchCommandResolver()
          .selectTechnology(
            state: persistent,
            command: _agriculture,
            actorPlayerId: _playerId,
          );
      final domainResult = const DomainResearchCommandResolver()
          .selectTechnology(
            state: domain,
            command: _agriculture,
            actorPlayerId: _playerId,
          );

      _expectParity(persistentResult, domainResult, accepted: true);
      expect(
        persistentResult.state.research.forPlayer(_playerId),
        domainResult.state.research.forPlayer(_playerId),
      );
      _expectPersistentChangedOnlyResearch(persistent, persistentResult.state);
      _expectDomainChangedOnlyResearch(domain, domainResult.state);
    });

    test('forwards map and overflow inputs exactly', () {
      final research = _research(scienceOverflow: 4);
      final persistent = _persistentState(research: research, withCity: true);
      final domain = _domainState(research: research, withCity: true);
      final mapTiles = _mapTilesWithWheat();

      final persistentResult = const PersistentResearchCommandResolver()
          .selectTechnology(
            state: persistent,
            command: _agriculture,
            actorPlayerId: _playerId,
            mapTiles: mapTiles,
          );
      final domainResult = const DomainResearchCommandResolver()
          .selectTechnology(
            state: domain,
            command: _agriculture,
            actorPlayerId: _playerId,
            mapTiles: mapTiles,
          );

      _expectParity(persistentResult, domainResult, accepted: true);
      final selected = persistentResult.state.research.forPlayer(_playerId);
      expect(selected.activeTechnologyId, TechnologyId.agriculture);
      expect(selected.progressFor(TechnologyId.agriculture), 2);
      expect(selected.scienceOverflow, 0);
    });

    test('rejects missing prerequisite with input state identity', () {
      _expectRejectedParity(
        command: const SelectTechnologyCommand(_playerId, TechnologyId.storage),
        reason: 'technology_not_available',
      );
    });

    test('rejects technology blocked by an unlocked technology', () {
      final research = ResearchState(
        players: {
          _playerId: PlayerResearchState(
            unlockedTechnologyIds: {
              TechnologyId.agriculture,
              TechnologyId.mining,
            },
          ),
          _otherPlayerId: PlayerResearchState.empty,
        },
      );
      _expectRejectedParity(
        research: research,
        command: const SelectTechnologyCommand(_playerId, TechnologyId.trade),
        reason: 'technology_not_available',
        ruleset: _rulesetWithTradeBlockedByMining(),
      );
    });

    test('rejects another player selection with input state identity', () {
      _expectRejectedParity(
        actorPlayerId: _otherPlayerId,
        command: _agriculture,
        reason: 'technology_player_not_controlled',
      );
    });

    test('persistent adapter clears only matching pending selection', () {
      final runtimeState = _runtimeState(
        const PendingResearchSelection(ownerPlayerId: _playerId),
      );
      final persistent = _persistentState(runtimeState: runtimeState);

      final result = const PersistentResearchCommandResolver().selectTechnology(
        state: persistent,
        command: _agriculture,
        actorPlayerId: _playerId,
      );

      expect(result.accepted, isTrue);
      expect(result.state.runtimeState.pendingAction, isNull);
      expect(identical(result.state.runtimeState, runtimeState), isFalse);
      _expectRuntimeBranchesUnchanged(runtimeState, result.state.runtimeState);
    });

    test('persistent adapter preserves another pending action identity', () {
      const pendingAction = PendingCityWorkedHexSelection(
        ownerPlayerId: _playerId,
        cityId: 'city_1',
      );
      final runtimeState = _runtimeState(pendingAction);
      final persistent = _persistentState(runtimeState: runtimeState);

      final result = const PersistentResearchCommandResolver().selectTechnology(
        state: persistent,
        command: _agriculture,
        actorPlayerId: _playerId,
      );

      expect(result.accepted, isTrue);
      expect(identical(result.state.runtimeState, runtimeState), isTrue);
      expect(
        identical(result.state.runtimeState.pendingAction, pendingAction),
        isTrue,
      );
    });
  });
}

void _expectRejectedParity({
  ResearchState? research,
  required SelectTechnologyCommand command,
  required String reason,
  String actorPlayerId = _playerId,
  TechnologyRuleset ruleset = TechnologyRulesets.standard,
}) {
  final initialResearch = research ?? _research();
  final persistent = _persistentState(research: initialResearch);
  final domain = _domainState(research: initialResearch);

  final persistentResult = const PersistentResearchCommandResolver()
      .selectTechnology(
        state: persistent,
        command: command,
        actorPlayerId: actorPlayerId,
        ruleset: ruleset,
      );
  final domainResult = const DomainResearchCommandResolver().selectTechnology(
    state: domain,
    command: command,
    actorPlayerId: actorPlayerId,
    ruleset: ruleset,
  );

  _expectParity(
    persistentResult,
    domainResult,
    accepted: false,
    reason: reason,
  );
  expect(identical(persistentResult.state, persistent), isTrue);
  expect(identical(domainResult.state, domain), isTrue);
  expect(identical(persistentResult.state.research, initialResearch), isTrue);
  expect(identical(domainResult.state.research, initialResearch), isTrue);
}

void _expectParity(
  PersistentResearchCommandResult persistent,
  DomainResearchCommandResult domain, {
  required bool accepted,
  String? reason,
}) {
  expect(persistent.accepted, accepted);
  expect(domain.accepted, accepted);
  expect(persistent.reason, reason);
  expect(domain.reason, reason);
  expect(persistent.state.research, domain.state.research);
}

ResearchState _research({int scienceOverflow = 0}) {
  return ResearchState(
    players: {
      _playerId: PlayerResearchState(scienceOverflow: scienceOverflow),
      _otherPlayerId: PlayerResearchState.empty,
    },
  );
}

PersistentGameState _persistentState({
  ResearchState? research,
  GameRuntimeState? runtimeState,
  bool withCity = false,
}) {
  return PersistentGameState.snapshot(
    playerColors: const {_playerId: 1, _otherPlayerId: 2},
    playerCountries: const {
      _playerId: PlayerCountry.poland,
      _otherPlayerId: PlayerCountry.france,
    },
    playerGold: const {_playerId: 17},
    playerWarWeariness: const {_playerId: 2},
    playerStabilityNet: const {_playerId: 3},
    units: [GameUnit.startingWarrior(ownerPlayerId: _playerId)],
    cities: withCity ? const [_city] : const [],
    research: research ?? _research(),
    runtimeState: runtimeState ?? GameRuntimeState.empty,
  );
}

DomainState _domainState({ResearchState? research, bool withCity = false}) {
  return DomainState.snapshot(
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
    playerGold: const {_playerId: 17},
    playerWarWeariness: const {_playerId: 2},
    playerStabilityNet: const {_playerId: 3},
    units: [GameUnit.startingWarrior(ownerPlayerId: _playerId)],
    cities: withCity ? const [_city] : const [],
    research: research ?? _research(),
  );
}

const _city = GameCity(
  id: 'city_1',
  ownerPlayerId: _playerId,
  name: 'City',
  center: CityHex(col: 1, row: 1),
);

GameRuntimeState _runtimeState(PendingPlayerAction pendingAction) {
  return GameRuntimeState.snapshot(
    pendingAction: pendingAction,
    submittedPlayerIds: const {_otherPlayerId},
    timeoutStreaksByPlayerId: const {_otherPlayerId: 2},
    afkPlayerIds: const {_otherPlayerId},
    dominationHoldTurnsByPlayerId: const {_playerId: 3},
    culturalVictoryHoldTurnsByPlayerId: const {_otherPlayerId: 4},
    turnStartedAt: DateTime.utc(2026, 7, 18),
  );
}

void _expectPersistentChangedOnlyResearch(
  PersistentGameState before,
  PersistentGameState after,
) {
  expect(identical(after, before), isFalse);
  expect(identical(after.research, before.research), isFalse);
  expect(identical(after.playerColors, before.playerColors), isTrue);
  expect(identical(after.playerCountries, before.playerCountries), isTrue);
  expect(identical(after.playerGold, before.playerGold), isTrue);
  expect(
    identical(after.playerWarWeariness, before.playerWarWeariness),
    isTrue,
  );
  expect(
    identical(after.playerStabilityNet, before.playerStabilityNet),
    isTrue,
  );
  expect(identical(after.units, before.units), isTrue);
  expect(identical(after.cities, before.cities), isTrue);
  expect(identical(after.artifacts, before.artifacts), isTrue);
  expect(identical(after.fieldImprovements, before.fieldImprovements), isTrue);
  expect(identical(after.fogOfWar, before.fogOfWar), isTrue);
  expect(identical(after.runtimeState, before.runtimeState), isTrue);
  expect(identical(after.wonderRegistry, before.wonderRegistry), isTrue);
}

void _expectDomainChangedOnlyResearch(DomainState before, DomainState after) {
  expect(identical(after, before), isFalse);
  expect(identical(after.research, before.research), isFalse);
  expect(after.turn, before.turn);
  expect(identical(after.matchRules, before.matchRules), isTrue);
  expect(identical(after.participants, before.participants), isTrue);
  expect(identical(after.playerColors, before.playerColors), isTrue);
  expect(identical(after.playerCountries, before.playerCountries), isTrue);
  expect(identical(after.playerGold, before.playerGold), isTrue);
  expect(
    identical(after.playerWarWeariness, before.playerWarWeariness),
    isTrue,
  );
  expect(
    identical(after.playerStabilityNet, before.playerStabilityNet),
    isTrue,
  );
  expect(identical(after.units, before.units), isTrue);
  expect(identical(after.cities, before.cities), isTrue);
  expect(identical(after.artifacts, before.artifacts), isTrue);
  expect(identical(after.fieldImprovements, before.fieldImprovements), isTrue);
  expect(identical(after.fogOfWar, before.fogOfWar), isTrue);
  expect(identical(after.wonderRegistry, before.wonderRegistry), isTrue);
  expect(identical(after.intendedAttacks, before.intendedAttacks), isTrue);
  expect(identical(after.diplomacy, before.diplomacy), isTrue);
  expect(
    identical(after.resourceTradeAgreements, before.resourceTradeAgreements),
    isTrue,
  );
  expect(
    identical(
      after.dominationHoldTurnsByPlayerId,
      before.dominationHoldTurnsByPlayerId,
    ),
    isTrue,
  );
  expect(
    identical(
      after.culturalVictoryHoldTurnsByPlayerId,
      before.culturalVictoryHoldTurnsByPlayerId,
    ),
    isTrue,
  );
  expect(
    identical(
      after.mapObjectiveHoldStatesByObjectiveId,
      before.mapObjectiveHoldStatesByObjectiveId,
    ),
    isTrue,
  );
}

void _expectRuntimeBranchesUnchanged(
  GameRuntimeState before,
  GameRuntimeState after,
) {
  expect(
    identical(after.submittedPlayerIds, before.submittedPlayerIds),
    isTrue,
  );
  expect(
    identical(after.timeoutStreaksByPlayerId, before.timeoutStreaksByPlayerId),
    isTrue,
  );
  expect(identical(after.afkPlayerIds, before.afkPlayerIds), isTrue);
  expect(identical(after.kickedPlayerIds, before.kickedPlayerIds), isTrue);
  expect(identical(after.intendedAttacks, before.intendedAttacks), isTrue);
  expect(identical(after.diplomacy, before.diplomacy), isTrue);
  expect(
    identical(
      after.dominationHoldTurnsByPlayerId,
      before.dominationHoldTurnsByPlayerId,
    ),
    isTrue,
  );
  expect(
    identical(
      after.culturalVictoryHoldTurnsByPlayerId,
      before.culturalVictoryHoldTurnsByPlayerId,
    ),
    isTrue,
  );
  expect(after.turnStartedAt, before.turnStartedAt);
}

TechnologyRuleset _rulesetWithTradeBlockedByMining() {
  return TechnologyRuleset(
    science: TechnologyRulesets.standard.science,
    costs: TechnologyRulesets.standard.costs,
    technologies: {
      TechnologyId.agriculture: TechnologyRulesets.standard.definitionFor(
        TechnologyId.agriculture,
      ),
      TechnologyId.mining: TechnologyRulesets.standard.definitionFor(
        TechnologyId.mining,
      ),
      TechnologyId.trade: const TechnologyDefinition(
        id: TechnologyId.trade,
        name: 'Trade',
        description: 'Blocked test trade.',
        era: TechnologyEra.settlement,
        baseCost: 7,
        prerequisites: [TechnologyId.agriculture],
        blockedBy: [TechnologyId.mining],
        treePosition: TechnologyTreePosition(column: 1, row: 1),
      ),
    },
  );
}

MapTileLookup _mapTilesWithWheat() => WorldMapReadView(
  WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: row),
            terrains: const [TerrainType.grassland],
            resources: col == 1 && row == 1
                ? const [ResourceType.wheat]
                : const [],
            height: 0,
          ),
    ],
  ),
);

final class _ThrowingIterable<T> extends Iterable<T> {
  @override
  Iterator<T> get iterator => throw StateError('input must stay unread');
}
