import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/services/ai_turn_command_executor.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnCommandExecutor', () {
    test('dispatches planned commands with AI context and UI delays', () async {
      final commands = <GameCommand>[];
      final contexts = <GameCommandContext>[];
      final delays = <Duration>[];
      final executor = AiTurnCommandExecutor(
        dispatch:
            ({
              required saveId,
              required currentState,
              required command,
              required context,
            }) async {
              commands.add(command);
              contexts.add(context);
              return DispatchCommandResult(
                state: currentState.copyWith(moveCommandActive: true),
                uiEffects: const [JumpCameraEffect(col: 1, row: 1)],
              );
            },
        delay: (duration) async {
          delays.add(duration);
        },
      );

      final report = await executor.executePlan(
        saveId: 'save_1',
        playerId: 'ai_1',
        aiContext: _context(turn: 7),
        initialState: const GameState(activePlayerId: 'ai_1'),
        commands: const [SkipUnitTurnCommand('unit_1')],
        interCommandDelay: const Duration(milliseconds: 40),
      );

      expect(commands, const [SkipUnitTurnCommand('unit_1')]);
      expect(contexts.single.actorPlayerId, 'ai_1');
      expect(contexts.single.combatSeedTurn, 7);
      expect(contexts.single.ignoreFogOfWar, isTrue);
      expect(delays, const [Duration(milliseconds: 40)]);
      expect(report.dispatchedCommands, commands);
      expect(report.delayedCommandCount, 1);
      expect(report.finalState.moveCommandActive, isTrue);
    });

    test('skips terminal and stale move commands before dispatch', () async {
      final logger = _RecordingGameLogger();
      final commands = <GameCommand>[];
      final executor = AiTurnCommandExecutor(
        logger: logger,
        dispatch:
            ({
              required saveId,
              required currentState,
              required command,
              required context,
            }) async {
              commands.add(command);
              return DispatchCommandResult(
                state: currentState.copyWith(moveCommandActive: true),
              );
            },
        delay: (_) async {
          fail('stale/terminal commands should not delay presentation');
        },
      );
      const staleMove = MoveUnitCommand('unit_1', 2, 3);

      final report = await executor.executePlan(
        saveId: 'save_1',
        playerId: 'ai_1',
        aiContext: _context(turn: 8),
        initialState: GameState(
          activePlayerId: 'ai_1',
          units: [
            GameUnit(
              id: 'unit_1',
              ownerPlayerId: 'ai_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 2,
              row: 3,
            ),
          ],
        ),
        commands: const [EndTurnCommand('ai_1'), staleMove],
        interCommandDelay: const Duration(milliseconds: 40),
      );

      expect(commands, isEmpty);
      expect(report.skippedTerminalCommands, const [EndTurnCommand('ai_1')]);
      expect(report.skippedStaleCommands, const [staleMove]);
      expect(report.dispatchedCommands, isEmpty);
      expect(report.finalState.moveCommandActive, isFalse);
      expect(
        logger.warnMessages,
        contains(
          'AI: AI strategy returned terminal command; runner owns turn submit: '
          'end turn for ai_1.',
        ),
      );
      expect(
        logger.infoMessages,
        contains(
          'AI: Skipping stale move for ai_1: move unit unit_1 to (2, 3)',
        ),
      );
    });
  });
}

AiContext _context({required int turn}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: _mapData,
    turn: turn,
    rng: AiRng.fromTurn(turn: turn, playerId: 'ai_1', baseSeed: 7),
  );
}

final _mapData = MapData(
  cols: 1,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);

final class _RecordingGameLogger implements GameLogger {
  final infoMessages = <String>[];
  final warnMessages = <String>[];

  @override
  void info(String tag, String message) {
    infoMessages.add('$tag: $message');
  }

  @override
  void warn(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    warnMessages.add('$tag: $message');
  }
}
