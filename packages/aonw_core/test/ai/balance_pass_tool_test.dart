import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('balance_pass tool', () {
    test('writes markdown and json balance summaries', () async {
      final outputDir = await Directory.systemTemp.createTemp(
        'aonw_ai_balance_',
      );
      addTearDown(() async {
        if (await outputDir.exists()) {
          await outputDir.delete(recursive: true);
        }
      });

      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'tool/balance_pass.dart',
        '--games',
        '1',
        '--turns',
        '4',
        '--difficulty',
        'easy',
        '--primary-civ',
        'canada',
        '--civs',
        'spain,korea,sweden',
        '--seed',
        '5000',
        '--out',
        outputDir.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

      final reportFile = File('${outputDir.path}/balance-pass-report.md');
      final jsonFile = File('${outputDir.path}/balance-pass-summary.json');
      final gameCsvFile = File('${outputDir.path}/balance-pass-game-0.csv');

      expect(await reportFile.exists(), isTrue);
      expect(await jsonFile.exists(), isTrue);
      expect(await gameCsvFile.exists(), isTrue);

      final report = await reportFile.readAsString();
      expect(report, contains('# AI Balance Pass'));
      expect(report, contains('## Players'));
      expect(report, contains('## Opening Survival'));
      expect(report, contains('## Second-City Recovery'));
      expect(report, contains('## Civilizations'));
      expect(report, contains('## Opening Survival By Civilization'));
      expect(report, contains('## Second-City Recovery By Civilization'));
      expect(report, contains('| City dist |'));
      expect(report, contains('| Attacks |'));
      expect(report, contains('| Avg first city |'));
      expect(report, contains('| Avg second city |'));
      expect(report, contains('| Avg third city |'));
      expect(report, contains('| Lost 2nd city |'));
      expect(report, contains('| Canada |'));
      expect(report, contains('| Spain |'));
      expect(report, contains('| Korea |'));
      expect(report, contains('| Sweden |'));
      expect(await gameCsvFile.readAsString(), contains('player_id,turn'));

      final json =
          jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;
      final parameters = json['parameters'] as Map<String, dynamic>;
      final countries = json['countries'] as List<dynamic>;
      final players = json['players'] as List<dynamic>;
      expect(parameters['games'], 1);
      expect(parameters['targetMinutes'], isNull);
      expect(parameters['estimatedTurnSeconds'], 30);
      expect(parameters['rawTurnOverride'], isTrue);
      expect(parameters['turns'], 4);
      expect(parameters['difficulty'], 'easy');
      expect(parameters['primaryCiv'], 'canada');
      expect(parameters['civs'], ['spain', 'korea', 'sweden']);
      expect(json['completedGameCount'], 1);
      expect(json['crashCount'], 0);
      expect(json['totalRejectedCommands'], greaterThanOrEqualTo(0));
      expect(
        countries.map((entry) => (entry as Map<String, dynamic>)['country']),
        containsAll(['canada', 'spain', 'korea', 'sweden']),
      );
      final playerSummary = players.first as Map<String, dynamic>;
      expect(playerSummary, containsPair('averageAttackCommands', isA<num>()));
      expect(
        playerSummary['openingSurvival'],
        containsPair('settlerLostBeforeFirstCityRate', isA<num>()),
      );
      expect(
        playerSummary['expansionRecovery'],
        containsPair('secondCityCompletionRate', isA<num>()),
      );
      expect(
        playerSummary['expansionRecovery'],
        containsPair('thirdCityCompletionRate', isA<num>()),
      );
      expect(
        playerSummary['expansionRecovery'],
        containsPair('secondCityLostAfterFoundingRate', isA<num>()),
      );
      expect(
        playerSummary['expansionRecovery'],
        containsPair('averageTwoCityStartProjectCommands', isA<num>()),
      );
    });
  });
}
