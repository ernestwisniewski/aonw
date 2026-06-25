import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('economy_simulation tool', () {
    test(
      'writes preset and score-chaser report sections',
      () async {
        final outputDir = await Directory.systemTemp.createTemp(
          'aonw_ai_telemetry_',
        );
        addTearDown(() async {
          if (await outputDir.exists()) {
            await outputDir.delete(recursive: true);
          }
        });

        final result = await Process.run(Platform.resolvedExecutable, [
          'run',
          'tool/economy_simulation.dart',
          '--out',
          outputDir.path,
          '--turns',
          '48',
        ]);

        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );

        final reportFile = File('${outputDir.path}/ai-telemetry-report.md');
        final standardCsv = File(
          '${outputDir.path}/economy-simulation-standard60.csv',
        );
        final normalCsv = File(
          '${outputDir.path}/economy-simulation-normal90.csv',
        );
        final longCsv = File(
          '${outputDir.path}/economy-simulation-long120.csv',
        );
        final scoreChaserCsv = File(
          '${outputDir.path}/score-chaser-objective-actions.csv',
        );
        final scoreComebackCsv = File(
          '${outputDir.path}/score-comeback-telemetry.csv',
        );

        expect(await reportFile.exists(), isTrue);
        expect(await standardCsv.exists(), isTrue);
        expect(await normalCsv.exists(), isTrue);
        expect(await longCsv.exists(), isTrue);
        expect(await scoreChaserCsv.exists(), isTrue);
        expect(await scoreComebackCsv.exists(), isTrue);

        final report = await reportFile.readAsString();
        final turnLimit = GameLengthConfig.standard60.turnLimit!;
        expect(report, contains('| standard60 |'));
        expect(report, contains('| normal90 |'));
        expect(report, contains('| long120 |'));
        expect(report, contains('| Final pace |'));
        expect(report, contains('| End targets |'));
        expect(report, contains('techs:'));
        expect(report, contains('science:'));
        expect(report, contains('## Preset Player Findings'));
        expect(report, contains('| standard60 | player_1 |'));
        expect(report, contains('| standard60 | player_2 |'));
        expect(report, contains('## Score Chaser Objective Action'));
        expect(report, contains('[csv](score-chaser-objective-actions.csv)'));
        expect(report, contains('| Production gap |'));
        expect(report, contains('| Research gap |'));
        expect(report, contains('| Economy gap |'));
        expect(report, contains('## Score Comeback Telemetry'));
        expect(report, contains('[csv](score-comeback-telemetry.csv)'));
        expect(report, contains('| T${turnLimit - 5} | Production gap |'));
        expect(report, contains('| T${turnLimit - 3} | Research gap |'));
        expect(report, contains('| T${turnLimit - 1} | Economy gap |'));

        final scoreChaser = await scoreChaserCsv.readAsString();
        expect(
          scoreChaser,
          contains(
            'scenario,active_score,leader_score,score_gap,advice,target',
          ),
        );
        expect(scoreChaser, contains('production_gap,'));
        expect(scoreChaser, contains(',constructBuilding,cityProduction'));
        expect(scoreChaser, contains('research_gap,'));
        expect(scoreChaser, contains(',unlockTechnology,research'));
        expect(scoreChaser, contains('economy_gap,'));
        expect(scoreChaser, contains(',collectGold,cityProduction'));

        final scoreComeback = await scoreComebackCsv.readAsString();
        expect(
          scoreComeback,
          contains('turn,scenario,active_score,leader_score,score_gap'),
        );
        expect(scoreComeback, contains('${turnLimit - 5},production_gap,'));
        expect(scoreComeback, contains(',constructBuilding,cityProduction,'));
        expect(scoreComeback, contains('${turnLimit - 3},research_gap,'));
        expect(scoreComeback, contains(',unlockTechnology,research,'));
        expect(scoreComeback, contains('${turnLimit - 1},economy_gap,'));
        expect(scoreComeback, contains(',collectGold,cityProduction,'));
        expect(scoreComeback, contains('$turnLimit,economy_gap,'));
      },
      timeout: const Timeout(Duration(seconds: 90)),
    );
  });
}
