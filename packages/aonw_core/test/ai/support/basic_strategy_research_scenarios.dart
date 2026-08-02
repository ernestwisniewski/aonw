part of '../basic_strategy_test.dart';

void _registerBasicStrategyResearchScenarios() {
  test('plans SelectTechnologyCommand when no research is active', () {
    final mapData = _foundingScenarioMap();
    final view = GameView.fromDomainState(
      DomainState.snapshot(),
      forPlayerId: 'player_1',
      turn: 1,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    final research = plan.commands.whereType<SelectTechnologyCommand>();
    expect(
      research,
      contains(
        const SelectTechnologyCommand('player_1', TechnologyId.agriculture),
      ),
    );
  });

  test('uses persona weights when selecting an early technology', () {
    final mapData = _foundingScenarioMap();
    final view = GameView.fromDomainState(
      DomainState.snapshot(),
      forPlayerId: 'player_1',
      turn: 1,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    AiContext contextFor(AiPersona persona) => AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
      persona: persona,
    );

    final aggressivePlan = const BasicStrategy().plan(
      view,
      contextFor(AiPersona.aggressive),
    );
    final economicPlan = const BasicStrategy().plan(
      view,
      contextFor(AiPersona.economic),
    );

    expect(
      aggressivePlan.commands.whereType<SelectTechnologyCommand>(),
      contains(const SelectTechnologyCommand('player_1', TechnologyId.hunting)),
    );
    expect(
      economicPlan.commands.whereType<SelectTechnologyCommand>(),
      contains(const SelectTechnologyCommand('player_1', TechnologyId.mining)),
    );
  });

  test('prioritizes technology that unlocks visible resource improvements', () {
    final mapData = _pastureResourceMap();
    final state = DomainState.snapshot(
      units: [
        GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 0, row: 0),
      ],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 1, row: 0)],
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
        },
      ),
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 2,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<SelectTechnologyCommand>(),
      contains(
        const SelectTechnologyCommand('player_1', TechnologyId.animalHusbandry),
      ),
    );
  });

  test('uses persona to choose unlocked city specialization', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 1, row: 1),
          buildings: {CityBuildingType.archive},
        ),
      ],
      research: _researchWithUnlocked(TechnologyId.specialization),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 2,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 2,
      rng: AiRng.fromTurn(turn: 2, playerId: 'player_1', baseSeed: 1001),
      persona: AiPersona.scientific,
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(
      plan.commands.whereType<SetCitySpecializationCommand>(),
      contains(
        const SetCitySpecializationCommand(
          'city_1',
          CitySpecializationType.science,
        ),
      ),
    );
  });

  test('skips research when a technology is already active', () {
    final mapData = _foundingScenarioMap();
    final state = DomainState.snapshot(
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.mining,
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 1,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
    );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapData,
      turn: 1,
      rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 1001),
    );

    final plan = const BasicStrategy().plan(view, context);

    expect(plan.commands.whereType<SelectTechnologyCommand>(), isEmpty);
  });
}
