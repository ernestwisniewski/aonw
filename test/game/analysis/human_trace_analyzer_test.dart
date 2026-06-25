import 'package:aonw/game/analysis/human_trace_analyzer.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HumanTraceAnalyzer', () {
    test('extracts human benchmarks and repeated AI problem signals', () {
      final report = const HumanTraceAnalyzer().analyze(
        humanPlayerId: 'player_1',
        log: [
          _logged(1, const StartCityFoundingCommand()),
          _logged(
            2,
            const FoundCityCommand(
              'settler_player_1',
              controlledHexes: [CityHex(col: 2, row: 3)],
            ),
          ),
          _logged(
            3,
            const SelectTechnologyCommand('player_1', TechnologyId.agriculture),
          ),
          _logged(
            4,
            const StartBuildingCommand('city_1', CityBuildingType.granary),
          ),
          _logged(
            5,
            const SubmitTurnCommand('player_1'),
            events: [
              AllPlayersSubmittedEvent(
                turn: 1,
                playerIds: const ['player_1', 'player_2'],
              ),
            ],
          ),
          _logged(
            6,
            const MoveUnitCommand('settler_player_2', 8, 5),
            actorPlayerId: 'player_2',
          ),
          _logged(
            7,
            const MoveUnitCommand('settler_player_2', 8, 5),
            actorPlayerId: 'player_2',
          ),
          _logged(
            8,
            const SelectWorkerImprovementCommand(
              'worker_player_2',
              FieldImprovementType.farm,
            ),
            actorPlayerId: 'player_2',
          ),
          _logged(
            9,
            const SelectWorkerImprovementCommand(
              'worker_player_2',
              FieldImprovementType.farm,
            ),
            actorPlayerId: 'player_2',
          ),
          _logged(10, const AttackHexCommand('warrior_player_1', 4, 4)),
        ],
      );

      expect(report.lastCompletedTurn, 1);
      expect(report.humanCommandCounts, {
        'FoundCity': 1,
        'SelectTechnology': 1,
        'StartBuilding': 1,
        'AttackHex': 1,
      });
      expect(report.humanFoundCities.single.turn, 1);
      expect(report.humanResearch.single.technologyId, 'agriculture');
      expect(report.humanProduction.single.target, 'granary');
      expect(report.humanAttacks.single.targetCol, 4);

      final repeatedMove = report.repeatedAiCommands.singleWhere(
        (command) => command.commandType == 'MoveUnit',
      );
      expect(repeatedMove.playerId, 'player_2');
      expect(repeatedMove.count, 2);
      expect(repeatedMove.firstTurn, 2);

      final workerStall = report.aiWorkerStalls.single;
      expect(workerStall.playerId, 'player_2');
      expect(workerStall.selectionCount, 2);
      expect(workerStall.completionCount, 0);
      expect(workerStall.improvementType, 'farm');
    });
  });
}

LoggedCommand _logged(
  int offset,
  GameCommand command, {
  String? actorPlayerId,
  List<GameEvent> events = const [],
}) {
  return LoggedCommand(
    offset: offset,
    timestamp: DateTime.utc(2026, 5, 19, 12, 0, offset),
    turn: 1,
    command: command,
    actorPlayerId: actorPlayerId,
    events: events,
  );
}
