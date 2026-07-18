part of 'rush_production_command_resolver_test.dart';

typedef _RushKernelScenario = ({
  String name,
  PersistentGameState state,
  RushProductionCommand command,
  String actorPlayerId,
  bool accepted,
  String? reason,
  _RushKernelAcceptance? acceptance,
  WonderRuleset wonderRuleset,
  PaceBalance paceBalance,
});

enum _RushKernelAcceptance { building, unit, wonder }

List<_RushKernelScenario> _rushKernelRejections() {
  return [
    _scenario(
      name: 'rejects a missing city without changing slices',
      state: _stateWithQueue(rushCharacterizationBuildingQueue()),
      command: const RushProductionCommand('missing_city'),
      reason: 'city_not_found',
    ),
    _scenario(
      name: 'rejects the wrong actor before queue validation',
      state: _stateWithQueue(
        CityProductionQueue.project(projectType: CityProjectType.wealth),
      ),
      actorPlayerId: rushCharacterizationOtherPlayerId,
      reason: 'city_not_controlled',
    ),
    _scenario(
      name: 'rejects an empty queue before treasury validation',
      state: _stateWithQueue(null, playerGold: const {}),
      reason: 'production_queue_empty',
    ),
    _scenario(
      name: 'rejects a continuous project before treasury validation',
      state: _stateWithQueue(
        CityProductionQueue.project(projectType: CityProjectType.wealth),
        playerGold: const {},
      ),
      reason: 'project_cannot_be_rushed',
    ),
    _scenario(
      name: 'rejects insufficient treasury without changing slices',
      state: _stateWithQueue(
        rushCharacterizationBuildingQueue(),
        playerGold: const {rushCharacterizationPlayerId: 1},
      ),
      reason: 'rush_production_unavailable',
    ),
  ];
}

_RushKernelScenario _scenario({
  required String name,
  required PersistentGameState state,
  RushProductionCommand command = const RushProductionCommand('city_1'),
  String actorPlayerId = rushCharacterizationPlayerId,
  required String reason,
}) {
  return (
    name: name,
    state: state,
    command: command,
    actorPlayerId: actorPlayerId,
    accepted: false,
    reason: reason,
    acceptance: null,
    wonderRuleset: WonderRuleset.standard,
    paceBalance: PaceBalance.unlimited,
  );
}

PersistentGameState _stateWithQueue(
  CityProductionQueue? queue, {
  Map<String, int>? playerGold,
}) {
  return rushCharacterizationState(
    cities: rushCharacterizationCities(
      rushCharacterizationCity(productionQueue: queue),
    ),
    playerGold: playerGold,
  );
}

void _expectRushKernelParity(_RushKernelScenario scenario) {
  final mapTiles = rushCharacterizationMap();
  final direct = _resolveRushKernel(scenario, mapTiles);
  final persistent = const PersistentCityProductionResolver().rushProduction(
    state: scenario.state,
    command: scenario.command,
    actorPlayerId: scenario.actorPlayerId,
    mapTiles: mapTiles,
    wonderRuleset: scenario.wonderRuleset,
    paceBalance: scenario.paceBalance,
  );
  final domainBefore = _domainFromPersistent(scenario.state);
  final domain = const DomainCityProductionResolver().rushProduction(
    state: domainBefore,
    command: scenario.command,
    actorPlayerId: scenario.actorPlayerId,
    mapTiles: mapTiles,
    wonderRuleset: scenario.wonderRuleset,
    paceBalance: scenario.paceBalance,
  );

  _expectRushOutcome(scenario, direct, persistent, domain);
  if (!scenario.accepted) {
    _expectRejectedRushSlices(
      scenario.state,
      domainBefore,
      direct,
      persistent,
      domain,
    );
    return;
  }
  _expectAcceptedRushSlices(scenario, domainBefore, direct, persistent, domain);
}

RushProductionCommandResult _resolveRushKernel(
  _RushKernelScenario scenario,
  MapTileLookup mapTiles,
) {
  final state = scenario.state;
  return RushProductionCommandResolver.resolve(
    cities: state.cities,
    units: state.units,
    artifacts: state.artifacts,
    fieldImprovements: state.fieldImprovements,
    playerGold: state.playerGold,
    playerStabilityNet: state.playerStabilityNet,
    research: state.research,
    wonderRegistry: state.wonderRegistry,
    command: scenario.command,
    actorPlayerId: scenario.actorPlayerId,
    mapTiles: mapTiles,
    cityRuleset: CityRulesets.standard,
    technologyRuleset: TechnologyRulesets.standard,
    stabilityRuleset: StabilityRuleset.standard,
    wonderRuleset: scenario.wonderRuleset,
    paceBalance: scenario.paceBalance,
  );
}

void _expectRushOutcome(
  _RushKernelScenario scenario,
  RushProductionCommandResult direct,
  PersistentCityProductionResult persistent,
  DomainCityProductionResult domain,
) {
  expect(direct.accepted, scenario.accepted);
  expect(persistent.accepted, direct.accepted);
  expect(domain.accepted, direct.accepted);
  expect(direct.reason, scenario.reason);
  expect(persistent.reason, direct.reason);
  expect(domain.reason, direct.reason);
  expect(persistent.state.cities, direct.cities);
  expect(domain.state.cities, direct.cities);
  expect(persistent.state.units, direct.units);
  expect(domain.state.units, direct.units);
  expect(persistent.state.playerGold, direct.playerGold);
  expect(domain.state.playerGold, direct.playerGold);
  expect(persistent.state.research, direct.research);
  expect(domain.state.research, direct.research);
  expect(persistent.state.wonderRegistry, direct.wonderRegistry);
  expect(domain.state.wonderRegistry, direct.wonderRegistry);
  expect(_eventJson(persistent.events), _eventJson(direct.events));
  expect(_eventJson(domain.events), _eventJson(direct.events));
}

void _expectRejectedRushSlices(
  PersistentGameState persistentBefore,
  DomainState domainBefore,
  RushProductionCommandResult direct,
  PersistentCityProductionResult persistent,
  DomainCityProductionResult domain,
) {
  expect(direct.cities, same(persistentBefore.cities));
  expect(direct.units, same(persistentBefore.units));
  expect(direct.playerGold, same(persistentBefore.playerGold));
  expect(direct.research, same(persistentBefore.research));
  expect(direct.wonderRegistry, same(persistentBefore.wonderRegistry));
  expect(direct.events, isEmpty);
  expect(persistent.state, same(persistentBefore));
  expect(domain.state, same(domainBefore));
}

DomainState _domainFromPersistent(PersistentGameState state) {
  return DomainState.snapshot(
    turn: 7,
    matchRules: MatchRules.standard,
    participants: const [
      Player(
        id: rushCharacterizationPlayerId,
        name: 'One',
        colorValue: 1,
        country: PlayerCountry.poland,
      ),
      Player(
        id: rushCharacterizationOtherPlayerId,
        name: 'Two',
        colorValue: 2,
        country: PlayerCountry.germany,
      ),
    ],
    playerGold: state.playerGold,
    playerWarWeariness: state.playerWarWeariness,
    playerStabilityNet: state.playerStabilityNet,
    units: state.units,
    cities: state.cities,
    artifacts: state.artifacts,
    fieldImprovements: state.fieldImprovements,
    research: state.research,
    wonderRegistry: state.wonderRegistry,
  );
}

String _eventJson(List<GameEvent> events) {
  return jsonEncode(events.map(GameEventSerializer.toJson).toList());
}
