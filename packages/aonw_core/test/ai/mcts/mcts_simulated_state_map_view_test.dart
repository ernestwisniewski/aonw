import 'package:aonw_core/application.dart';
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

  test(
    'advanceTurn carries one canonical snapshot into turn-derived diplomacy',
    () {
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(scienceOverflow: 3),
          'player_2': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
          ),
        },
      );
      final diplomacy = DiplomacyState.empty
          .addContact('player_1', 'player_2')
          .addMessage(
            DiplomaticMessage.create(
              id: 'message_at_cooldown_boundary',
              fromPlayerId: 'player_1',
              toPlayerId: 'player_2',
              topic: DiplomaticMessageTopic.troopsNearCities,
              createdTurn: 5,
              expiresOnTurn: 20,
            ),
          );
      final mapView = _mapData().indexedReadView();
      final root = SimulatedState.fromView(
        _view(
          mapView: mapView,
          turn: 9,
          research: research,
          diplomacy: diplomacy,
          includeOpponent: true,
        ),
        maxPlanningDepth: 8,
      );

      final advanced = const TracingMctsSimulator(
        simulateOpponentPlans: false,
      ).advanceTurn(root);
      final nextView = advanced.view;
      final nextSnapshot = nextView.engineSnapshot!;

      expect(nextView.turn, 10);
      expect(nextSnapshot.domain.turn, nextView.turn);
      expect(nextSnapshot.domain.research, nextView.research);
      expect(nextSnapshot.domain.diplomacy, nextView.diplomacy);

      final afterMessage =
          SimulatedState.fromView(nextView, maxPlanningDepth: 8)
              .apply(
                const CommandMctsAction(
                  SendDiplomaticMessageCommand(
                    playerId: 'player_1',
                    targetPlayerId: 'player_2',
                    topic: DiplomaticMessageTopic.troopsNearCities,
                    messageId: 'message_after_advance',
                  ),
                ),
              )
              .view;
      final message = afterMessage.diplomacy.messages['message_after_advance']!;
      expect(message.createdTurn, 10);
      expect(message.expiresOnTurn, 15);

      final proposalResult = const GameEngine().apply(
        snapshot: nextSnapshot,
        command: const SendDiplomaticProposalCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
          kind: DiplomaticProposalKind.friendship,
          proposalId: 'proposal_after_advance',
        ),
        context: GameEngineContext(
          actorPlayerId: 'player_1',
          mapView: mapView,
          ruleset: GameRuleset.defaults,
          commandTick: 10,
        ),
      );
      expect(proposalResult, isA<GameEngineAccepted>());
      final proposal = proposalResult
          .snapshot
          .domain
          .diplomacy
          .pendingProposals['proposal_after_advance']!;
      expect(proposal.createdTurn, 10);
      expect(proposal.expiresOnTurn, 15);

      final truceSnapshot = nextSnapshot.copyWith(
        domain: nextSnapshot.domain.copyWith(
          diplomacy: nextSnapshot.domain.diplomacy.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.truce,
            turn: 5,
            statusExpiresOnTurn: 10,
          ),
        ),
      );
      final warResult = const GameEngine().apply(
        snapshot: truceSnapshot,
        command: const DeclareWarCommand(
          playerId: 'player_1',
          targetPlayerId: 'player_2',
        ),
        context: GameEngineContext(
          actorPlayerId: 'player_1',
          mapView: mapView,
          ruleset: GameRuleset.defaults,
          commandTick: 11,
        ),
      );
      expect(warResult, isA<GameEngineAccepted>());
      final warDiplomacy = warResult.snapshot.domain.diplomacy;
      expect(
        warDiplomacy.relationBetween('player_1', 'player_2').lastChangedTurn,
        10,
      );
      expect(
        warDiplomacy.scoreEntriesBetween('player_1', 'player_2').last.turn,
        10,
      );
    },
  );

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
  int turn = 1,
  Iterable<GameUnit>? ownUnits,
  ResearchState research = ResearchState.empty,
  DiplomacyState diplomacy = DiplomacyState.empty,
  List<ResourceTradeAgreement> agreements = const [],
  Map<String, MapObjectiveHoldState> holdStates = const {},
  WonderRegistry wonders = WonderRegistry.empty,
  int ownGold = 0,
  bool includeEngineSnapshot = true,
  bool includeOpponent = false,
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
    turn: turn,
    ownUnits: units,
    ownCities: const [],
    ownGold: ownGold,
    research: research,
    ownResearch: research.forPlayer('player_1'),
    ownImprovements: const [],
    resourceTradeAgreements: agreements,
    mapObjectiveHoldStatesByObjectiveId: holdStates,
    diplomacy: diplomacy,
    visibleEnemyUnits: const [],
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: mapView,
    ruleset: GameRuleset.defaults,
    wonderRegistry: wonders,
    engineSnapshot: includeEngineSnapshot
        ? _engineSnapshot(
            units,
            turn: turn,
            research: research,
            diplomacy: diplomacy,
            includeOpponent: includeOpponent,
          )
        : null,
  );
}

CanonicalGameSnapshot _engineSnapshot(
  List<GameUnit> units, {
  required int turn,
  required ResearchState research,
  required DiplomacyState diplomacy,
  required bool includeOpponent,
}) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: turn,
      matchRules: MatchRules.standard,
      participants: [
        const Player(id: 'player_1', name: 'AI', colorValue: 1),
        if (includeOpponent)
          const Player(id: 'player_2', name: 'Opponent', colorValue: 2),
      ],
      units: units,
      research: research,
      diplomacy: diplomacy,
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
