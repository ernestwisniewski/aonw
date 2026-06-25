import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_recent_hostility_tracker.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/application/use_cases/run_ai_turn_use_case.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/movement_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunAiTurnUseCase', () {
    test('runs AI player through submit turn in multiplayer mode', () async {
      final turnStartedAt = DateTime.utc(2026, 4, 27, 12);
      final strategy = _CapturingStrategy(
        commands: const [SkipUnitTurnCommand('commander_player_2')],
      );
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(
          gameMode: GameMode.multiplayer,
          turnStartedAt: turnStartedAt,
        ),
        strategy: strategy,
        transport: transport,
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(transport.commands, [
        const SkipUnitTurnCommand('commander_player_2'),
        const SubmitTurnCommand('player_2'),
      ]);
      expect(strategy.lastView?.forPlayerId, 'player_2');
      expect(strategy.lastView?.ownUnits.single.id, 'commander_player_2');
      expect(strategy.lastContext?.persona, AiPersona.aggressive);
      expect(
        strategy.lastContext?.deadline,
        turnStartedAt.add(const Duration(seconds: 115)),
      );
    });

    test('marks human players as pressure targets for AI planning', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(gameMode: GameMode.hotSeat),
        strategy: strategy,
        transport: transport,
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(strategy.lastView?.pressureTargetPlayerIds, {'player_1'});
    });

    test('does not pressure friendly human players', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(gameMode: GameMode.hotSeat),
        strategy: strategy,
        transport: transport,
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.friendly,
          ),
        ),
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(strategy.lastView?.pressureTargetPlayerIds, isEmpty);
    });

    test('does not pressure explicitly neutral human players', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(gameMode: GameMode.hotSeat),
        strategy: strategy,
        transport: transport,
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.neutral,
          ),
        ),
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(strategy.lastView?.pressureTargetPlayerIds, isEmpty);
    });

    test('pressures neutral human players near cultural victory', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final cities = [
        for (var i = 0; i < 4; i++)
          GameCity(
            id: 'human_city_$i',
            ownerPlayerId: 'player_1',
            name: 'Human $i',
            center: CityHex(col: i, row: 0),
          ),
      ];
      final artifacts = [
        for (var i = 0; i < 4; i++)
          WorldArtifact(
            id: 'artifact_$i',
            type: WorldArtifactType.values[i],
            location: WorldArtifactLocation.stored(cityId: cities[i].id),
          ),
      ];
      final useCase = _useCase(
        save: _save(gameMode: GameMode.hotSeat),
        strategy: strategy,
        transport: transport,
        cities: cities,
        artifacts: artifacts,
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.neutral,
          ),
        ),
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(strategy.lastView?.pressureTargetPlayerIds, {'player_1'});
    });

    test('pressures human players in explicit war', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(gameMode: GameMode.hotSeat),
        strategy: strategy,
        transport: transport,
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.war,
          ),
        ),
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(strategy.lastView?.pressureTargetPlayerIds, {'player_1'});
    });

    test('pressures human players in explicit hostile relation', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(gameMode: GameMode.hotSeat),
        strategy: strategy,
        transport: transport,
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.hostile,
          ),
        ),
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(strategy.lastView?.pressureTargetPlayerIds, {'player_1'});
      expect(strategy.lastView?.canTargetPlayer('player_1'), isTrue);
    });

    test('pressures runaway score leaders during AI planning', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final matchRules = MatchRules.forGameLength(GameLengthConfig.standard60);
      final useCase = _useCase(
        save: _save(
          gameMode: GameMode.hotSeat,
          matchRules: matchRules,
          turn: 50,
          players: const [
            Player(id: 'player_1', name: 'Alice', colorValue: 0xFF2563EB),
            Player(
              id: 'player_2',
              name: 'AI Acting',
              colorValue: 0xFFDC2626,
              kind: PlayerKind.ai,
              ai: AiPlayer(
                strategyId: AiStrategyId.random,
                difficulty: AiDifficulty.normal,
                persona: AiPersona.aggressive,
                seed: 123,
              ),
            ),
            Player(
              id: 'player_3',
              name: 'AI Leader',
              colorValue: 0xFF16A34A,
              kind: PlayerKind.ai,
              ai: AiPlayer(strategyId: AiStrategyId.random, seed: 456),
            ),
          ],
        ),
        strategy: strategy,
        transport: transport,
        cities: const [
          GameCity(
            id: 'acting_city',
            ownerPlayerId: 'player_2',
            name: 'Acting City',
            center: CityHex(col: 1, row: 0),
          ),
          GameCity(
            id: 'leader_city_a',
            ownerPlayerId: 'player_3',
            name: 'Leader A',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'leader_city_b',
            ownerPlayerId: 'player_3',
            name: 'Leader B',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'player_1',
            'player_2',
            DiplomaticRelationStatus.neutral,
          ),
        ),
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(strategy.lastContext?.scoreRace?.leaderPlayerId, 'player_3');
      expect(strategy.lastView?.pressureTargetPlayerIds, contains('player_3'));
      expect(
        strategy.lastContext?.strategicPlan?.rivalRanking.first.playerId,
        'player_3',
      );
    });

    test('resets hot-seat AI movement before planning', () async {
      final aiCommander = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 1,
        row: 0,
      ).copyWith(movementPoints: 0).copyWithHitPoints(2);
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(gameMode: GameMode.hotSeat),
        strategy: strategy,
        transport: transport,
        units: [
          GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0),
          aiCommander,
        ],
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(transport.commands, [
        const ResetUnitMovementCommand(playerId: 'player_2'),
        const EndTurnCommand('player_2'),
      ]);
      final viewedCommander = strategy.lastView?.ownUnits.single;
      expect(
        viewedCommander?.movementPoints,
        UnitMovementBalance.commanderMovementPointsPerTurn,
      );
      expect(viewedCommander?.hitPoints, 2);
      final terminalState = transport.states.last;
      final dispatchedCommander = terminalState.units.singleWhere(
        (unit) => unit.id == 'commander_player_2',
      );
      expect(
        dispatchedCommander.movementPoints,
        UnitMovementBalance.commanderMovementPointsPerTurn,
      );
      expect(dispatchedCommander.hitPoints, 2);
    });

    test('runs MCTS AI player in hot-seat mode', () async {
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(
          gameMode: GameMode.hotSeat,
          aiStrategyId: AiStrategyId.mcts,
        ),
        strategy: _CapturingStrategy(commands: const []),
        strategyRegistry: AiStrategyRegistry({
          AiStrategyId.mcts: const MctsStrategy(
            config: MctsConfig(
              wallClockBudget: Duration.zero,
              minimumBudget: Duration.zero,
              minIterations: 12,
              maxPlanningDepth: 2,
            ),
          ),
        }),
        transport: transport,
        units: [
          GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0),
        ],
        cities: const [
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            name: 'AI City',
            center: CityHex(col: 1, row: 0),
          ),
        ],
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(
        transport.commands.first,
        const ResetUnitMovementCommand(playerId: 'player_2'),
      );
      expect(transport.commands.last, const EndTurnCommand('player_2'));
      expect(
        transport.commands
            .skip(1)
            .take(transport.commands.length - 2)
            .where((command) => command is! EndTurnCommand),
        isNotEmpty,
      );
    });

    test('returns null for human players', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(gameMode: GameMode.hotSeat),
        strategy: strategy,
        transport: transport,
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_1',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNull);
      expect(transport.commands, isEmpty);
      expect(strategy.lastContext, isNull);
    });

    test('returns null for a provided snapshot from another save', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(gameMode: GameMode.hotSeat),
        strategy: strategy,
        transport: transport,
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        snapshot: SaveSnapshot(
          save: _save(gameMode: GameMode.hotSeat).copyWith(id: 'other_save'),
        ),
        interCommandDelay: Duration.zero,
      );

      expect(report, isNull);
      expect(transport.commands, isEmpty);
      expect(strategy.lastContext, isNull);
    });

    test('passes recent hostility memory into the AI view', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final eventLog = _MemoryEventLog()
        ..commands.add(
          LoggedCommand(
            offset: 1,
            timestamp: DateTime.utc(2026, 4, 27, 12),
            turn: 1,
            actorPlayerId: 'player_3',
            command: const SkipUnitTurnCommand('warrior_3'),
            events: const [
              UnitAttackedEvent(
                attackerUnitId: 'warrior_3',
                attackerOwnerPlayerId: 'player_3',
                defenderUnitId: 'commander_player_2',
                defenderOwnerPlayerId: 'player_2',
              ),
            ],
          ),
        );
      final useCase = _useCase(
        save: _save(gameMode: GameMode.hotSeat),
        strategy: strategy,
        transport: transport,
        eventLogOffset: 1,
        recentHostilityTracker: AiRecentHostilityTracker(eventLog: eventLog),
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(strategy.lastView?.recentHostilePlayerIds, {'player_3'});
      expect(
        strategy.lastContext?.strategicPlan?.rivalRanking.first.playerId,
        'player_3',
      );
    });

    test('treats pending multiplayer attack intents as hostility', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(gameMode: GameMode.multiplayer),
        strategy: strategy,
        transport: transport,
        runtimeState: const GameRuntimeState(
          intendedAttacks: [
            IntendedAttack(
              attackerUnitId: 'commander_player_1',
              defenderCol: 1,
              defenderRow: 0,
              declaredAtTick: 7,
              declaringPlayerId: 'player_1',
            ),
          ],
        ),
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(strategy.lastView?.activeHostilePlayerIds, {'player_1'});
      expect(strategy.lastView?.recentHostilePlayerIds, isEmpty);
      expect(
        strategy.lastContext?.strategicPlan?.rivalRanking.first.playerId,
        'player_1',
      );
    });

    test(
      'treats pending attack intents as active hostility despite neutral',
      () async {
        final strategy = _CapturingStrategy(commands: const []);
        final transport = _RecordingCommandTransport();
        final useCase = _useCase(
          save: _save(gameMode: GameMode.multiplayer),
          strategy: strategy,
          transport: transport,
          runtimeState: GameRuntimeState(
            diplomacy: DiplomacyState.empty.setStatus(
              'player_1',
              'player_2',
              DiplomaticRelationStatus.neutral,
            ),
            intendedAttacks: const [
              IntendedAttack(
                attackerUnitId: 'commander_player_1',
                defenderCol: 1,
                defenderRow: 0,
                declaredAtTick: 7,
                declaringPlayerId: 'player_1',
              ),
            ],
          ),
        );

        final report = await useCase.execute(
          saveId: 'save_1',
          playerId: 'player_2',
          interCommandDelay: Duration.zero,
        );

        expect(report, isNotNull);
        expect(strategy.lastView?.pressureTargetPlayerIds, isEmpty);
        expect(strategy.lastView?.activeHostilePlayerIds, {'player_1'});
        expect(strategy.lastView?.canTargetPlayer('player_1'), isTrue);
        expect(
          strategy.lastContext?.strategicPlan?.rivalRanking.first.playerId,
          'player_1',
        );
      },
    );

    test('passes pending city attacks as urgent AI defense threats', () async {
      final strategy = _CapturingStrategy(commands: const []);
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        save: _save(gameMode: GameMode.multiplayer),
        strategy: strategy,
        transport: transport,
        units: [
          GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0),
        ],
        cities: const [
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            name: 'AI City',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        runtimeState: const GameRuntimeState(
          intendedAttacks: [
            IntendedAttack(
              attackerUnitId: 'commander_player_1',
              defenderCol: 1,
              defenderRow: 0,
              declaredAtTick: 9,
              declaringPlayerId: 'player_1',
            ),
          ],
        ),
      );

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
      );

      expect(report, isNotNull);
      expect(strategy.lastView?.pendingCityAttackThreats, [
        const PendingCityAttackThreat(
          attackerPlayerId: 'player_1',
          attackerUnitId: 'commander_player_1',
          attackerHex: HexCoordinate(col: 0, row: 0),
          cityId: 'city_2',
          cityCenter: CityHex(col: 1, row: 0),
        ),
      ]);
      expect(
        strategy.lastView?.visibleEnemyUnits.map((unit) => unit.id),
        contains('commander_player_1'),
      );
    });
  });
}

RunAiTurnUseCase _useCase({
  required GameSave save,
  required AiStrategy strategy,
  required _RecordingCommandTransport transport,
  AiStrategyRegistry? strategyRegistry,
  List<GameUnit>? units,
  List<GameCity>? cities,
  List<WorldArtifact> artifacts = const [],
  GameRuntimeState runtimeState = GameRuntimeState.empty,
  int eventLogOffset = 0,
  AiRecentHostilityTracker? recentHostilityTracker,
}) {
  return RunAiTurnUseCase(
    repository: _MemoryGameRepository(
      SaveSnapshot(
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
        runtimeState: runtimeState.copyWith(turnStartedAt: save.savedAt),
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
    recentHostilityTracker: recentHostilityTracker,
  );
}

class _CapturingStrategy implements AiStrategy {
  final List<GameCommand> commands;
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
  final commands = <GameCommand>[];
  final states = <GameState>[];

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    GameCommandContext context = const GameCommandContext(),
  }) async {
    commands.add(command);
    states.add(currentState);
    final nextState = switch (command) {
      ResetUnitMovementCommand(:final playerId) =>
        MovementReducer.resetUnitMovementForNewTurn(
          currentState,
          _mapData,
          playerId: playerId,
        ).state,
      SubmitTurnCommand() ||
      EndTurnCommand() => currentState.copyWith(activePlayerCanAct: false),
      _ => currentState.copyWith(moveCommandActive: true),
    };
    return CommandTransportResult(
      state: nextState,
      snapshot: SaveSnapshot(save: _save(gameMode: GameMode.hotSeat)),
      offset: commands.length,
    );
  }
}

class _MemoryGameRepository implements GameRepository {
  final SaveSnapshot snapshot;

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
  Future<SaveSnapshot> load(String saveId) async => snapshot;

  @override
  Future<void> save(SaveSnapshot snapshot) async {}

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    throw UnimplementedError();
  }
}

class _MemoryEventLog implements EventLog {
  final commands = <LoggedCommand>[];

  @override
  Future<void> append(String saveId, LoggedCommand command) async {
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    return commands.isEmpty ? 0 : commands.last.offset;
  }

  @override
  Stream<LoggedCommand> readAll(String saveId) => readSince(saveId);

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) async* {
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

final _mapData = MapData(
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
