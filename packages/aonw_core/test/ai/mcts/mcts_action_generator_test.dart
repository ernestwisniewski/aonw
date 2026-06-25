import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _playerId = 'player_1';
const _enemyId = 'player_2';

void main() {
  group('BasicPlanMctsActionGenerator', () {
    test('filters terminal and already used commands', () {
      const move = MoveUnitCommand('unit_1', 1, 0);
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(
          commands: [
            move,
            EndTurnCommand('player_1'),
            SubmitTurnCommand('player_1'),
          ],
        ),
        candidateLimit: 8,
      );
      final context = _context();
      final state = SimulatedState.fromView(
        _view(
          units: [
            GameUnit(
              id: 'unit_1',
              ownerPlayerId: _playerId,
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      );

      final initial = generator.candidatesFor(state, context);
      final afterMove = generator.candidatesFor(
        state.apply(initial.first),
        context,
      );

      expect(initial, contains(const CommandMctsAction(move)));
      expect(
        initial,
        isNot(contains(const CommandMctsAction(EndTurnCommand('player_1')))),
      );
      expect(
        initial,
        isNot(contains(const CommandMctsAction(SubmitTurnCommand('player_1')))),
      );
      expect(afterMove, isNot(contains(const CommandMctsAction(move))));
      expect(afterMove.last, const EndPlanningAction());
    });

    test('can skip expensive source planning beyond configured depth', () {
      const move = MoveUnitCommand('unit_1', 1, 0);
      final source = _CountingStrategy(commands: const [move]);
      final stats = MctsActionGenerationStatsCollector();
      final generator = BasicPlanMctsActionGenerator(
        source: source,
        candidateLimit: 8,
        sourcePlanDepthLimit: 0,
        stats: stats,
      );
      final context = _context();
      final state = SimulatedState.fromView(
        _view(
          mapData: _lineMap(3),
          units: [
            GameUnit(
              id: 'unit_1',
              ownerPlayerId: _playerId,
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
          ],
          research: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        ),
        maxPlanningDepth: 3,
      );

      final initial = generator.candidatesFor(state, context);
      final afterMove = generator.candidatesFor(
        state.apply(const CommandMctsAction(move)),
        context,
      );

      expect(initial, contains(const CommandMctsAction(move)));
      expect(afterMove, isNot(contains(const CommandMctsAction(move))));
      expect(source.calls, 1);
      final snapshot = stats.snapshot();
      expect(snapshot.sourcePlanCalls, 1);
      expect(snapshot.sourcePlanSkipped, 1);
    });

    test('drops fallback moves into occupied tiles', () {
      const occupiedMove = MoveUnitCommand('warrior_1', 1, 0);
      const legalMove = MoveUnitCommand('warrior_1', 0, 1);
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [occupiedMove, legalMove]),
        candidateLimit: 8,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 1,
        row: 0,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, settler],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );

      expect(_commands(actions), contains(legalMove));
      expect(_commands(actions), isNot(contains(occupiedMove)));
    });

    test('drops moves whose path is blocked by hidden units', () {
      const blockedMove = MoveUnitCommand('warrior_1', 2, 0);
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [blockedMove]),
        candidateLimit: 8,
      );
      final mapData = _lineMap(3);
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final hiddenBlocker = GameUnit(
        id: 'hidden_blocker',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Hidden Blocker',
        col: 1,
        row: 0,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior, hiddenBlocker],
            fogOfWar: _fogForHexes(_playerId, {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 2, row: 0),
            }),
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );

      expect(_commands(actions), isNot(contains(blockedMove)));
    });

    test('keeps moves through full-turn passable terrain', () {
      const roughTerrainMove = MoveUnitCommand('warrior_1', 1, 0);
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [roughTerrainMove]),
        candidateLimit: 8,
      );
      final mapData = _highCostLineMap();
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );

      expect(_commands(actions), contains(roughTerrainMove));
    });

    test('drops moves into remembered enemy city centers', () {
      const cityMove = MoveUnitCommand('warrior_1', 1, 0);
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [cityMove]),
        candidateLimit: 8,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      const enemyCity = GameCity(
        id: 'enemy_city',
        ownerPlayerId: _enemyId,
        name: 'Enemy City',
        center: CityHex(col: 1, row: 0),
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior],
            cities: const [enemyCity],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );

      expect(_commands(actions), isNot(contains(cityMove)));
    });

    test('drops moves into discovered but non-visible hexes', () {
      const hiddenMove = MoveUnitCommand('warrior_1', 1, 0);
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [hiddenMove]),
        candidateLimit: 8,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final mapData = _lineMap(3);

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior],
            fogOfWar: FogOfWarState(
              players: {
                _playerId: PlayerFogOfWar(
                  playerId: _playerId,
                  discoveredHexes: {const HexCoordinate(col: 1, row: 0)},
                  visibleHexes: {const HexCoordinate(col: 0, row: 0)},
                ),
              },
            ),
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );

      expect(_commands(actions), isNot(contains(hiddenMove)));
    });

    test('adds research alternatives beyond fallback plan', () {
      const fallbackPick = SelectTechnologyCommand(
        _playerId,
        TechnologyId.agriculture,
      );
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [fallbackPick]),
        candidateLimit: 8,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(_view(), maxPlanningDepth: 3),
        _context(),
      );
      final commands = _commands(actions);

      expect(commands, contains(fallbackPick));
      expect(
        commands,
        contains(const SelectTechnologyCommand(_playerId, TechnologyId.mining)),
      );
      expect(
        commands.where((command) => command == fallbackPick),
        hasLength(1),
      );
    });

    test('adds multiple city production alternatives', () {
      const fallbackPick = StartBuildingCommand(
        'city_1',
        CityBuildingType.granary,
      );
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [fallbackPick]),
        candidateLimit: 12,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 3,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );
      final commands = _commands(actions);

      expect(commands, contains(fallbackPick));
      expect(
        commands,
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.worker),
        ),
      );
      expect(
        commands,
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.warrior),
        ),
      );
      expect(
        commands,
        contains(
          const StartCityProjectCommand('city_1', CityProjectType.wealth),
        ),
      );
    });

    test('adds replacement production alternatives for project queues', () {
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: []),
        candidateLimit: 12,
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: const CityHex(col: 0, row: 0),
        population: 3,
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            cities: [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );
      final commands = _commands(actions);

      expect(
        commands,
        contains(
          const StartUnitProductionCommand('city_1', GameUnitType.worker),
        ),
      );
      expect(
        commands,
        isNot(
          contains(
            const StartCityProjectCommand('city_1', CityProjectType.wealth),
          ),
        ),
      );
    });

    test(
      'keeps production alternatives from being starved by combat options',
      () {
        const generator = BasicPlanMctsActionGenerator(
          source: _StaticStrategy(commands: []),
          candidateLimit: 8,
        );
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: _playerId,
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
          population: 4,
        );
        final units = [
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: _playerId,
            type: GameUnitType.warrior,
            col: 1,
            row: 1,
          ),
          GameUnit.produced(
            id: 'warrior_2',
            ownerPlayerId: _playerId,
            type: GameUnitType.warrior,
            col: 1,
            row: 2,
          ),
          for (final entry in const [
            ('enemy_1', 2, 1),
            ('enemy_2', 1, 0),
            ('enemy_3', 0, 1),
            ('enemy_4', 2, 2),
            ('enemy_5', 1, 3),
            ('enemy_6', 0, 2),
          ])
            GameUnit.produced(
              id: entry.$1,
              ownerPlayerId: _enemyId,
              type: GameUnitType.warrior,
              col: entry.$2,
              row: entry.$3,
            ),
        ];

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              mapData: _squareMap(cols: 4, rows: 4),
              cities: const [city],
              units: units,
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            ),
            maxPlanningDepth: 3,
          ),
          _context(mapData: _squareMap(cols: 4, rows: 4)),
        );
        final commands = _commands(actions);

        expect(
          commands,
          contains(
            const StartUnitProductionCommand('city_1', GameUnitType.settler),
          ),
        );
      },
    );

    test('adds worker improvement alternatives', () {
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: []),
        candidateLimit: 8,
      );
      final city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: const CityHex(col: 0, row: 0),
        controlledHexes: const [CityHex(col: 1, row: 0)],
        productionQueue: CityProductionQueue.project(
          projectType: CityProjectType.wealth,
        ),
      );
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.worker,
        name: 'Worker',
        col: 1,
        row: 0,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [worker],
            cities: [city],
            research: PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.agriculture},
              activeTechnologyId: TechnologyId.mining,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );

      expect(
        _commands(actions),
        contains(
          const SelectWorkerImprovementCommand(
            'worker_1',
            FieldImprovementType.farm,
          ),
        ),
      );
    });

    test('adds combat alternatives for visible enemies', () {
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: []),
        candidateLimit: 8,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 1,
        row: 0,
        hitPoints: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, enemy],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );

      expect(
        _commands(actions),
        contains(const AttackHexCommand('warrior_1', 1, 0)),
      );
    });

    test('drops combat alternatives against friendly players', () {
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(
          commands: [AttackHexCommand('warrior_1', 1, 0)],
        ),
        candidateLimit: 8,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final friendly = GameUnit(
        id: 'friendly_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Friendly',
        col: 1,
        row: 0,
        hitPoints: 1,
      );
      final diplomacy = DiplomacyState.empty.setStatus(
        _playerId,
        _enemyId,
        DiplomaticRelationStatus.friendly,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, friendly],
            diplomacy: diplomacy,
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );

      expect(
        _commands(actions),
        isNot(contains(const AttackHexCommand('warrior_1', 1, 0))),
      );
    });

    test('adds capture alternatives for remembered enemy cities', () {
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: []),
        candidateLimit: 8,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      const enemyCity = GameCity(
        id: 'enemy_city',
        ownerPlayerId: _enemyId,
        name: 'Enemy City',
        center: CityHex(col: 1, row: 0),
        population: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior],
            cities: const [enemyCity],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );

      expect(
        _commands(actions),
        contains(
          const AttackHexCommand(
            'warrior_1',
            1,
            0,
            cityConquestAction: CityConquestAction.capture,
          ),
        ),
      );
    });

    test('adds city attack when own unit is already on the city center', () {
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: []),
        candidateLimit: 8,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 0,
      );
      const enemyCity = GameCity(
        id: 'enemy_city',
        ownerPlayerId: _enemyId,
        name: 'Enemy City',
        center: CityHex(col: 1, row: 0),
        population: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior],
            cities: const [enemyCity],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );

      expect(
        _commands(actions),
        contains(
          const AttackHexCommand(
            'warrior_1',
            1,
            0,
            cityConquestAction: CityConquestAction.capture,
          ),
        ),
      );
    });

    test('drops city attacks blocked by an own unit on the target hex', () {
      const blockedAttack = AttackHexCommand('warrior_1', 1, 0);
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [blockedAttack]),
        candidateLimit: 8,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final blocker = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 0,
      );
      const enemyCity = GameCity(
        id: 'enemy_city',
        ownerPlayerId: _enemyId,
        name: 'Enemy City',
        center: CityHex(col: 1, row: 0),
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, blocker],
            cities: const [enemyCity],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );

      expect(_commands(actions), isNot(contains(blockedAttack)));
    });

    test('drops founding commands that are illegal in the current state', () {
      const invalidFounding = FoundCityCommand(
        'settler_1',
        controlledHexes: [CityHex(col: 2, row: 0), CityHex(col: 2, row: 1)],
      );
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [invalidFounding]),
        candidateLimit: 8,
      );
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 0,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [settler],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );

      expect(_commands(actions), isNot(contains(invalidFounding)));
    });

    test('drops founding commands when nearby fog could hide a city', () {
      const riskyFounding = FoundCityCommand(
        'settler_1',
        controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
      );
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [riskyFounding]),
        candidateLimit: 8,
      );
      final mapData = _squareMap(cols: 4, rows: 4);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 0,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 3, row: 3),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
            fogOfWar: _fogForHexes(_playerId, {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 0, row: 1),
            }),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );

      expect(_commands(actions), isNot(contains(riskyFounding)));
    });

    test('keeps founding commands under AI full-map planning', () {
      const founding = FoundCityCommand(
        'settler_1',
        controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
      );
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [founding]),
        candidateLimit: 8,
      );
      final mapData = _squareMap(cols: 4, rows: 4);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 0,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 3, row: 3),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
            fogOfWar: _fogForHexes(_playerId, {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 0, row: 1),
            }),
            ignoreFogOfWar: true,
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );

      expect(_commands(actions), contains(founding));
    });

    test('keeps founding commands when the exclusion zone is known', () {
      const founding = FoundCityCommand(
        'settler_1',
        controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
      );
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [founding]),
        candidateLimit: 8,
      );
      final mapData = _squareMap(cols: 4, rows: 4);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 0,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 3, row: 3),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );

      expect(_commands(actions), contains(founding));
    });

    test('adds current founding alternatives for active settlers', () {
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: []),
        candidateLimit: 8,
      );
      final mapData = _squareMap(cols: 8, rows: 8);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 3,
        row: 4,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 7, row: 7),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );
      final foundings = _commands(actions).whereType<FoundCityCommand>().where(
        (command) => command.founderId == 'settler_1',
      );

      expect(foundings, isNotEmpty);
      expect(foundings.single.controlledHexes, hasLength(2));
    });

    test('adds spacing moves for settlers stuck near owned cities', () {
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: []),
        candidateLimit: 8,
      );
      final mapData = _squareMap(cols: 5, rows: 5);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 4, row: 4),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );

      expect(
        _commands(actions),
        contains(const MoveUnitCommand('settler_1', 0, 2)),
      );
    });

    test('reserves room for spacing moves when fallback plan is full', () {
      final generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(
          commands: [
            for (var index = 0; index < 12; index++)
              StartCityProjectCommand('city_$index', CityProjectType.wealth),
          ],
        ),
        candidateLimit: 8,
      );
      final mapData = _squareMap(cols: 5, rows: 5);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 4, row: 4),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );
      final commands = _commands(actions);

      expect(commands, hasLength(8));
      expect(commands, contains(const MoveUnitCommand('settler_1', 0, 2)));
    });

    test('drops partial second-city founding until the ring is known', () {
      const founding = FoundCityCommand(
        'settler_1',
        controlledHexes: [CityHex(col: 3, row: 2), CityHex(col: 4, row: 3)],
      );
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [founding]),
        candidateLimit: 8,
      );
      final mapData = _squareMap(cols: 8, rows: 8);
      final visibleHexes = {
        for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
      }..remove(const HexCoordinate(col: 2, row: 2));
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 3,
        row: 3,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 6,
        row: 3,
      );
      final worker = GameUnit(
        id: 'enemy_worker',
        ownerPlayerId: _enemyId,
        type: GameUnitType.worker,
        name: 'Worker',
        col: 1,
        row: 3,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, enemy, worker],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
            fogOfWar: _fogForHexes(_playerId, visibleHexes),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );

      expect(_commands(actions), isNot(contains(founding)));
    });

    test('drops partial third-city founding until the ring is known', () {
      const founding = FoundCityCommand(
        'settler_1',
        controlledHexes: [CityHex(col: 3, row: 2), CityHex(col: 4, row: 3)],
      );
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [founding]),
        candidateLimit: 8,
      );
      final mapData = _squareMap(cols: 8, rows: 8);
      final visibleHexes = {
        for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
      }..remove(const HexCoordinate(col: 2, row: 2));
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 3,
        row: 3,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 7, row: 7),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
            fogOfWar: _fogForHexes(_playerId, visibleHexes),
          ),
          maxPlanningDepth: 3,
        ),
        _context(mapData: mapData),
      );

      expect(_commands(actions), isNot(contains(founding)));
    });

    test('keeps tactical alternatives under a tight candidate limit', () {
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: []),
        candidateLimit: 3,
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 1),
        population: 3,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
        hitPoints: 7,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 1,
        row: 0,
        hitPoints: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, enemy],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(),
      );
      final commands = _commands(actions);

      expect(commands, hasLength(3));
      expect(commands, contains(const FortifyUnitCommand('warrior_1')));
    });

    test('respects candidate limit and de-duplicates commands', () {
      const fallbackPick = SelectTechnologyCommand(
        _playerId,
        TechnologyId.agriculture,
      );
      const generator = BasicPlanMctsActionGenerator(
        source: _StaticStrategy(commands: [fallbackPick, fallbackPick]),
        candidateLimit: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(_view(), maxPlanningDepth: 3),
        _context(),
      );
      final commands = _commands(actions);

      expect(commands, hasLength(2));
      expect(commands, contains(fallbackPick));
      expect(
        commands,
        contains(const SelectTechnologyCommand(_playerId, TechnologyId.mining)),
      );
    });
  });

  group('StrategyAwareMctsActionGenerator', () {
    test('prioritizes attacks that match active war goals', () {
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 1,
        row: 0,
        hitPoints: 1,
      );
      const attack = AttackHexCommand('warrior_1', 1, 0);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(
              StartCityProjectCommand('city_1', CityProjectType.wealth),
            ),
            CommandMctsAction(attack),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, enemy],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            warGoals: [
              WarGoal(
                targetPlayerId: _enemyId,
                kind: WarGoalKind.eliminateUnits,
                targetHex: const HexCoordinate(col: 1, row: 0),
                turnsBudget: 3,
                assignedUnitIds: const ['warrior_1'],
                priority: 0.9,
              ),
            ],
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(attack));
      expect(actions.last, const EndPlanningAction());
    });

    test('keeps assigned offensive units from chasing unrelated attacks', () {
      final mapData = _squareMap(cols: 5, rows: 3);
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 1,
      );
      final unrelatedEnemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 0,
        row: 0,
        hitPoints: 1,
      );
      const unrelatedAttack = AttackHexCommand('warrior_1', 0, 0);
      const warMove = MoveUnitCommand('warrior_1', 1, 1);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(unrelatedAttack),
            CommandMctsAction(warMove),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior, unrelatedEnemy],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            warGoals: [
              WarGoal(
                targetPlayerId: 'player_3',
                kind: WarGoalKind.captureCity,
                targetHex: const HexCoordinate(col: 4, row: 1),
                turnsBudget: 8,
                assignedUnitIds: const ['warrior_1'],
                priority: 6,
              ),
            ],
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(warMove));
      expect(
        actions,
        isNot(contains(const CommandMctsAction(unrelatedAttack))),
      );
    });

    test('keeps frontline blocker attacks for assigned offensive units', () {
      final mapData = _squareMap(cols: 5, rows: 3);
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 1,
      );
      final blocker = GameUnit(
        id: 'frontline_blocker',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Blocker',
        col: 1,
        row: 1,
        hitPoints: 1,
      );
      const blockerAttack = AttackHexCommand('warrior_1', 1, 1);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [CommandMctsAction(blockerAttack), EndPlanningAction()],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior, blocker],
            cities: const [
              GameCity(
                id: 'goal_city',
                ownerPlayerId: 'player_3',
                name: 'Goal',
                center: CityHex(col: 4, row: 1),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            warGoals: [
              WarGoal(
                targetPlayerId: 'player_3',
                kind: WarGoalKind.captureCity,
                targetHex: const HexCoordinate(col: 4, row: 1),
                targetCity: const CityHex(col: 4, row: 1),
                turnsBudget: 8,
                assignedUnitIds: const ['warrior_1'],
                priority: 6,
              ),
            ],
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(blockerAttack));
      expect(actions.last, const EndPlanningAction());
    });

    test('drops low-impact war-goal skirmishes', () {
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 1,
        row: 0,
      );
      const attack = AttackHexCommand('warrior_1', 1, 0);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [CommandMctsAction(attack), EndPlanningAction()],
        ),
        candidateLimit: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, enemy],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            warGoals: [
              WarGoal(
                targetPlayerId: _enemyId,
                kind: WarGoalKind.eliminateUnits,
                targetHex: const HexCoordinate(col: 1, row: 0),
                turnsBudget: 3,
                assignedUnitIds: const ['warrior_1'],
                priority: 0.9,
              ),
            ],
          ),
        ),
      );

      expect(_commands(actions), isEmpty);
      expect(actions, const [EndPlanningAction()]);
    });

    test('does not promote far defensive war-goal attacks', () {
      final mapData = _lineMap(6);
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 4,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 5,
        row: 0,
        hitPoints: 1,
      );
      const attack = AttackHexCommand('warrior_1', 5, 0);
      const project = StartCityProjectCommand('city_1', CityProjectType.wealth);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(attack),
            CommandMctsAction(project),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior, enemy],
            cities: const [
              GameCity(
                id: 'city_1',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.consolidate,
            warGoals: [
              WarGoal(
                targetPlayerId: _enemyId,
                kind: WarGoalKind.defend,
                targetHex: const HexCoordinate(col: 0, row: 0),
                turnsBudget: 3,
                assignedUnitIds: const ['warrior_1'],
                priority: 0.9,
              ),
            ],
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(project));
      expect(actions, isNot(contains(const CommandMctsAction(attack))));
      expect(actions.last, const EndPlanningAction());
    });

    test('promotes local defensive war-goal attacks', () {
      final mapData = _lineMap(6);
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 4,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 5,
        row: 0,
        hitPoints: 1,
      );
      const attack = AttackHexCommand('warrior_1', 5, 0);
      const project = StartCityProjectCommand('city_1', CityProjectType.wealth);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(project),
            CommandMctsAction(attack),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior, enemy],
            cities: const [
              GameCity(
                id: 'city_1',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 3, row: 0),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.consolidate,
            warGoals: [
              WarGoal(
                targetPlayerId: _enemyId,
                kind: WarGoalKind.defend,
                targetHex: const HexCoordinate(col: 3, row: 0),
                turnsBudget: 3,
                assignedUnitIds: const ['warrior_1'],
                priority: 0.9,
              ),
            ],
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(attack));
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes settler movement toward assigned city sites', () {
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 0,
      );
      const move = MoveUnitCommand('settler_1', 1, 0);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(
              StartCityProjectCommand('city_1', CityProjectType.wealth),
            ),
            CommandMctsAction(move),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [settler],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          strategicPlan: _strategicPlan(
            mode: StrategicMode.expand,
            settlerAssignments: const {'settler_1': CityHex(col: 2, row: 0)},
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(move));
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes settler moves that reveal assigned founding rings', () {
      final mapData = _squareMap(cols: 5, rows: 5);
      final visibleHexes = {
        const HexCoordinate(col: 0, row: 0),
        for (final tile in mapData.tiles)
          if (HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 2, row: 2),
                  ) <
                  CityFoundingRules.minimumCenterDistance &&
              tile.col < 4)
            HexCoordinate.fromTile(tile),
      };
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 2,
        row: 2,
      );
      const revealMove = MoveUnitCommand('settler_1', 3, 2);
      const project = StartCityProjectCommand(
        'capital',
        CityProjectType.wealth,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(project),
            CommandMctsAction(revealMove),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
            fogOfWar: _fogForHexes(_playerId, visibleHexes),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.expand,
            settlerAssignments: const {'settler_1': CityHex(col: 2, row: 2)},
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(revealMove));
      expect(actions.last, const EndPlanningAction());
    });

    test(
      'keeps assigned settler reveal moves ahead of routine defense builds',
      () {
        final mapData = _squareMap(cols: 5, rows: 5);
        final visibleHexes = {
          const HexCoordinate(col: 0, row: 0),
          for (final tile in mapData.tiles)
            if (HexDistance.between(
                      HexCoordinate.fromTile(tile),
                      const HexCoordinate(col: 2, row: 2),
                    ) <
                    CityFoundingRules.minimumCenterDistance &&
                tile.col < 4)
              HexCoordinate.fromTile(tile),
        };
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.settler,
          name: 'Settler',
          col: 2,
          row: 2,
        );
        final garrison = GameUnit(
          id: 'warrior_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ).copyWithHitPoints(7);
        final reserve = GameUnit(
          id: 'warrior_2',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 1,
        );
        const revealMove = MoveUnitCommand('settler_1', 3, 2);
        const barracks = StartBuildingCommand(
          'capital',
          CityBuildingType.barracks,
        );
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(barracks),
              CommandMctsAction(FortifyUnitCommand('warrior_1')),
              CommandMctsAction(revealMove),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 1,
        );

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              mapData: mapData,
              units: [settler, garrison, reserve],
              cities: const [
                GameCity(
                  id: 'capital',
                  ownerPlayerId: _playerId,
                  name: 'Capital',
                  center: CityHex(col: 0, row: 0),
                ),
              ],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
              fogOfWar: _fogForHexes(_playerId, visibleHexes),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            mapData: mapData,
            strategicPlan: _strategicPlan(
              mode: StrategicMode.consolidate,
              settlerAssignments: const {'settler_1': CityHex(col: 2, row: 2)},
              defenses: {
                'capital': StrategicDefenseAssignment(
                  cityId: 'capital',
                  cityCenter: const CityHex(col: 0, row: 0),
                  threatLevel: 1,
                  assignedUnitIds: const ['warrior_1'],
                ),
              },
            ),
          ),
        );

        expect(actions.first, const CommandMctsAction(revealMove));
        expect(actions.last, const EndPlanningAction());
      },
    );

    test('keeps two-city reveal moves near distant visible military', () {
      final mapData = _squareMap(cols: 7, rows: 5);
      final visibleHexes = {
        const HexCoordinate(col: 0, row: 0),
        const HexCoordinate(col: 6, row: 2),
        for (final tile in mapData.tiles)
          if (HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 2, row: 2),
                  ) <
                  CityFoundingRules.minimumCenterDistance &&
              tile.col < 4)
            HexCoordinate.fromTile(tile),
      };
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 2,
        row: 2,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 6,
        row: 2,
      );
      const revealMove = MoveUnitCommand('settler_1', 3, 2);
      const project = StartCityProjectCommand(
        'capital',
        CityProjectType.wealth,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(project),
            CommandMctsAction(revealMove),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, enemy],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 6, row: 4),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
            fogOfWar: _fogForHexes(_playerId, visibleHexes),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.expand,
            settlerAssignments: const {'settler_1': CityHex(col: 2, row: 2)},
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(revealMove));
      expect(actions.last, const EndPlanningAction());
    });

    test('keeps assigned settler moves near enemy civilian units', () {
      final mapData = _squareMap(cols: 7, rows: 5);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 4,
        row: 2,
      );
      final worker = GameUnit(
        id: 'enemy_worker',
        ownerPlayerId: _enemyId,
        type: GameUnitType.worker,
        name: 'Worker',
        col: 3,
        row: 1,
      );
      const move = MoveUnitCommand('settler_1', 3, 2);
      const building = StartBuildingCommand('capital', CityBuildingType.walls);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(building),
            CommandMctsAction(move),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, worker],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 6, row: 4),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.recover,
            settlerAssignments: const {'settler_1': CityHex(col: 3, row: 2)},
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(move));
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes endangered settler retreat moves', () {
      final mapData = _squareMap(cols: 8, rows: 5);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 4,
        row: 2,
      );
      final enemy = GameUnit(
        id: 'enemy_warrior',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 3,
        row: 2,
      );
      const retreat = MoveUnitCommand('settler_1', 7, 2);
      const unsafeMove = MoveUnitCommand('settler_1', 3, 1);
      const building = StartBuildingCommand('capital', CityBuildingType.walls);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(building),
            CommandMctsAction(unsafeMove),
            CommandMctsAction(retreat),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, enemy],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 7, row: 4),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.recover),
        ),
      );

      expect(actions.first, const CommandMctsAction(retreat));
      expect(_commands(actions), isNot(contains(unsafeMove)));
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes crowded settler reveal moves', () {
      final mapData = _squareMap(cols: 9, rows: 9);
      final visibleHexes = {
        const HexCoordinate(col: 6, row: 1),
        const HexCoordinate(col: 8, row: 1),
        const HexCoordinate(col: 8, row: 3),
        const HexCoordinate(col: 7, row: 1),
        const HexCoordinate(col: 8, row: 0),
        const HexCoordinate(col: 8, row: 2),
      };
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 8,
        row: 1,
      );
      const revealMove = MoveUnitCommand('settler_1', 4, 3);
      const building = StartBuildingCommand('capital', CityBuildingType.walls);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(building),
            CommandMctsAction(revealMove),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 6, row: 1),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 8, row: 3),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
            fogOfWar: _fogForHexes(_playerId, visibleHexes),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.recover),
        ),
      );

      expect(actions.first, const CommandMctsAction(revealMove));
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes scout-led third-city site discovery', () {
      final mapData = _squareMap(cols: 8, rows: 8);
      final visibleHexes = {
        for (final tile in mapData.tiles)
          if (HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 0, row: 0),
                  ) <=
                  2 ||
              HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 7, row: 0),
                  ) <=
                  2 ||
              HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 3, row: 2),
                  ) <=
                  2)
            HexCoordinate.fromTile(tile),
      };
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 1,
        row: 0,
      );
      final scout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.scout,
        name: 'Scout',
        col: 3,
        row: 2,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      const scoutMove = MoveUnitCommand('scout_1', 4, 4);
      const fortify = FortifyUnitCommand('warrior_1');
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(fortify),
            CommandMctsAction(scoutMove),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, scout, warrior],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 7, row: 0),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
            fogOfWar: _fogForHexes(_playerId, visibleHexes),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.recover),
        ),
      );

      expect(_commands(actions).first, scoutMove);
      expect(actions.last, const EndPlanningAction());
    });

    test(
      'uses surplus military for city-site discovery when no scout exists',
      () {
        final mapData = _squareMap(cols: 8, rows: 8);
        final visibleHexes = {
          for (final tile in mapData.tiles)
            if (HexDistance.between(
                      HexCoordinate.fromTile(tile),
                      const HexCoordinate(col: 0, row: 0),
                    ) <=
                    2 ||
                HexDistance.between(
                      HexCoordinate.fromTile(tile),
                      const HexCoordinate(col: 7, row: 0),
                    ) <=
                    2 ||
                HexDistance.between(
                      HexCoordinate.fromTile(tile),
                      const HexCoordinate(col: 3, row: 2),
                    ) <=
                    2)
              HexCoordinate.fromTile(tile),
        };
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.settler,
          name: 'Settler',
          col: 1,
          row: 0,
        );
        final warrior = GameUnit(
          id: 'warrior_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 3,
          row: 2,
        );
        final reserve = GameUnit(
          id: 'warrior_2',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ).copyWithHitPoints(7);
        const scoutMove = MoveUnitCommand('warrior_1', 4, 4);
        const fortify = FortifyUnitCommand('warrior_2');
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(fortify),
              CommandMctsAction(scoutMove),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 1,
        );

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              mapData: mapData,
              units: [settler, warrior, reserve],
              cities: const [
                GameCity(
                  id: 'capital',
                  ownerPlayerId: _playerId,
                  name: 'Capital',
                  center: CityHex(col: 0, row: 0),
                ),
                GameCity(
                  id: 'second',
                  ownerPlayerId: _playerId,
                  name: 'Second',
                  center: CityHex(col: 7, row: 0),
                ),
              ],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
              fogOfWar: _fogForHexes(_playerId, visibleHexes),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            mapData: mapData,
            strategicPlan: _strategicPlan(mode: StrategicMode.recover),
          ),
        );

        expect(_commands(actions).first, scoutMove);
        expect(actions.last, const EndPlanningAction());
      },
    );

    test(
      'prioritizes unassigned settler frontier moves once core defense is covered',
      () {
        final mapData = _squareMap(cols: 6, rows: 5);
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.settler,
          name: 'Settler',
          col: 1,
          row: 0,
        );
        final garrison = GameUnit(
          id: 'warrior_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        );
        final reserve1 = GameUnit(
          id: 'warrior_2',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 5,
          row: 0,
        );
        final reserve2 = GameUnit(
          id: 'warrior_3',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 5,
          row: 1,
        );
        const frontierMove = MoveUnitCommand('settler_1', 3, 4);
        const fortify = FortifyUnitCommand('warrior_1');
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(fortify),
              CommandMctsAction(frontierMove),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 1,
        );

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              mapData: mapData,
              units: [settler, garrison, reserve1, reserve2],
              cities: const [
                GameCity(
                  id: 'capital',
                  ownerPlayerId: _playerId,
                  name: 'Capital',
                  center: CityHex(col: 0, row: 0),
                ),
                GameCity(
                  id: 'second',
                  ownerPlayerId: _playerId,
                  name: 'Second',
                  center: CityHex(col: 5, row: 0),
                ),
              ],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            mapData: mapData,
            strategicPlan: _strategicPlan(
              mode: StrategicMode.consolidate,
              defenses: {
                'capital': StrategicDefenseAssignment(
                  cityId: 'capital',
                  cityCenter: const CityHex(col: 0, row: 0),
                  threatLevel: 0,
                  assignedUnitIds: const ['warrior_1'],
                ),
              },
            ),
          ),
        );

        expect(actions.first, const CommandMctsAction(frontierMove));
        expect(actions.last, const EndPlanningAction());
      },
    );

    test(
      'prioritizes incremental settler spacing moves before routine city projects',
      () {
        final mapData = _squareMap(cols: 5, rows: 5);
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.settler,
          name: 'Settler',
          col: 0,
          row: 1,
        );
        const spacingMove = MoveUnitCommand('settler_1', 0, 2);
        const project = StartCityProjectCommand(
          'capital',
          CityProjectType.wealth,
        );
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(project),
              CommandMctsAction(spacingMove),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 1,
        );

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              mapData: mapData,
              units: [settler],
              cities: const [
                GameCity(
                  id: 'capital',
                  ownerPlayerId: _playerId,
                  name: 'Capital',
                  center: CityHex(col: 0, row: 0),
                ),
                GameCity(
                  id: 'second',
                  ownerPlayerId: _playerId,
                  name: 'Second',
                  center: CityHex(col: 4, row: 4),
                ),
              ],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            mapData: mapData,
            strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
          ),
        );

        expect(_commands(actions), const [spacingMove]);
        expect(actions.last, const EndPlanningAction());
      },
    );

    test(
      'does not prioritize crowded settler spacing once three cities exist',
      () {
        final mapData = _squareMap(cols: 6, rows: 6);
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.settler,
          name: 'Settler',
          col: 0,
          row: 1,
        );
        const crowdedMove = MoveUnitCommand('settler_1', 0, 2);
        const project = StartCityProjectCommand(
          'capital',
          CityProjectType.wealth,
        );
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(crowdedMove),
              CommandMctsAction(project),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 1,
        );

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              mapData: mapData,
              units: [settler],
              cities: const [
                GameCity(
                  id: 'capital',
                  ownerPlayerId: _playerId,
                  name: 'Capital',
                  center: CityHex(col: 0, row: 0),
                ),
                GameCity(
                  id: 'second',
                  ownerPlayerId: _playerId,
                  name: 'Second',
                  center: CityHex(col: 4, row: 4),
                ),
                GameCity(
                  id: 'third',
                  ownerPlayerId: _playerId,
                  name: 'Third',
                  center: CityHex(col: 5, row: 0),
                ),
              ],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            mapData: mapData,
            strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
          ),
        );

        expect(_commands(actions), const [project]);
        expect(actions.last, const EndPlanningAction());
      },
    );

    test('prioritizes assigned frontier clearing attacks', () {
      final mapData = _squareMap(cols: 8, rows: 8);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 4,
        row: 5,
      );
      final clearer = GameUnit(
        id: 'warrior_clearer',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 3,
        row: 4,
      );
      final reserve = GameUnit(
        id: 'warrior_reserve',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final blocker = GameUnit(
        id: 'blocker',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 4,
        row: 4,
      );
      const clearingAttack = AttackHexCommand('warrior_clearer', 4, 4);
      const fortify = FortifyUnitCommand('warrior_reserve');
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(fortify),
            CommandMctsAction(clearingAttack),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, clearer, reserve, blocker],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 7, row: 0),
              ),
            ],
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.expand,
            frontierClearingAssignments: const {
              'warrior_clearer': StrategicFrontierClearingAssignment(
                unitId: 'warrior_clearer',
                founderId: 'settler_1',
                targetPlayerId: 'player_2',
                targetHex: HexCoordinate(col: 4, row: 4),
                founderDistance: 1,
                priority: 4.5,
              ),
            },
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(clearingAttack));
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes attacks that relieve unassigned settler pressure', () {
      final mapData = _squareMap(cols: 8, rows: 8);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 4,
        row: 5,
      );
      final clearer = GameUnit(
        id: 'warrior_clearer',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 3,
        row: 5,
      );
      final reserve = GameUnit(
        id: 'warrior_reserve',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final blocker = GameUnit(
        id: 'blocker',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 4,
        row: 6,
      );
      const pressureAttack = AttackHexCommand('warrior_clearer', 4, 6);
      const fortify = FortifyUnitCommand('warrior_reserve');
      const building = StartBuildingCommand(
        'capital',
        CityBuildingType.granary,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(building),
            CommandMctsAction(fortify),
            CommandMctsAction(pressureAttack),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, clearer, reserve, blocker],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
            ],
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.recover),
        ),
      );

      expect(actions.first, const CommandMctsAction(pressureAttack));
      expect(actions.last, const EndPlanningAction());
    });

    test('keeps escorted unassigned settler frontier moves under pressure', () {
      final mapData = _squareMap(cols: 6, rows: 5);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 1,
        row: 0,
      );
      final escort = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 2,
        row: 4,
      );
      final garrison = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 5,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 5,
        row: 4,
      );
      const frontierMove = MoveUnitCommand('settler_1', 3, 4);
      const barracks = StartBuildingCommand(
        'capital',
        CityBuildingType.barracks,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(barracks),
            CommandMctsAction(frontierMove),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, escort, garrison, enemy],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 5, row: 0),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
        ),
      );

      expect(actions.first, const CommandMctsAction(frontierMove));
      expect(actions.last, const EndPlanningAction());
    });

    test('drops unescorted settler frontier moves into enemy threat', () {
      final mapData = _squareMap(cols: 6, rows: 5);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 1,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 3,
        row: 1,
      );
      const frontierMove = MoveUnitCommand('settler_1', 2, 1);
      const barracks = StartBuildingCommand(
        'capital',
        CityBuildingType.barracks,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(frontierMove),
            CommandMctsAction(barracks),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [settler, enemy],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: _playerId,
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: _playerId,
                name: 'Second',
                center: CityHex(col: 4, row: 0),
              ),
            ],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
        ),
      );

      expect(_commands(actions), isNot(contains(frontierMove)));
      expect(_commands(actions).single, isA<StartBuildingCommand>());
      expect(actions.last, const EndPlanningAction());
    });

    test(
      'drops third-city settler moves that outrun origin cover near threat',
      () {
        final mapData = _squareMap(cols: 6, rows: 5);
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.settler,
          name: 'Settler',
          col: 1,
          row: 0,
        );
        final originEscort = GameUnit(
          id: 'warrior_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 1,
          row: 1,
        );
        final enemy = GameUnit(
          id: 'enemy_1',
          ownerPlayerId: _enemyId,
          type: GameUnitType.warrior,
          name: 'Enemy',
          col: 5,
          row: 4,
        );
        const frontierMove = MoveUnitCommand('settler_1', 2, 4);
        const fallback = StartBuildingCommand(
          'capital',
          CityBuildingType.barracks,
        );
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(frontierMove),
              CommandMctsAction(fallback),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 1,
        );

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              mapData: mapData,
              units: [settler, originEscort, enemy],
              cities: const [
                GameCity(
                  id: 'capital',
                  ownerPlayerId: _playerId,
                  name: 'Capital',
                  center: CityHex(col: 0, row: 0),
                ),
                GameCity(
                  id: 'second',
                  ownerPlayerId: _playerId,
                  name: 'Second',
                  center: CityHex(col: 5, row: 0),
                ),
              ],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            mapData: mapData,
            strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
          ),
        );

        expect(_commands(actions), isNot(contains(frontierMove)));
        expect(_commands(actions).single, fallback);
        expect(actions.last, const EndPlanningAction());
      },
    );

    test(
      'drops one-city settler moves into remembered enemy city pressure',
      () {
        final mapData = _squareMap(cols: 8, rows: 7);
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.settler,
          name: 'Settler',
          col: 4,
          row: 1,
        );
        const unsafeMove = MoveUnitCommand('settler_1', 6, 4);
        const fallback = StartBuildingCommand(
          'capital',
          CityBuildingType.walls,
        );
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(unsafeMove),
              CommandMctsAction(fallback),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 2,
        );

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              mapData: mapData,
              units: [settler],
              cities: const [
                GameCity(
                  id: 'capital',
                  ownerPlayerId: _playerId,
                  name: 'Capital',
                  center: CityHex(col: 4, row: 0),
                ),
                GameCity(
                  id: 'enemy_city',
                  ownerPlayerId: _enemyId,
                  name: 'Enemy City',
                  center: CityHex(col: 6, row: 5),
                  controlledHexes: [CityHex(col: 6, row: 4)],
                ),
              ],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            mapData: mapData,
            strategicPlan: _strategicPlan(mode: StrategicMode.expand),
          ),
        );

        expect(_commands(actions), isNot(contains(unsafeMove)));
        expect(actions.last, const EndPlanningAction());
      },
    );

    test('prioritizes first city founding over active war goals', () {
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 0,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 1,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 1,
        row: 1,
      );
      const found = FoundCityCommand(
        'settler_1',
        controlledHexes: [CityHex(col: 0, row: 1), CityHex(col: 1, row: 0)],
      );
      const attack = AttackHexCommand('warrior_1', 1, 1);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(attack),
            CommandMctsAction(found),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [settler, warrior, enemy],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            warGoals: [
              WarGoal(
                targetPlayerId: _enemyId,
                kind: WarGoalKind.eliminateUnits,
                targetHex: const HexCoordinate(col: 1, row: 1),
                turnsBudget: 3,
                assignedUnitIds: const ['warrior_1'],
                priority: 0.9,
              ),
            ],
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(found));
      expect(actions.last, const EndPlanningAction());
    });

    test('moves the first settler when the opening plan has a better site', () {
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 0,
      );
      const found = FoundCityCommand(
        'settler_1',
        controlledHexes: [CityHex(col: 0, row: 1), CityHex(col: 1, row: 0)],
      );
      const move = MoveUnitCommand('settler_1', 1, 0);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(found),
            CommandMctsAction(move),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [settler],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          strategicPlan: _strategicPlan(
            mode: StrategicMode.expand,
            settlerAssignments: const {'settler_1': CityHex(col: 1, row: 0)},
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(move));
      expect(actions.last, const EndPlanningAction());
    });

    test('keeps first settler movement ahead of distant attacks', () {
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 0,
        row: 0,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 1,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 2,
        row: 1,
      );
      const move = MoveUnitCommand('settler_1', 1, 0);
      const attack = AttackHexCommand('warrior_1', 2, 1);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(attack),
            CommandMctsAction(move),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [settler, warrior, enemy],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            settlerAssignments: const {'settler_1': CityHex(col: 2, row: 0)},
            warGoals: [
              WarGoal(
                targetPlayerId: _enemyId,
                kind: WarGoalKind.eliminateUnits,
                targetHex: const HexCoordinate(col: 2, row: 1),
                turnsBudget: 3,
                assignedUnitIds: const ['warrior_1'],
                priority: 0.9,
              ),
            ],
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(move));
      expect(actions.last, const EndPlanningAction());
    });

    test(
      'does not move a post-step founding command ahead of its movement',
      () {
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.settler,
          name: 'Settler',
          col: 0,
          row: 0,
        );
        const move = MoveUnitCommand('settler_1', 1, 0);
        const foundAfterMove = FoundCityCommand(
          'settler_1',
          controlledHexes: [CityHex(col: 2, row: 0), CityHex(col: 2, row: 1)],
        );
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(foundAfterMove),
              CommandMctsAction(move),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 1,
        );

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              units: [settler],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            strategicPlan: _strategicPlan(
              mode: StrategicMode.expand,
              settlerAssignments: const {'settler_1': CityHex(col: 1, row: 0)},
            ),
          ),
        );

        expect(actions.first, const CommandMctsAction(move));
        expect(actions.last, const EndPlanningAction());
      },
    );

    test('drops stale no-op and occupied move candidates', () {
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.worker,
        name: 'Worker',
        col: 1,
        row: 0,
      );
      const currentTile = MoveUnitCommand('warrior_1', 0, 0);
      const occupiedTile = MoveUnitCommand('warrior_1', 1, 0);
      const legalMove = MoveUnitCommand('warrior_1', 0, 1);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(currentTile),
            CommandMctsAction(occupiedTile),
            CommandMctsAction(legalMove),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(units: [warrior, worker]),
          maxPlanningDepth: 3,
        ),
        _context(strategicPlan: _strategicPlan()),
      );

      expect(_commands(actions), const [legalMove]);
      expect(actions.last, const EndPlanningAction());
    });

    test(
      'keeps protective attacks near the first settler in the opening pool',
      () {
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.settler,
          name: 'Settler',
          col: 0,
          row: 0,
        );
        final warrior = GameUnit(
          id: 'warrior_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 1,
        );
        final enemy = GameUnit(
          id: 'enemy_1',
          ownerPlayerId: _enemyId,
          type: GameUnitType.warrior,
          name: 'Enemy',
          col: 1,
          row: 0,
          hitPoints: 1,
        );
        const found = FoundCityCommand(
          'settler_1',
          controlledHexes: [CityHex(col: 0, row: 1), CityHex(col: 1, row: 0)],
        );
        const attack = AttackHexCommand('warrior_1', 1, 0);
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(attack),
              CommandMctsAction(found),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 2,
        );

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              units: [settler, warrior, enemy],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            strategicPlan: _strategicPlan(
              mode: StrategicMode.military,
              warGoals: [
                WarGoal(
                  targetPlayerId: _enemyId,
                  kind: WarGoalKind.eliminateUnits,
                  targetHex: const HexCoordinate(col: 1, row: 0),
                  turnsBudget: 3,
                  assignedUnitIds: const ['warrior_1'],
                  priority: 0.9,
                ),
              ],
            ),
          ),
        );

        expect(_commands(actions), const [attack, found]);
        expect(actions.last, const EndPlanningAction());
      },
    );

    test(
      'prioritizes defender production for threatened ungarrisoned cities',
      () {
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: _playerId,
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
          population: 3,
        );
        const defender = StartUnitProductionCommand(
          'city_1',
          GameUnitType.warrior,
        );
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(
                StartBuildingCommand('city_1', CityBuildingType.granary),
              ),
              CommandMctsAction(defender),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 2,
        );

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              cities: const [city],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            strategicPlan: _strategicPlan(
              defenses: {
                'city_1': StrategicDefenseAssignment(
                  cityId: 'city_1',
                  cityCenter: const CityHex(col: 0, row: 0),
                  threatLevel: 2,
                  assignedUnitIds: const [],
                  primaryThreatPlayerId: _enemyId,
                ),
              },
            ),
          ),
        );

        expect(actions.first, const CommandMctsAction(defender));
        expect(actions.last, const EndPlanningAction());
      },
    );

    test('prioritizes only-city protection over distant war attacks', () {
      final mapData = MapData(
        cols: 5,
        rows: 3,
        tiles: [
          for (var col = 0; col < 5; col++)
            for (var row = 0; row < 3; row++)
              TileData(
                col: col,
                row: row,
                terrains: const [TerrainType.plains],
                resources: const [],
                height: 0,
              ),
        ],
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 3,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final cityThreat = GameUnit(
        id: 'enemy_near',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy Near',
        col: 1,
        row: 0,
        hitPoints: 1,
      );
      final distantEnemy = GameUnit(
        id: 'enemy_far',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy Far',
        col: 4,
        row: 2,
      );
      const protectCity = AttackHexCommand('warrior_1', 1, 0);
      const raid = AttackHexCommand('warrior_1', 4, 2);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(raid),
            CommandMctsAction(protectCity),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior, cityThreat, distantEnemy],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 8,
                assignedUnitIds: const ['warrior_1'],
                primaryThreatPlayerId: _enemyId,
              ),
            },
            warGoals: [
              WarGoal(
                targetPlayerId: _enemyId,
                kind: WarGoalKind.eliminateUnits,
                targetHex: const HexCoordinate(col: 4, row: 2),
                turnsBudget: 3,
                assignedUnitIds: const ['warrior_1'],
                priority: 0.9,
              ),
            ],
          ),
        ),
      );

      expect(actions.first, const CommandMctsAction(protectCity));
      expect(actions.last, const EndPlanningAction());
    });

    test('drops raids by the last military unit away from owned cities', () {
      final mapData = MapData(
        cols: 5,
        rows: 1,
        tiles: [
          for (var col = 0; col < 5; col++)
            TileData(
              col: col,
              row: 0,
              terrains: const [TerrainType.plains],
              resources: const [],
              height: 0,
            ),
        ],
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 3,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 3,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_far',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy Far',
        col: 4,
        row: 0,
      );
      const raid = AttackHexCommand('warrior_1', 4, 0);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [CommandMctsAction(raid), EndPlanningAction()],
        ),
        candidateLimit: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior, enemy],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.military),
        ),
      );

      expect(_commands(actions), isEmpty);
      expect(actions, const [EndPlanningAction()]);
    });

    test('drops low-impact attacks by the last military unit', () {
      final mapData = _lineMap(3);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 3,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_near',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy Near',
        col: 2,
        row: 0,
      );
      const attack = AttackHexCommand('warrior_1', 2, 0);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [CommandMctsAction(attack), EndPlanningAction()],
        ),
        candidateLimit: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior, enemy],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.military),
        ),
      );

      expect(_commands(actions), isEmpty);
      expect(actions, const [EndPlanningAction()]);
    });

    test('keeps finishing attacks by the last military unit', () {
      final mapData = _lineMap(3);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 3,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_near',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy Near',
        col: 2,
        row: 0,
        hitPoints: 1,
      );
      const attack = AttackHexCommand('warrior_1', 2, 0);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [CommandMctsAction(attack), EndPlanningAction()],
        ),
        candidateLimit: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior, enemy],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.military),
        ),
      );

      expect(_commands(actions), const [attack]);
      expect(actions.last, const EndPlanningAction());
    });

    test('drops distant raids by a reserved city garrison', () {
      final mapData = _squareMap(cols: 6, rows: 2);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 3,
      );
      final homeGuard = GameUnit(
        id: 'home_guard',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Home Guard',
        col: 0,
        row: 0,
      );
      final raider = GameUnit(
        id: 'raider',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Raider',
        col: 2,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_far',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy Far',
        col: 3,
        row: 0,
        hitPoints: 1,
      );
      const homeRaid = AttackHexCommand('home_guard', 3, 0);
      const raiderAttack = AttackHexCommand('raider', 3, 0);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(homeRaid),
            CommandMctsAction(raiderAttack),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 3,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [homeGuard, raider, enemy],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 0,
                assignedUnitIds: const ['home_guard'],
                primaryThreatPlayerId: '',
              ),
            },
          ),
        ),
      );

      expect(_commands(actions), contains(raiderAttack));
      expect(_commands(actions), isNot(contains(homeRaid)));
    });

    test('keeps calm baseline garrisons from chasing perimeter attacks', () {
      final mapData = _squareMap(cols: 4, rows: 2);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 3,
      );
      final homeGuard = GameUnit(
        id: 'home_guard',
        ownerPlayerId: _playerId,
        type: GameUnitType.archer,
        name: 'Home Guard',
        col: 0,
        row: 0,
      );
      final enemy = GameUnit(
        id: 'enemy_perimeter',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy Perimeter',
        col: 2,
        row: 0,
      );
      const perimeterShot = AttackHexCommand('home_guard', 2, 0);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [CommandMctsAction(perimeterShot), EndPlanningAction()],
        ),
        candidateLimit: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [homeGuard, enemy],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.consolidate,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 0,
                assignedUnitIds: const ['home_guard'],
                primaryThreatPlayerId: '',
              ),
            },
          ),
        ),
      );

      expect(_commands(actions), isNot(contains(perimeterShot)));
    });

    test('prioritizes rebuilding a reserve defender before projects', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 3,
      );
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(
              StartCityProjectCommand('city_1', CityProjectType.wealth),
            ),
            CommandMctsAction(defender),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(strategicPlan: _strategicPlan()),
      );

      expect(actions.first, const CommandMctsAction(defender));
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes settlers over spare defenders during safe expansion', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 1,
      );
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(
              StartCityProjectCommand('city_1', CityProjectType.wealth),
            ),
            CommandMctsAction(defender),
            CommandMctsAction(settler),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, worker],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(strategicPlan: _strategicPlan(mode: StrategicMode.expand)),
      );

      expect(actions.first, const CommandMctsAction(settler));
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes safe second-city settlers over first workers', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final warrior2 = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 0,
      );
      const worker = StartUnitProductionCommand('city_1', GameUnitType.worker);
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(worker),
            CommandMctsAction(settler),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, warrior2],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(strategicPlan: _strategicPlan(mode: StrategicMode.expand)),
      );

      expect(_commands(actions), const [settler]);
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes escort production for an exposed active settler', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      final garrison = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final activeSettler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 5,
        row: 2,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 6,
        row: 2,
      );
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(settler),
            CommandMctsAction(defender),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );
      final mapData = _squareMap(cols: 8, rows: 5);

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [garrison, activeSettler, enemy],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.expand),
        ),
      );

      expect(_commands(actions), const [defender]);
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes worker recovery before chaining settlers', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final activeSettler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 1,
        row: 0,
      );
      const worker = StartUnitProductionCommand('city_1', GameUnitType.worker);
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(settler),
            CommandMctsAction(worker),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, activeSettler],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(strategicPlan: _strategicPlan(mode: StrategicMode.military)),
      );

      expect(_commands(actions), const [worker]);
      expect(actions.last, const EndPlanningAction());
    });

    test('defers german opening settler until reserve defense exists', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      const worker = StartUnitProductionCommand('city_1', GameUnitType.worker);
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(worker),
            CommandMctsAction(defender),
            CommandMctsAction(settler),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );
      final mapData = _squareMap(cols: 8, rows: 8);
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [warrior],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
          civProfile: profile,
        ),
      );

      expect(_commands(actions), const [defender]);
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes second-city settlers in unthreatened military plans', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final warrior2 = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 0,
      );
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 1,
      );
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const project = StartCityProjectCommand('city_1', CityProjectType.wealth);
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(project),
            CommandMctsAction(defender),
            CommandMctsAction(settler),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior, warrior2, worker],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(strategicPlan: _strategicPlan(mode: StrategicMode.military)),
      );
      final commands = _commands(actions);

      expect(commands, const [settler]);
      expect(commands, isNot(contains(defender)));
      expect(commands, isNot(contains(project)));
      expect(actions.last, const EndPlanningAction());
    });

    test('keeps pinned garrison in a threatened city over settler escort', () {
      final mapData = _squareMap(cols: 5, rows: 5);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 1, row: 1),
        population: 4,
      );
      final garrison = GameUnit(
        id: 'garrison_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 1,
      ).copyWithHitPoints(7);
      final settler = GameUnit(
        id: 'settler_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.settler,
        name: 'Settler',
        col: 3,
        row: 1,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 3,
        row: 2,
      );
      const escortMove = MoveUnitCommand('garrison_1', 2, 1);
      const fortify = FortifyUnitCommand('garrison_1');
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(escortMove),
            CommandMctsAction(fortify),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [garrison, settler, enemy],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            settlerAssignments: const {'settler_1': CityHex(col: 4, row: 1)},
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 1, row: 1),
                threatLevel: 4,
                assignedUnitIds: const ['garrison_1'],
                primaryThreatPlayerId: _enemyId,
              ),
            },
          ),
        ),
      );

      expect(_commands(actions), const [fortify]);
      expect(_commands(actions), isNot(contains(escortMove)));
      expect(actions.last, const EndPlanningAction());
    });

    test('prefers a second-city settler after local defense is covered', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      final warrior1 = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final warrior2 = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 0,
      );
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 1,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 1,
        row: 1,
      );
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(defender),
            CommandMctsAction(settler),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            units: [warrior1, warrior2, worker, enemy],
            cities: const [city],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 4,
                assignedUnitIds: const ['warrior_1'],
                primaryThreatPlayerId: _enemyId,
              ),
            },
          ),
        ),
      );

      expect(_commands(actions), const [settler]);
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes third-city settlers once two cities are covered', () {
      const capital = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      const frontier = GameCity(
        id: 'city_2',
        ownerPlayerId: _playerId,
        name: 'Frontier',
        center: CityHex(col: 5, row: 5),
        population: 3,
      );
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.worker,
        name: 'Worker',
        col: 0,
        row: 1,
      );
      final capitalGuard = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final frontierGuard = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 5,
        row: 4,
      );
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(defender),
            CommandMctsAction(
              StartCityProjectCommand('city_1', CityProjectType.research),
            ),
            CommandMctsAction(settler),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );
      final mapData = _squareMap(cols: 8, rows: 8);
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [worker, capitalGuard, frontierGuard],
            cities: const [capital, frontier],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          civProfile: profile,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 0,
                assignedUnitIds: const ['warrior_1'],
              ),
              'city_2': StrategicDefenseAssignment(
                cityId: 'city_2',
                cityCenter: const CityHex(col: 5, row: 5),
                threatLevel: 0,
                assignedUnitIds: const ['warrior_2'],
              ),
            },
          ),
        ),
      );

      expect(_commands(actions), const [settler]);
      expect(actions.last, const EndPlanningAction());
    });

    test('prioritizes reserve defenders for a pressured two-city core', () {
      const capital = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      const frontier = GameCity(
        id: 'city_2',
        ownerPlayerId: _playerId,
        name: 'Frontier',
        center: CityHex(col: 5, row: 5),
        population: 3,
      );
      final capitalGuard = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final frontierGuard = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 5,
        row: 5,
      );
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 1,
        row: 0,
      );
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(settler),
            CommandMctsAction(defender),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );
      final mapData = _squareMap(cols: 8, rows: 8);
      final profile = CivilizationProfiles.all[PlayerCountry.netherlands]!;

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [capitalGuard, frontierGuard, enemy],
            cities: const [capital, frontier],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          civProfile: profile,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.consolidate,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 8,
                assignedUnitIds: const ['warrior_1'],
                primaryThreatPlayerId: _enemyId,
              ),
              'city_2': StrategicDefenseAssignment(
                cityId: 'city_2',
                cityCenter: const CityHex(col: 5, row: 5),
                threatLevel: 0,
                assignedUnitIds: const ['warrior_2'],
              ),
            },
          ),
        ),
      );

      expect(_commands(actions), const [defender]);
      expect(actions.last, const EndPlanningAction());
    });

    test('allows third-city settlers with minimal calm city coverage', () {
      const capital = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      const frontier = GameCity(
        id: 'city_2',
        ownerPlayerId: _playerId,
        name: 'Frontier',
        center: CityHex(col: 5, row: 5),
        population: 3,
      );
      final capitalGuard = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final frontierGuard = GameUnit(
        id: 'warrior_2',
        ownerPlayerId: _playerId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 5,
        row: 4,
      );
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(defender),
            CommandMctsAction(
              StartCityProjectCommand('city_1', CityProjectType.research),
            ),
            CommandMctsAction(settler),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );
      final mapData = _squareMap(cols: 8, rows: 8);
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [capitalGuard, frontierGuard],
            cities: const [capital, frontier],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          civProfile: profile,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 0,
                assignedUnitIds: const [],
              ),
              'city_2': StrategicDefenseAssignment(
                cityId: 'city_2',
                cityCenter: const CityHex(col: 5, row: 5),
                threatLevel: 0,
                assignedUnitIds: const [],
              ),
            },
          ),
        ),
      );

      expect(_commands(actions), const [settler]);
      expect(actions.last, const EndPlanningAction());
    });

    test(
      'moves active third-city settlers before low-priority war marches',
      () {
        const capital = GameCity(
          id: 'city_1',
          ownerPlayerId: _playerId,
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
          population: 4,
        );
        const frontier = GameCity(
          id: 'city_2',
          ownerPlayerId: _playerId,
          name: 'Frontier',
          center: CityHex(col: 7, row: 7),
          population: 3,
        );
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.settler,
          name: 'Settler',
          col: 2,
          row: 2,
        );
        final warrior = GameUnit(
          id: 'warrior_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        );
        const settlerMove = MoveUnitCommand('settler_1', 3, 2);
        const warMove = MoveUnitCommand('warrior_1', 1, 0);
        const generator = StrategyAwareMctsActionGenerator(
          inner: _StaticActionGenerator(
            actions: [
              CommandMctsAction(warMove),
              CommandMctsAction(settlerMove),
              EndPlanningAction(),
            ],
          ),
          candidateLimit: 1,
        );
        final mapData = _squareMap(cols: 8, rows: 8);
        final profile = CivilizationProfiles.all[PlayerCountry.france]!;

        final actions = generator.candidatesFor(
          SimulatedState.fromView(
            _view(
              mapData: mapData,
              units: [settler, warrior],
              cities: const [capital, frontier],
              research: PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            ),
            maxPlanningDepth: 3,
          ),
          _context(
            mapData: mapData,
            civProfile: profile,
            strategicPlan: _strategicPlan(
              mode: StrategicMode.military,
              warGoals: [
                WarGoal(
                  targetPlayerId: _enemyId,
                  kind: WarGoalKind.eliminateUnits,
                  targetHex: const HexCoordinate(col: 4, row: 0),
                  turnsBudget: 4,
                  assignedUnitIds: const ['warrior_1'],
                  priority: 0.2,
                ),
              ],
            ),
          ),
        );

        expect(_commands(actions), const [settlerMove]);
        expect(actions.last, const EndPlanningAction());
      },
    );

    test('allows escorted third-city settlers during light city pressure', () {
      const capital = GameCity(
        id: 'city_1',
        ownerPlayerId: _playerId,
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        population: 4,
      );
      const frontier = GameCity(
        id: 'city_2',
        ownerPlayerId: _playerId,
        name: 'Frontier',
        center: CityHex(col: 5, row: 5),
        population: 3,
      );
      final guards = [
        for (var i = 1; i <= 3; i++)
          GameUnit(
            id: 'warrior_$i',
            ownerPlayerId: _playerId,
            type: GameUnitType.warrior,
            name: 'Warrior',
            col: i <= 2 ? 0 : 5,
            row: i,
          ),
      ];
      final enemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: _enemyId,
        type: GameUnitType.warrior,
        name: 'Enemy',
        col: 1,
        row: 0,
      );
      const settler = StartUnitProductionCommand(
        'city_1',
        GameUnitType.settler,
      );
      const defender = StartUnitProductionCommand(
        'city_1',
        GameUnitType.warrior,
      );
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(defender),
            CommandMctsAction(settler),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 1,
      );
      final mapData = _squareMap(cols: 8, rows: 8);
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            mapData: mapData,
            units: [...guards, enemy],
            cities: const [capital, frontier],
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(
          mapData: mapData,
          civProfile: profile,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.military,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 2,
                assignedUnitIds: const ['warrior_1'],
                primaryThreatPlayerId: _enemyId,
              ),
              'city_2': StrategicDefenseAssignment(
                cityId: 'city_2',
                cityCenter: const CityHex(col: 5, row: 5),
                threatLevel: 0,
                assignedUnitIds: const ['warrior_3'],
              ),
            },
          ),
        ),
      );

      expect(_commands(actions), const [settler]);
      expect(actions.last, const EndPlanningAction());
    });

    test('keeps end planning last and respects candidate limit', () {
      const generator = StrategyAwareMctsActionGenerator(
        inner: _StaticActionGenerator(
          actions: [
            CommandMctsAction(
              StartCityProjectCommand('city_1', CityProjectType.wealth),
            ),
            CommandMctsAction(
              StartCityProjectCommand('city_2', CityProjectType.wealth),
            ),
            CommandMctsAction(
              StartCityProjectCommand('city_3', CityProjectType.wealth),
            ),
            EndPlanningAction(),
          ],
        ),
        candidateLimit: 2,
      );

      final actions = generator.candidatesFor(
        SimulatedState.fromView(
          _view(
            research: PlayerResearchState(
              activeTechnologyId: TechnologyId.agriculture,
            ),
          ),
          maxPlanningDepth: 3,
        ),
        _context(strategicPlan: _strategicPlan()),
      );

      expect(_commands(actions), hasLength(2));
      expect(actions, hasLength(3));
      expect(actions.last, const EndPlanningAction());
    });
  });
}

class _StaticStrategy implements AiStrategy {
  final List<GameCommand> commands;

  const _StaticStrategy({required this.commands});

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    return AiTurnPlan(commands: commands);
  }
}

class _CountingStrategy implements AiStrategy {
  final List<GameCommand> commands;
  int calls = 0;

  _CountingStrategy({required this.commands});

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    calls += 1;
    return AiTurnPlan(commands: commands);
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

List<GameCommand> _commands(List<MctsAction> actions) {
  return actions
      .map((action) => action.toCommand())
      .whereType<GameCommand>()
      .toList();
}

AiContext _context({
  MapData? mapData,
  StrategicPlan? strategicPlan,
  CivilizationProfile civProfile = CivilizationProfiles.poland,
}) {
  final actualMapData = mapData ?? _mapData();
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: actualMapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: _playerId, baseSeed: 7),
    strategicPlan: strategicPlan,
    persona: civProfile.defaultPersona,
    civProfile: civProfile,
  );
}

StrategicPlan _strategicPlan({
  StrategicMode mode = StrategicMode.consolidate,
  List<WarGoal> warGoals = const [],
  Map<String, CityHex> settlerAssignments = const {},
  Map<String, StrategicFrontierClearingAssignment> frontierClearingAssignments =
      const {},
  Map<String, StrategicDefenseAssignment> defenses = const {},
}) {
  return StrategicPlan(
    computedAtTurn: 1,
    mode: mode,
    expectations: const EconomyExpectations(
      expectedCityCount: 1,
      expectedWorkerCount: 1,
      expectedMilitaryCount: 1,
      goldReserveTarget: 8,
      minimumSciencePerTurn: 2,
    ),
    warGoals: warGoals,
    settlerAssignments: settlerAssignments,
    frontierClearingAssignments: frontierClearingAssignments,
    defenses: defenses,
  );
}

GameView _view({
  MapData? mapData,
  PlayerResearchState? research,
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  List<FieldImprovement> fieldImprovements = const [],
  DiplomacyState diplomacy = DiplomacyState.empty,
  FogOfWarState? fogOfWar,
  bool ignoreFogOfWar = false,
}) {
  final actualMapData = mapData ?? _mapData();
  final researchState = research == null
      ? ResearchState.empty
      : ResearchState(players: {_playerId: research});
  return GameView.fromPersistentState(
    PersistentGameState(
      units: units,
      cities: cities,
      fieldImprovements: fieldImprovements,
      research: researchState,
      runtimeState: GameRuntimeState(diplomacy: diplomacy),
      fogOfWar: fogOfWar ?? _visibleFog(actualMapData),
    ),
    forPlayerId: _playerId,
    turn: 1,
    mapData: actualMapData,
    ruleset: GameRuleset.defaults,
    ignoreFogOfWar: ignoreFogOfWar,
  );
}

MapData _mapData() {
  return _squareMap(cols: 3, rows: 2);
}

MapData _lineMap(int cols) {
  return _squareMap(cols: cols, rows: 1);
}

MapData _highCostLineMap() {
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
        terrains: [TerrainType.snow, TerrainType.forest, TerrainType.tundra],
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

MapData _squareMap({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

FogOfWarState _visibleFog(MapData mapData) {
  return _fogForHexes(_playerId, {
    for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
  });
}

FogOfWarState _fogForHexes(String playerId, Set<HexCoordinate> visibleHexes) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(playerId: playerId, visibleHexes: visibleHexes),
    },
  );
}
