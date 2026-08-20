part of 'run_ai_turn_use_case_test.dart';

List<Player> _defaultPlayers(AiStrategyId aiStrategyId) {
  return [
    const Player(id: 'player_1', name: 'Alice', colorValue: 0xFF2563EB),
    Player(
      id: 'player_2',
      name: 'AI Random',
      colorValue: 0xFFDC2626,
      kind: PlayerKind.ai,
      ai: AiPlayer(
        strategyId: aiStrategyId,
        difficulty: AiDifficulty.normal,
        persona: AiPersona.aggressive,
        seed: 123,
      ),
    ),
  ];
}

RunAiTurnUseCase _useCase({
  required GameSave save,
  required AiStrategy strategy,
  required _RecordingCommandTransport transport,
  AiStrategyRegistry? strategyRegistry,
  List<GameUnit>? units,
  List<GameCity>? cities,
  List<WorldArtifact> artifacts = const [],
  DiplomacyState diplomacy = DiplomacyState.empty,
  List<IntendedAttack> intendedAttacks = const [],
  int eventLogOffset = 0,
  AiRecentHostilityTracker? recentHostilityTracker,
  AiPlanningDeadlinePolicy planningDeadlinePolicy =
      AiPlanningDeadlinePolicy.unbounded,
}) {
  return RunAiTurnUseCase(
    repository: _MemoryGameRepository(
      GameSnapshotFactory.create(
        save: save,
        units:
            units ??
            [
              GameUnit.startingCommander(
                ownerPlayerId: 'player_1',
                col: 0,
                row: 0,
              ),
              GameUnit.startingCommander(
                ownerPlayerId: 'player_2',
                col: 1,
                row: 0,
              ),
            ],
        cities: cities ?? const [],
        artifacts: artifacts,
        diplomacy: diplomacy,
        intendedAttacks: intendedAttacks,
        turnStartedAt: save.savedAt,
        eventLogOffset: eventLogOffset,
      ),
    ),
    strategyRegistry:
        strategyRegistry ?? AiStrategyRegistry({AiStrategyId.random: strategy}),
    runner: AiTurnRunner(
      dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
      delay: (_) async {},
    ),
    ruleset: GameRuleset.defaults,
    mapData: _mapData,
    planningDeadlinePolicy: planningDeadlinePolicy,
    recentHostilityTracker: recentHostilityTracker,
  );
}

class _CapturingStrategy implements AiStrategy {
  final List<DomainCommand> commands;
  GameView? lastView;
  AiContext? lastContext;

  _CapturingStrategy({required this.commands});

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    lastView = view;
    lastContext = context;
    return AiTurnPlan(commands: commands);
  }
}

class _RecordingCommandTransport implements CommandTransport {
  final commands = <DomainCommand>[];
  final states = <GameClientState>[];

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    GameCommandContext context = const GameCommandContext(),
    bool fromMovePreviewConfirmation = false,
  }) async {
    commands.add(command);
    states.add(currentState);
    final nextState = switch (command) {
      SubmitTurnCommand() ||
      EndTurnCommand() => currentState.copyWith(activePlayerCanAct: false),
      _ => currentState.copyWithInteraction(moveCommandActive: true),
    };
    return CommandTransportResult(
      state: nextState,
      snapshot: GameSnapshotFactory.create(
        save: _save(gameMode: GameMode.hotSeat),
      ),
      offset: commands.length,
    );
  }
}

class _MemoryGameRepository implements GameRepository {
  final CanonicalGameSnapshot snapshot;

  const _MemoryGameRepository(this.snapshot);

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => snapshot.save.id;

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async => snapshot;

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {}

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    throw UnimplementedError();
  }
}

class _MemoryEventLog implements EventLog {
  final commands = <RecordedDomainCommand>[];

  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async {
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    return commands.isEmpty ? 0 : commands.last.offset;
  }

  @override
  Stream<RecordedDomainCommand> readAll(String saveId) => readSince(saveId);

  @override
  Stream<RecordedDomainCommand> readSince(
    String saveId, {
    int offset = 0,
  }) async* {
    for (final command in commands) {
      if (command.offset >= offset) yield command;
    }
  }
}

GameSave _save({
  required GameMode gameMode,
  DateTime? turnStartedAt,
  AiStrategyId aiStrategyId = AiStrategyId.random,
  MatchRules matchRules = MatchRules.standard,
  int turn = 2,
  List<Player>? players,
}) {
  final savedAt = turnStartedAt ?? DateTime.utc(2026, 4, 27, 12);
  return GameSave(
    id: 'save_1',
    name: 'AI test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: {
      for (final player in players ?? _defaultPlayers(aiStrategyId))
        player.id: PlayerTurnState.active,
    },
    savedAt: savedAt,
    camera: CameraState.zero,
    matchRules: matchRules,
    players: players ?? _defaultPlayers(aiStrategyId),
    gameMode: gameMode,
  );
}

final _mapData = WorldMap(
  cols: 2,
  rows: 1,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    WorldTile(
      col: 1,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
