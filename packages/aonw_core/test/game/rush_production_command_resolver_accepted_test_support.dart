part of 'rush_production_command_resolver_test.dart';

List<_RushKernelScenario> _acceptedRushKernelScenarios() {
  return [
    _acceptedBuildingRushKernelScenario(),
    _acceptedUnitRushKernelScenario(),
    _acceptedWonderRushKernelScenario(),
  ];
}

_RushKernelScenario _acceptedBuildingRushKernelScenario() {
  final cost = CityProductionRules.buildingProductionCost(
    CityBuildingType.granary,
  );
  return _acceptedScenario(
    name: 'completed building is immutable and matches both adapters',
    acceptance: _RushKernelAcceptance.building,
    state: _stateWithQueue(
      rushCharacterizationBuildingQueue(investedProduction: cost - 1),
      playerGold: const {rushCharacterizationPlayerId: 2},
    ),
  );
}

_RushKernelScenario _acceptedUnitRushKernelScenario() {
  final cost = CityProductionRules.targetCost(
    const UnitProductionTarget(GameUnitType.warrior),
  );
  return _acceptedScenario(
    name: 'completed unit maps the changed unit slice through both adapters',
    acceptance: _RushKernelAcceptance.unit,
    state: _stateWithQueue(
      rushCharacterizationUnitQueue(investedProduction: cost - 1),
      playerGold: const {rushCharacterizationPlayerId: 2},
      artifacts: [rushCharacterizationHeroSword()],
    ),
  );
}

_RushKernelScenario _acceptedWonderRushKernelScenario() {
  final ruleset = _rushKernelWonderRuleset();
  const pace = PaceBalance.standard60;
  const target = WonderProductionTarget(WonderType.hangingGardens);
  final cost = CityProductionRules.targetCost(
    target,
    wonderRuleset: ruleset,
    paceBalance: pace,
  );
  return _acceptedScenario(
    name: 'completed wonder maps research, registry, refund and event order',
    acceptance: _RushKernelAcceptance.wonder,
    wonderRuleset: ruleset,
    paceBalance: pace,
    state: rushCharacterizationState(
      cities: [
        rushCharacterizationCity(
          productionQueue: CityProductionQueue.wonder(
            wonderType: WonderType.hangingGardens,
            investedProduction: cost - 1,
          ),
          productionOverflow: 5,
        ),
        rushCharacterizationCity(
          id: 'rival_city',
          ownerPlayerId: rushCharacterizationOtherPlayerId,
          center: const CityHex(col: 3, row: 3),
          productionQueue: CityProductionQueue.wonder(
            wonderType: WonderType.hangingGardens,
            investedProduction: 9,
          ),
          productionOverflow: 2,
        ),
        rushCharacterizationSentinelCity(),
      ],
      playerGold: const {
        rushCharacterizationPlayerId: 2,
        rushCharacterizationOtherPlayerId: 23,
      },
      research: ResearchState(
        players: {
          rushCharacterizationPlayerId: PlayerResearchState(
            activeTechnologyId: TechnologyId.mining,
            progressByTechnologyId: const {TechnologyId.mining: 4},
          ),
        },
      ),
      wonderRegistry: WonderRegistry.empty,
    ),
  );
}

_RushKernelScenario _acceptedScenario({
  required String name,
  required _RushKernelAcceptance acceptance,
  required PersistentGameState state,
  WonderRuleset wonderRuleset = WonderRuleset.standard,
  PaceBalance paceBalance = PaceBalance.unlimited,
}) {
  return (
    name: name,
    state: state,
    command: const RushProductionCommand('city_1'),
    actorPlayerId: rushCharacterizationPlayerId,
    accepted: true,
    reason: null,
    acceptance: acceptance,
    wonderRuleset: wonderRuleset,
    paceBalance: paceBalance,
  );
}

WonderRuleset _rushKernelWonderRuleset() {
  const standard = WonderRuleset.standard;
  final source = standard.definitionFor(WonderType.hangingGardens);
  return WonderRuleset(
    wonders: {
      ...standard.wonders,
      WonderType.hangingGardens: WonderDefinition(
        type: source.type,
        productionCost: 20,
        unlockTech: source.unlockTech,
        requirements: source.requirements,
        standingEffects: source.standingEffects,
        completionEffects: const [
          GrantFreeTechnology(),
          GrantGold(7),
          ProductionBurst(3),
        ],
      ),
    },
  );
}

void _expectAcceptedRushSlices(
  _RushKernelScenario scenario,
  DomainState domainBefore,
  RushProductionCommandResult direct,
  DomainCityProductionResult domain,
) {
  final acceptance = scenario.acceptance!;
  _expectAcceptedRushIdentities(
    acceptance,
    scenario.state,
    domainBefore,
    direct,
    domain,
  );
  _expectAcceptedRushImmutability(scenario.state, direct, domain);
  switch (acceptance) {
    case _RushKernelAcceptance.building:
      _expectCompletedBuilding(scenario.state, direct);
    case _RushKernelAcceptance.unit:
      _expectCompletedUnit(scenario.state, direct);
    case _RushKernelAcceptance.wonder:
      _expectCompletedWonder(scenario.state, direct);
  }
}

void _expectAcceptedRushIdentities(
  _RushKernelAcceptance acceptance,
  PersistentGameState persistentBefore,
  DomainState domainBefore,
  RushProductionCommandResult direct,
  DomainCityProductionResult domain,
) {
  final changes = switch (acceptance) {
    _RushKernelAcceptance.building => (
      units: false,
      research: false,
      registry: false,
    ),
    _RushKernelAcceptance.unit => (
      units: true,
      research: false,
      registry: false,
    ),
    _RushKernelAcceptance.wonder => (
      units: false,
      research: true,
      registry: true,
    ),
  };

  expect(direct.cities, isNot(same(persistentBefore.cities)));
  expect(direct.playerGold, isNot(same(persistentBefore.playerGold)));
  _expectSliceIdentity(direct.units, persistentBefore.units, changes.units);
  _expectSliceIdentity(
    direct.research,
    persistentBefore.research,
    changes.research,
  );
  _expectSliceIdentity(
    direct.wonderRegistry,
    persistentBefore.wonderRegistry,
    changes.registry,
  );

  expect(domain.state, isNot(same(domainBefore)));
  _expectDomainSliceIdentities(
    before: domainBefore,
    after: domain.state,
    changes: changes,
  );
}

void _expectDomainSliceIdentities({
  required DomainState before,
  required DomainState after,
  required ({bool units, bool research, bool registry}) changes,
}) {
  expect(after.cities, isNot(same(before.cities)));
  expect(after.playerGold, isNot(same(before.playerGold)));
  _expectSliceIdentity(after.units, before.units, changes.units);
  _expectSliceIdentity(after.research, before.research, changes.research);
  _expectSliceIdentity(
    after.wonderRegistry,
    before.wonderRegistry,
    changes.registry,
  );
}

void _expectSliceIdentity(Object after, Object before, bool changed) {
  expect(after, changed ? isNot(same(before)) : same(before));
}

void _expectAcceptedRushImmutability(
  PersistentGameState before,
  RushProductionCommandResult direct,
  DomainCityProductionResult domain,
) {
  expect(() => direct.cities.clear(), throwsUnsupportedError);
  expect(() => direct.units.clear(), throwsUnsupportedError);
  expect(
    () => direct.playerGold[rushCharacterizationPlayerId] = 999,
    throwsUnsupportedError,
  );
  expect(() => direct.events.clear(), throwsUnsupportedError);
  expect(() => domain.state.cities.clear(), throwsUnsupportedError);
  expect(() => domain.state.units.clear(), throwsUnsupportedError);
  expect(
    () => domain.state.playerGold[rushCharacterizationPlayerId] = 999,
    throwsUnsupportedError,
  );
  expect(() => domain.events.clear(), throwsUnsupportedError);
  for (final research in [direct.research, domain.state.research]) {
    _expectResearchImmutable(research);
  }
  for (final registry in [direct.wonderRegistry, domain.state.wonderRegistry]) {
    _expectRegistryImmutable(registry);
  }
  expect(direct.cities.last, same(before.cities.last));
}

void _expectResearchImmutable(ResearchState research) {
  expect(
    () => research.players['mutated'] = PlayerResearchState.empty,
    throwsUnsupportedError,
  );
}

void _expectRegistryImmutable(WonderRegistry registry) {
  expect(
    () => registry.completedBy[WonderType.greatWall] = 'mutated',
    throwsUnsupportedError,
  );
}

void _expectCompletedBuilding(
  PersistentGameState before,
  RushProductionCommandResult direct,
) {
  expect(direct.units, same(before.units));
  expect(direct.research, same(before.research));
  expect(direct.wonderRegistry, same(before.wonderRegistry));
  expect(direct.cities.first.productionQueue, isNull);
  expect(direct.cities.first.buildings, contains(CityBuildingType.granary));
  expect(direct.events.single, isA<CityBuiltBuildingEvent>());
}

void _expectCompletedUnit(
  PersistentGameState before,
  RushProductionCommandResult direct,
) {
  expect(direct.units, hasLength(before.units.length + 1));
  expect(direct.units.first, same(before.units.first));
  final produced = direct.units.last;
  expect(produced.id, 'city_1_warrior_1');
  expect(produced.type, GameUnitType.warrior);
  expect(produced.coordinate, const HexCoordinate(col: 1, row: 1));
  expect(produced.experiencePoints, 2);
  expect(direct.cities.first.productionQueue, isNull);
  final event = direct.events.single as CityProducedUnitEvent;
  expect(event.producedUnitId, produced.id);
}

void _expectCompletedWonder(
  PersistentGameState before,
  RushProductionCommandResult direct,
) {
  expect(direct.units, same(before.units));
  expect(
    direct.wonderRegistry.ownerOf(WonderType.hangingGardens),
    rushCharacterizationPlayerId,
  );
  final research = direct.research.forPlayer(rushCharacterizationPlayerId);
  expect(research.hasUnlocked(TechnologyId.mining), isTrue);
  expect(research.activeTechnologyId, isNull);
  expect(direct.cities[0].productionQueue, isNull);
  expect(direct.cities[0].productionOverflow, 3);
  expect(direct.cities[1].productionQueue, isNull);
  expect(direct.cities[1].productionOverflow, 11);
  expect(direct.playerGold[rushCharacterizationPlayerId], 7);
  expect(direct.playerGold[rushCharacterizationOtherPlayerId], 23);
  expect(direct.events, hasLength(3));
  expect(direct.events[0], isA<CityBuiltWonderEvent>());
  expect(direct.events[1], isA<TechnologyResearchedEvent>());
  final refund = direct.events[2] as WonderProductionRefundedEvent;
  expect(refund.cityId, 'rival_city');
  expect(refund.refundedProduction, 9);
}
