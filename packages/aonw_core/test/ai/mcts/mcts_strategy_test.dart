import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsStrategy', () {
    test('falls back when deadline is below minimum budget', () {
      const fallbackCommand = SelectTechnologyCommand(
        'player_1',
        TechnologyId.agriculture,
      );
      const strategy = MctsStrategy(
        config: MctsConfig(minimumBudget: Duration(seconds: 1)),
        fallback: _StaticStrategy(commands: [fallbackCommand]),
      );

      final plan = strategy.plan(
        _view(),
        _context(deadline: DateTime.now().subtract(const Duration(seconds: 1))),
      );

      expect(plan.commands, const [fallbackCommand]);
      expect(plan.debug?.strategyId, 'static');
    });

    test('plans deterministic command-backed actions', () {
      const commands = [
        EndTurnCommand('player_1'),
        MoveUnitCommand('unit_1', 1, 0),
        SelectTechnologyCommand('player_1', TechnologyId.agriculture),
      ];
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 16,
          maxPlanningDepth: 2,
        ),
        fallback: _StaticStrategy(commands: commands),
      );

      final first = strategy.plan(_view(), _context());
      final second = strategy.plan(_view(), _context());

      expect(first.debug?.strategyId, 'mcts');
      expect(first.debug?.notes, contains('iterations 16'));
      expect(
        first.debug?.notes,
        contains(predicate<String>((note) => note.startsWith('elapsed '))),
      );
      expect(
        first.debug?.notes,
        contains(
          predicate<String>((note) => note.startsWith('explored nodes ')),
        ),
      );
      expect(
        first.debug?.notes,
        contains(
          predicate<String>((note) => note.startsWith('candidate calls ')),
        ),
      );
      expect(
        first.debug?.notes,
        contains(predicate<String>((note) => note.startsWith('source plans '))),
      );
      expect(first.debug?.metrics['mcts.candidateCalls'], greaterThan(0));
      expect(first.debug?.metrics['mcts.sourcePlanCalls'], greaterThan(0));
      expect(first.debug?.metrics['mcts.searchElapsedMicros'], isA<int>());
      expect(
        first.debug?.metrics['mcts.searchRolloutElapsedMicros'],
        isA<int>(),
      );
      expect(
        first.debug?.metrics['mcts.searchEvaluationElapsedMicros'],
        isA<int>(),
      );
      expect(first.debug?.metrics['mcts.validationElapsedMicros'], isA<int>());
      expect(
        first.debug?.metrics['mcts.baselinePlanElapsedMicros'],
        isA<int>(),
      );
      expect(first.debug?.metrics['mcts.mergeElapsedMicros'], isA<int>());
      expect(first.debug?.metrics['mcts.strategyElapsedMicros'], isA<int>());
      expect(first.commands, second.commands);
      expect(first.commands, isNot(contains(const EndTurnCommand('player_1'))));
      expect(
        first.commands,
        contains(
          const SelectTechnologyCommand('player_1', TechnologyId.agriculture),
        ),
      );
    });

    test('interactive runtime profile uses a bounded iteration budget', () {
      const strategy = MctsStrategy(
        runtimeProfile: MctsRuntimeProfile.interactive,
      );

      final plan = strategy.plan(_unitView(), _context(mapData: _unitMap()));

      expect(plan.debug?.strategyId, 'mcts');
      expect(plan.debug?.metrics['mcts.iterations'], 24);
      expect(plan.debug?.metrics['mcts.sourcePlanCalls'], 1);
      expect(plan.debug?.metrics['mcts.sourcePlanSkipped'], greaterThan(0));
    });

    test('battery saver runtime profile uses a tighter iteration budget', () {
      const strategy = MctsStrategy(
        runtimeProfile: MctsRuntimeProfile.batterySaver,
      );

      final plan = strategy.plan(_unitView(), _context(mapData: _unitMap()));

      expect(plan.debug?.strategyId, 'mcts');
      expect(plan.debug?.metrics['mcts.iterations'], 12);
      expect(plan.debug?.metrics['mcts.sourcePlanCalls'], 1);
      expect(plan.debug?.metrics['mcts.sourcePlanSkipped'], greaterThan(0));
    });

    test('bypasses late battery saver search without targetable contact', () {
      const fallbackCommand = SelectTechnologyCommand(
        'player_1',
        TechnologyId.agriculture,
      );
      const strategy = MctsStrategy(
        runtimeProfile: MctsRuntimeProfile.batterySaver,
        fallback: _StaticStrategy(
          commands: [MoveUnitCommand('warrior_1', 2, 0), fallbackCommand],
        ),
      );

      final plan = strategy.plan(_lateNoTargetView(), _context());

      expect(plan.commands, const [fallbackCommand]);
      expect(plan.debug?.strategyId, 'mcts');
      expect(
        plan.debug?.notes,
        contains('bypassed search: no targetable tactical contact'),
      );
      expect(plan.debug?.metrics['mcts.searchBypassed'], true);
      expect(plan.debug?.metrics['mcts.iterations'], 0);
      expect(plan.debug?.metrics['mcts.mergeElapsedMicros'], isA<int>());
    });

    test('bypasses late battery saver search for single-unit cleanup', () {
      const strategy = MctsStrategy(
        runtimeProfile: MctsRuntimeProfile.batterySaver,
      );

      final plan = strategy.plan(
        _focusFireView(turn: 70),
        _context(mapData: _focusFireMap()),
      );

      expect(plan.debug?.strategyId, 'mcts');
      expect(
        plan.debug?.notes,
        contains('bypassed search: single-unit cleanup'),
      );
      expect(plan.debug?.metrics['mcts.searchBypassed'], true);
      expect(plan.debug?.metrics['mcts.iterations'], 0);
    });

    test('keeps late battery saver search for multiple visible targets', () {
      const strategy = MctsStrategy(
        runtimeProfile: MctsRuntimeProfile.batterySaver,
      );

      final plan = strategy.plan(
        _focusFireView(turn: 70, extraEnemy: true),
        _context(mapData: _focusFireMap()),
      );

      expect(plan.debug?.strategyId, 'mcts');
      expect(plan.debug?.metrics['mcts.iterations'], 12);
      expect(plan.debug?.metrics['mcts.searchBypassed'], isNot(true));
    });

    test('does not emit multiple same-unit actions after search', () {
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 16,
          maxPlanningDepth: 2,
        ),
        actionGenerator: _StaticActionGenerator(
          actions: [
            CommandMctsAction(FortifyUnitCommand('warrior_1')),
            CommandMctsAction(MoveUnitCommand('warrior_1', 1, 0)),
            EndPlanningAction(),
          ],
        ),
      );

      final plan = strategy.plan(_unitView(), _context(mapData: _unitMap()));

      expect(
        _unitActionCount(plan.commands, 'warrior_1'),
        lessThanOrEqualTo(1),
      );
    });

    test('does not emit multiple attacks into the same defender hex', () {
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 16,
          maxPlanningDepth: 2,
        ),
        actionGenerator: _StaticActionGenerator(
          actions: [
            CommandMctsAction(AttackHexCommand('warrior_1', 1, 0)),
            CommandMctsAction(AttackHexCommand('warrior_2', 1, 0)),
            EndPlanningAction(),
          ],
        ),
      );

      final plan = strategy.plan(
        _focusFireView(),
        _context(mapData: _focusFireMap()),
      );

      expect(plan.commands.whereType<AttackHexCommand>(), hasLength(1));
    });

    test('keeps fallback economy commands when search ends tactically', () {
      const production = StartUnitProductionCommand(
        'city_1',
        GameUnitType.worker,
      );
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [production]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('warrior_1'))],
        ),
      );

      final plan = strategy.plan(
        _cityUnitView(),
        _context(mapData: _unitMap()),
      );

      expect(plan.commands, contains(const FortifyUnitCommand('warrior_1')));
      expect(plan.commands, contains(production));
    });

    test('keeps fallback settler relocation when search ends tactically', () {
      const settlerMove = MoveUnitCommand('settler_1', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [settlerMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('warrior_1'))],
        ),
      );

      final plan = strategy.plan(
        _civilianSupportView(),
        _context(mapData: _wideUnitMap()),
      );

      expect(plan.commands, contains(const FortifyUnitCommand('warrior_1')));
      expect(plan.commands, contains(settlerMove));
    });

    test('does not append fallback settler move after search uses settler', () {
      const settlerMove = MoveUnitCommand('settler_1', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [settlerMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(settlerMove)],
        ),
      );

      final plan = strategy.plan(
        _civilianSupportView(),
        _context(mapData: _wideUnitMap()),
      );

      expect(_unitActionCount(plan.commands, 'settler_1'), 1);
    });

    test('does not append fallback move into searched partial destination', () {
      const searchedSettlerMove = MoveUnitCommand('settler_1', 2, 0);
      const fallbackWarMove = MoveUnitCommand('warrior_war', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [fallbackWarMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(searchedSettlerMove)],
        ),
      );

      final plan = strategy.plan(
        _partialMoveReservationView(),
        _context(
          mapData: _partialMoveReservationMap(),
          strategicPlan: _warGoalPlan(unitId: 'warrior_war'),
        ),
      );

      expect(plan.commands, contains(searchedSettlerMove));
      expect(plan.commands, isNot(contains(fallbackWarMove)));
    });

    test('does not append fallback move into alternate partial approach', () {
      const searchedMove = MoveUnitCommand('scout_1', 2, 1);
      const fallbackWarMove = MoveUnitCommand('warrior_war', 1, 1);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [fallbackWarMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(searchedMove)],
        ),
      );

      final plan = strategy.plan(
        _alternateApproachReservationView(),
        _context(
          mapData: _pressureMap(),
          strategicPlan: _warGoalPlan(unitId: 'warrior_war'),
        ),
      );

      expect(plan.commands, contains(searchedMove));
      expect(plan.commands, isNot(contains(fallbackWarMove)));
    });

    test('does not append fallback move into alternate reachable approach', () {
      const searchedMove = MoveUnitCommand('scout_1', 2, 1);
      const fallbackWarMove = MoveUnitCommand('warrior_war', 1, 1);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [fallbackWarMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(searchedMove)],
        ),
      );

      final plan = strategy.plan(
        _alternateApproachReservationView(scoutMovementPoints: 3),
        _context(
          mapData: _pressureMap(),
          strategicPlan: _warGoalPlan(unitId: 'warrior_war'),
        ),
      );

      expect(plan.commands, contains(searchedMove));
      expect(plan.commands, isNot(contains(fallbackWarMove)));
    });

    test('does not move another unit into a searched support origin', () {
      const searchedSettlerMove = MoveUnitCommand('settler_1', 2, 0);
      const searchedWarMove = MoveUnitCommand('warrior_war', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 2,
        ),
        fallback: _StaticStrategy(commands: []),
        actionGenerator: _StaticActionGenerator(
          actions: [
            CommandMctsAction(searchedSettlerMove),
            CommandMctsAction(searchedWarMove),
          ],
        ),
      );

      final plan = strategy.plan(
        _supportOriginReservationView(),
        _context(
          mapData: _wideUnitMap(),
          strategicPlan: _warGoalPlan(unitId: 'warrior_war'),
        ),
      );

      expect(plan.commands, contains(searchedSettlerMove));
      expect(plan.commands, isNot(contains(searchedWarMove)));
    });

    test('does not append fallback settler move into non-visible hex', () {
      const settlerMove = MoveUnitCommand('settler_1', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [settlerMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('warrior_1'))],
        ),
      );

      final plan = strategy.plan(
        _civilianSupportView(visibleTarget: false),
        _context(mapData: _wideUnitMap()),
      );

      expect(plan.commands, contains(const FortifyUnitCommand('warrior_1')));
      expect(plan.commands, isNot(contains(settlerMove)));
    });

    test('keeps fallback settler move into discovered non-visible hex', () {
      const settlerMove = MoveUnitCommand('settler_1', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [settlerMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('warrior_1'))],
        ),
      );

      final plan = strategy.plan(
        _civilianSupportView(visibleTarget: false, discoveredTarget: true),
        _context(mapData: _wideUnitMap()),
      );

      expect(plan.commands, contains(const FortifyUnitCommand('warrior_1')));
      expect(plan.commands, contains(settlerMove));
    });

    test(
      'does not append fallback settler move into remembered enemy city',
      () {
        const settlerMove = MoveUnitCommand('settler_1', 1, 0);
        const strategy = MctsStrategy(
          config: MctsConfig(
            wallClockBudget: Duration.zero,
            minIterations: 8,
            maxPlanningDepth: 1,
          ),
          fallback: _StaticStrategy(commands: [settlerMove]),
          actionGenerator: _StaticActionGenerator(
            actions: [CommandMctsAction(FortifyUnitCommand('warrior_1'))],
          ),
        );

        final plan = strategy.plan(
          _civilianSupportView(enemyCityAtTarget: true),
          _context(mapData: _wideUnitMap()),
        );

        expect(plan.commands, contains(const FortifyUnitCommand('warrior_1')));
        expect(plan.commands, isNot(contains(settlerMove)));
      },
    );

    test(
      'does not append fallback settler move beside a remembered enemy city',
      () {
        const settlerMove = MoveUnitCommand('settler_1', 1, 0);
        const technology = SelectTechnologyCommand(
          'player_1',
          TechnologyId.agriculture,
        );
        const strategy = MctsStrategy(
          config: MctsConfig(
            wallClockBudget: Duration.zero,
            minIterations: 8,
            maxPlanningDepth: 1,
          ),
          fallback: _StaticStrategy(commands: [settlerMove]),
          actionGenerator: _StaticActionGenerator(
            actions: [CommandMctsAction(technology)],
          ),
        );

        final plan = strategy.plan(
          _civilianSupportView(
            enemyCityNearTarget: true,
            includeWarrior: false,
            withOwnCity: true,
          ),
          _context(mapData: _wideUnitMap()),
        );

        expect(plan.commands, contains(technology));
        expect(plan.commands, isNot(contains(settlerMove)));
      },
    );

    test('keeps fallback scout exploration when search ends tactically', () {
      const scoutMove = MoveUnitCommand('scout_1', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [scoutMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('warrior_1'))],
        ),
      );

      final plan = strategy.plan(
        _reconSupportView(),
        _context(mapData: _wideUnitMap()),
      );

      expect(plan.commands, contains(const FortifyUnitCommand('warrior_1')));
      expect(plan.commands, contains(scoutMove));
    });

    test('keeps fallback attacks that protect an active settler', () {
      const pressureAttack = AttackHexCommand('warrior_clearer', 1, 1);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [pressureAttack]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('warrior_reserve'))],
        ),
      );

      final plan = strategy.plan(
        _founderPressureSupportView(),
        _context(mapData: _pressureMap()),
      );

      expect(
        plan.commands,
        contains(const FortifyUnitCommand('warrior_reserve')),
      );
      expect(plan.commands, contains(pressureAttack));
    });

    test('keeps fallback war-goal military movement after tactical search', () {
      const warMove = MoveUnitCommand('warrior_war', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [warMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('warrior_reserve'))],
        ),
      );

      final plan = strategy.plan(
        _warGoalSupportView(),
        _context(
          mapData: _wideUnitMap(),
          strategicPlan: _warGoalPlan(unitId: 'warrior_war'),
        ),
      );

      expect(
        plan.commands,
        contains(const FortifyUnitCommand('warrior_reserve')),
      );
      expect(plan.commands, contains(warMove));
    });

    test('does not append fallback movement into combat retreat space', () {
      const attack = AttackHexCommand('warrior_attack', 1, 0);
      const warMove = MoveUnitCommand('warrior_war', 1, 1);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [warMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(attack)],
        ),
      );

      final plan = strategy.plan(
        _combatRetreatReservationView(),
        _context(
          mapData: _pressureMap(),
          strategicPlan: _warGoalPlan(unitId: 'warrior_war'),
        ),
      );

      expect(plan.commands, contains(attack));
      expect(plan.commands, isNot(contains(warMove)));
    });

    test('does not append fallback attack next to unstable combat', () {
      const attack = AttackHexCommand('warrior_attack', 1, 0);
      const followUpAttack = AttackHexCommand('warrior_war', 1, 1);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [followUpAttack]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(attack)],
        ),
      );

      final plan = strategy.plan(
        _combatRetreatReservationView(enemyAtAdjacentTarget: true),
        _context(
          mapData: _pressureMap(),
          strategicPlan: _warGoalPlan(unitId: 'warrior_war'),
        ),
      );

      expect(plan.commands, contains(attack));
      expect(plan.commands, isNot(contains(followUpAttack)));
    });

    test('keeps fallback war-goal attacks after tactical search', () {
      const warAttack = AttackHexCommand('warrior_war', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [warAttack]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('warrior_reserve'))],
        ),
      );

      final plan = strategy.plan(
        _warGoalSupportView(enemyAtTarget: true),
        _context(
          mapData: _wideUnitMap(),
          strategicPlan: _warGoalPlan(unitId: 'warrior_war'),
        ),
      );

      expect(
        plan.commands,
        contains(const FortifyUnitCommand('warrior_reserve')),
      );
      expect(plan.commands, contains(warAttack));
    });

    test('keeps fallback war-goal city attacks after tactical search', () {
      const cityAttack = AttackHexCommand('tank_war', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [cityAttack]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('warrior_reserve'))],
        ),
      );

      final plan = strategy.plan(
        _warGoalCitySupportView(),
        _context(
          mapData: _wideUnitMap(),
          strategicPlan: _warGoalPlan(unitId: 'tank_war'),
        ),
      );

      expect(
        plan.commands,
        contains(const FortifyUnitCommand('warrior_reserve')),
      );
      expect(plan.commands, contains(cityAttack));
    });

    test('lets fallback priority attack override searched fortify', () {
      const cityAttack = AttackHexCommand('tank_war', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [cityAttack]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('tank_war'))],
        ),
      );

      final plan = strategy.plan(
        _warGoalCitySupportView(),
        _context(
          mapData: _wideUnitMap(),
          strategicPlan: _warGoalPlan(unitId: 'tank_war'),
        ),
      );

      expect(plan.commands, contains(cityAttack));
      expect(
        plan.commands,
        isNot(contains(const FortifyUnitCommand('tank_war'))),
      );
    });

    test('lets fallback pressure move override searched fortify', () {
      const pressureMove = MoveUnitCommand('warrior_pressure', 1, 0);
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 8,
          maxPlanningDepth: 1,
        ),
        fallback: _StaticStrategy(commands: [pressureMove]),
        actionGenerator: _StaticActionGenerator(
          actions: [CommandMctsAction(FortifyUnitCommand('warrior_pressure'))],
        ),
      );

      final plan = strategy.plan(
        _pressureMoveSupportView(),
        _context(mapData: _wideUnitMap()),
      );

      expect(plan.commands, contains(pressureMove));
      expect(
        plan.commands,
        isNot(contains(const FortifyUnitCommand('warrior_pressure'))),
      );
    });
  });
}

class _StaticStrategy implements AiStrategy {
  final List<GameCommand> commands;

  const _StaticStrategy({required this.commands});

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    return AiTurnPlan(
      commands: commands,
      debug: AiDebugInfo(strategyId: 'static'),
    );
  }
}

class _StaticActionGenerator implements MctsActionGenerator {
  final List<MctsAction> actions;

  const _StaticActionGenerator({required this.actions});

  @override
  List<MctsAction> candidatesFor(SimulatedState state, AiContext context) {
    return actions;
  }
}

AiContext _context({
  DateTime? deadline,
  MapData? mapData,
  StrategicPlan? strategicPlan,
}) {
  final actualMapData = mapData ?? MapData(cols: 1, rows: 1, tiles: const []);
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: actualMapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
    deadline: deadline,
    strategicPlan: strategicPlan,
  );
}

GameView _view() {
  final mapData = MapData(cols: 1, rows: 1, tiles: const []);
  return GameView.fromPersistentState(
    const PersistentGameState(),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _unitView() {
  final mapData = _unitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _lateNoTargetView() {
  final mapData = _unitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        ),
      ],
      units: [
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 70,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _cityUnitView() {
  final mapData = _unitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        ),
      ],
      units: [
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _focusFireView({int turn = 1, bool extraEnemy = false}) {
  final mapData = _focusFireMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
        GameUnit(
          id: 'warrior_2',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 1,
          row: 1,
        ),
        GameUnit(
          id: 'enemy_tank',
          ownerPlayerId: 'player_2',
          type: GameUnitType.tank,
          name: 'Tank',
          col: 1,
          row: 0,
        ),
        if (extraEnemy)
          GameUnit(
            id: 'enemy_warrior',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            name: 'Warrior',
            col: 0,
            row: 1,
          ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 0, row: 1),
              const HexCoordinate(col: 1, row: 1),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: turn,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _civilianSupportView({
  bool visibleTarget = true,
  bool discoveredTarget = false,
  bool enemyCityAtTarget = false,
  bool enemyCityNearTarget = false,
  bool includeWarrior = true,
  bool withOwnCity = false,
}) {
  final mapData = _wideUnitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      cities: [
        if (withOwnCity)
          const GameCity(
            id: 'own_city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
          ),
        if (enemyCityAtTarget)
          const GameCity(
            id: 'enemy_city_1',
            ownerPlayerId: 'player_2',
            name: 'Enemy City',
            center: CityHex(col: 1, row: 0),
          ),
        if (enemyCityNearTarget)
          const GameCity(
            id: 'enemy_city_2',
            ownerPlayerId: 'player_2',
            name: 'Enemy City',
            center: CityHex(col: 2, row: 0),
          ),
      ],
      units: [
        GameUnit(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          name: 'Settler',
          col: 0,
          row: 0,
        ),
        if (includeWarrior)
          GameUnit(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            name: 'Warrior',
            col: 2,
            row: 0,
          ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {
              if (discoveredTarget) const HexCoordinate(col: 1, row: 0),
            },
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              if (visibleTarget) const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _reconSupportView() {
  final mapData = _wideUnitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'scout_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: 'Scout',
          col: 0,
          row: 0,
        ),
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 2,
          row: 0,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _partialMoveReservationView() {
  final mapData = _partialMoveReservationMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          name: 'Settler',
          col: 0,
          row: 0,
          movementPoints: 1,
        ),
        GameUnit(
          id: 'warrior_war',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 3,
          row: 0,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
              const HexCoordinate(col: 3, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _supportOriginReservationView() {
  final mapData = _wideUnitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'warrior_war',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
        GameUnit(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          name: 'Settler',
          col: 1,
          row: 0,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _alternateApproachReservationView({int scoutMovementPoints = 1}) {
  final mapData = _pressureMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'scout_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: 'Scout',
          col: 0,
          row: 1,
          movementPoints: scoutMovementPoints,
        ),
        GameUnit(
          id: 'warrior_war',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
              const HexCoordinate(col: 0, row: 1),
              const HexCoordinate(col: 1, row: 1),
              const HexCoordinate(col: 2, row: 1),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _founderPressureSupportView() {
  final mapData = _pressureMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        ),
      ],
      units: [
        GameUnit(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          name: 'Settler',
          col: 1,
          row: 0,
        ),
        GameUnit(
          id: 'warrior_clearer',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 1,
        ),
        GameUnit(
          id: 'warrior_reserve',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 2,
          row: 0,
        ),
        GameUnit(
          id: 'enemy_blocker',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: 'Enemy',
          col: 1,
          row: 1,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
              const HexCoordinate(col: 0, row: 1),
              const HexCoordinate(col: 1, row: 1),
              const HexCoordinate(col: 2, row: 1),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _warGoalSupportView({bool enemyAtTarget = false}) {
  final mapData = _wideUnitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'warrior_war',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
        GameUnit(
          id: 'warrior_reserve',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 2,
          row: 0,
        ),
        if (enemyAtTarget)
          GameUnit(
            id: 'enemy_worker',
            ownerPlayerId: 'player_2',
            type: GameUnitType.worker,
            name: 'Enemy Worker',
            col: 1,
            row: 0,
          ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _warGoalCitySupportView() {
  final mapData = _wideUnitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'tank_war',
          ownerPlayerId: 'player_1',
          type: GameUnitType.tank,
          name: 'Tank',
          col: 0,
          row: 0,
        ),
        GameUnit(
          id: 'warrior_reserve',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 2,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'enemy_city',
          ownerPlayerId: 'player_2',
          name: 'Enemy',
          center: CityHex(col: 1, row: 0),
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _pressureMoveSupportView() {
  final mapData = _wideUnitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'warrior_pressure',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
      ],
      cities: const [
        GameCity(
          id: 'enemy_city',
          ownerPlayerId: 'player_2',
          name: 'Enemy',
          center: CityHex(col: 2, row: 0),
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
    pressureTargetPlayerIds: const ['player_2'],
  );
}

GameView _combatRetreatReservationView({bool enemyAtAdjacentTarget = false}) {
  final mapData = _pressureMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'warrior_attack',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
        GameUnit(
          id: 'warrior_war',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 2,
          row: 1,
        ),
        GameUnit(
          id: 'enemy_warrior',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: 'Enemy',
          col: 1,
          row: 0,
        ),
        if (enemyAtAdjacentTarget)
          GameUnit(
            id: 'enemy_adjacent',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            name: 'Enemy',
            col: 1,
            row: 1,
          ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
              const HexCoordinate(col: 0, row: 1),
              const HexCoordinate(col: 1, row: 1),
              const HexCoordinate(col: 2, row: 1),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

StrategicPlan _warGoalPlan({required String unitId}) {
  return StrategicPlan(
    computedAtTurn: 1,
    mode: StrategicMode.military,
    expectations: const EconomyExpectations(
      expectedCityCount: 1,
      expectedWorkerCount: 0,
      expectedMilitaryCount: 1,
      goldReserveTarget: 0,
      minimumSciencePerTurn: 0,
    ),
    warGoals: [
      WarGoal(
        targetPlayerId: 'player_2',
        kind: WarGoalKind.captureCity,
        targetHex: const HexCoordinate(col: 2, row: 0),
        turnsBudget: 4,
        assignedUnitIds: [unitId],
        priority: 5,
      ),
    ],
  );
}

MapData _unitMap() {
  return MapData(
    cols: 2,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

MapData _focusFireMap() {
  return MapData(
    cols: 2,
    rows: 2,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
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
        col: 0,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

MapData _wideUnitMap() {
  return MapData(
    cols: 3,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
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
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

MapData _partialMoveReservationMap() {
  return MapData(
    cols: 4,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
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
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 3,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

MapData _pressureMap() {
  return MapData(
    cols: 3,
    rows: 2,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.plains],
        resources: [],
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
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 0,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 1,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
      TileData(
        col: 2,
        row: 1,
        terrains: [TerrainType.plains],
        resources: [],
        height: 0,
      ),
    ],
  );
}

int _unitActionCount(List<GameCommand> commands, String targetUnitId) {
  return commands.where((command) {
    final commandUnitId = switch (command) {
      MoveUnitCommand(:final unitId) => unitId,
      FortifyUnitCommand(:final unitId) => unitId,
      FoundCityCommand(:final founderId) => founderId,
      SelectWorkerImprovementCommand(:final unitId) => unitId,
      AssignWorkerToHexCommand(:final unitId) => unitId,
      AttackHexCommand(:final attackerUnitId) => attackerUnitId,
      _ => null,
    };
    return commandUnitId == targetUnitId;
  }).length;
}
