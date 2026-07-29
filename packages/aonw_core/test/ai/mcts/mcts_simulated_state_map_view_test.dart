import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('simulated states preserve the request-scoped map view identity', () {
    final mapView = _mapData().indexedReadView();
    final root = SimulatedState.fromView(
      _view(mapView: mapView),
      maxPlanningDepth: 4,
    );

    final afterAction = root.apply(
      const CommandMctsAction(MoveUnitCommand('warrior_1', 1, 0)),
    );
    final afterTurn = const TracingMctsSimulator(
      simulateTurnEconomy: false,
    ).advanceTurn(root);
    final afterFounding =
        SimulatedState.fromView(
          _view(
            mapView: mapView,
            ownUnits: [
              GameUnit.produced(
                id: 'settler_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.settler,
                col: 0,
                row: 0,
              ),
            ],
          ),
          maxPlanningDepth: 4,
        ).apply(
          CommandMctsAction(
            FoundCityCommand(
              'settler_1',
              controlledHexes: const [
                CityHex(col: 1, row: 0),
                CityHex(col: 2, row: 0),
              ],
            ),
          ),
        );
    final context = AiContext(
      ruleset: GameRuleset.defaults,
      mapData: mapView,
      turn: 1,
      rng: AiRng(7),
    );

    expect(afterAction.view.mapData, same(mapView));
    expect(afterTurn.view.mapData, same(mapView));
    expect(afterFounding.view.mapData, same(mapView));
    expect(afterFounding.ownUnits.single.cityFoundingJob, isNotNull);
    expect(context.copyWith(turn: 2).mapData, same(mapView));
  });

  test('full simulation preserves coherent research and runtime metadata', () {
    final playerTwoResearch = PlayerResearchState(
      unlockedTechnologyIds: {TechnologyId.agriculture},
    );
    final research = ResearchState(
      players: {
        'player_1': PlayerResearchState(scienceOverflow: 3),
        'player_2': playerTwoResearch,
      },
    );
    const agreements = [
      ResourceTradeAgreement(
        id: 'trade_1',
        exporterPlayerId: 'player_2',
        importerPlayerId: 'player_1',
        resource: ResourceType.iron,
        goldPerTurn: 2,
        remainingTurns: 4,
      ),
    ];
    const holdStates = {
      'objective_1': MapObjectiveHoldState(
        objectiveId: 'objective_1',
        playerId: 'player_1',
        holdTurns: 2,
      ),
    };
    final wonders = WonderRegistry(
      completedBy: {WonderType.greatLibrary: 'player_1'},
    );
    final mapView = _mapData().indexedReadView();
    final rootView = _view(
      mapView: mapView,
      research: research,
      agreements: agreements,
      holdStates: holdStates,
      wonders: wonders,
      ownGold: 10,
    );
    final root = SimulatedState.fromView(rootView, maxPlanningDepth: 2);
    final simulatedView = root.view;
    final afterResearch = root
        .apply(
          const CommandMctsAction(
            SelectTechnologyCommand('player_1', TechnologyId.agriculture),
          ),
        )
        .view;
    final afterFullTurn = const TracingMctsSimulator(
      simulateOpponentPlans: false,
    ).advanceTurn(root).view;

    expect(simulatedView.research, research);
    expect(simulatedView.resourceTradeAgreements, agreements);
    expect(simulatedView.mapObjectiveHoldStatesByObjectiveId, holdStates);
    expect(simulatedView.wonderRegistry, same(wonders));
    expect(
      afterResearch.research.forPlayer('player_1'),
      same(afterResearch.ownResearch),
    );
    expect(
      afterResearch.ownResearch.activeTechnologyId,
      TechnologyId.agriculture,
    );
    expect(
      afterResearch.engineSnapshot?.domain.research,
      afterResearch.research,
    );
    expect(afterResearch.research.forPlayer('player_2'), playerTwoResearch);
    expect(afterFullTurn.mapData, same(mapView));
    expect(afterFullTurn.resourceTradeAgreements, hasLength(1));
    expect(afterFullTurn.resourceTradeAgreements.single.id, 'trade_1');
    expect(afterFullTurn.resourceTradeAgreements.single.remainingTurns, 3);
    expect(afterFullTurn.mapObjectiveHoldStatesByObjectiveId, holdStates);
    expect(afterFullTurn.wonderRegistry.completedBy, wonders.completedBy);
    expect(afterFullTurn.research.forPlayer('player_2'), playerTwoResearch);
  });

  test('lightweight skip projects the canonical unit mutation', () {
    final unit =
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
          movementPoints: 2,
          posture: UnitPosture.fortified,
        ).copyWithQueuedPath(
          QueuedMovePath(
            targetCol: 2,
            targetRow: 0,
            steps: const [
              UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            ],
          ),
        );
    final view = _view(mapView: _mapData().indexedReadView(), ownUnits: [unit]);
    final expected = UnitActionCommandResolver.skipUnitTurn(
      units: [unit],
      artifacts: view.artifacts,
      interaction: PersistedInteractionState.empty,
      command: const SkipUnitTurnCommand('warrior_1'),
      actorPlayerId: 'player_1',
    );

    final actual = SimulatedState.fromView(
      view,
      maxPlanningDepth: 2,
    ).apply(const CommandMctsAction(SkipUnitTurnCommand('warrior_1')));

    expect(actual.ownUnits, expected.units);
    expect(actual.ownUnits.single.movementPoints, 0);
    expect(actual.ownUnits.single.queuedPath, isNull);
    expect(actual.ownUnits.single.posture, UnitPosture.active);
  });

  test('lightweight unit actions fail loudly without an engine envelope', () {
    final view = _view(
      mapView: _mapData().indexedReadView(),
      includeEngineSnapshot: false,
    );
    final root = SimulatedState.fromView(view, maxPlanningDepth: 2);

    for (final command in const [
      SkipUnitTurnCommand('warrior_1'),
      FortifyUnitCommand('warrior_1'),
    ]) {
      expect(
        () => root.apply(CommandMctsAction(command)),
        throwsA(isA<StateError>()),
      );
    }
  });

  test(
    'lightweight fortify projects accept and preserves rejected workers',
    () {
      final warrior = GameUnit(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
        movementPoints: 2,
      );
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: 'Worker',
        col: 1,
        row: 0,
        workerJob: const WorkerJob(
          improvementType: FieldImprovementType.farm,
          targetHex: CityHex(col: 1, row: 0),
          remainingTurns: 2,
          totalTurns: 3,
        ),
      );
      final view = _view(
        mapView: _mapData().indexedReadView(),
        ownUnits: [warrior, worker],
      );
      final expected = UnitActionCommandResolver.fortifyUnit(
        units: [warrior, worker],
        artifacts: view.artifacts,
        interaction: PersistedInteractionState.empty,
        command: const FortifyUnitCommand('warrior_1'),
        actorPlayerId: 'player_1',
      );
      final root = SimulatedState.fromView(view, maxPlanningDepth: 3);

      final fortified = root.apply(
        const CommandMctsAction(FortifyUnitCommand('warrior_1')),
      );
      final rejected = root.apply(
        const CommandMctsAction(FortifyUnitCommand('worker_1')),
      );

      expect(fortified.ownUnits, expected.units);
      expect(fortified.ownUnits.first.posture, UnitPosture.fortified);
      expect(rejected.ownUnits, root.ownUnits);
    },
  );
}

GameView _view({
  required MapReadView mapView,
  Iterable<GameUnit>? ownUnits,
  ResearchState research = ResearchState.empty,
  List<ResourceTradeAgreement> agreements = const [],
  Map<String, MapObjectiveHoldState> holdStates = const {},
  WonderRegistry wonders = WonderRegistry.empty,
  int ownGold = 0,
  bool includeEngineSnapshot = true,
}) {
  final units =
      ownUnits?.toList(growable: false) ??
      [
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
      ];
  return GameView(
    forPlayerId: 'player_1',
    turn: 1,
    ownUnits: units,
    ownCities: const [],
    ownGold: ownGold,
    research: research,
    ownResearch: research.forPlayer('player_1'),
    ownImprovements: const [],
    resourceTradeAgreements: agreements,
    mapObjectiveHoldStatesByObjectiveId: holdStates,
    visibleEnemyUnits: const [],
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: mapView,
    ruleset: GameRuleset.defaults,
    wonderRegistry: wonders,
    engineSnapshot: includeEngineSnapshot ? _engineSnapshot(units) : null,
  );
}

CanonicalGameSnapshot _engineSnapshot(List<GameUnit> units) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: const [Player(id: 'player_1', name: 'AI', colorValue: 1)],
      units: units,
    ),
    session: MatchSessionState.snapshot(gameMode: GameMode.hotSeat),
    metadata: GameSnapshotMetadata(
      id: 'mcts_test',
      schemaVersion: 3,
      name: 'MCTS test',
      world: const WorldReference(name: 'test', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
    ),
  );
}

MapData _mapData() {
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
