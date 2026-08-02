import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

const _scenarioLineLimit = 500;
const _fixtureLineLimit = 500;

void main() {
  const suites = [
    _SuitePolicy(
      host: 'test/game/game_hud_test.dart',
      fixtureParts: [
        'support/game_hud_shared_fixtures.dart',
        'support/game_hud_ai_handoff_fixtures.dart',
        'support/game_hud_coachmark_fixtures.dart',
        'support/game_hud_notification_fixtures.dart',
      ],
      minimumScenarioParts: 11,
    ),
    _SuitePolicy(
      host: 'test/game/game_providers_test.dart',
      fixtureParts: [
        'support/game_provider_shared_fixtures.dart',
        'support/game_provider_multiplayer_fixtures.dart',
      ],
      minimumScenarioParts: 8,
    ),
    _SuitePolicy(
      host: 'test/game/game_renderer_keyboard_test.dart',
      fixtureParts: ['support/game_renderer_keyboard_shared_fixtures.dart'],
      minimumScenarioParts: 7,
    ),
    _SuitePolicy(
      host: 'server/test/multiplayer/realtime_match_hub_test.dart',
      fixtureParts: [
        'support/realtime_match_hub_store_fixture.dart',
        'support/realtime_match_hub_diplomacy_fixture.dart',
      ],
      minimumScenarioParts: 8,
    ),
    _SuitePolicy(
      host: 'packages/aonw_core/test/ai/basic_strategy_test.dart',
      fixtureParts: [
        'support/basic_strategy_fixtures.dart',
        'support/basic_strategy_settler_safety_fixtures.dart',
      ],
      minimumScenarioParts: 11,
    ),
    _SuitePolicy(
      host: 'packages/aonw_core/test/ai/mcts/mcts_action_generator_test.dart',
      fixtureParts: ['support/mcts_action_generator_fixtures.dart'],
      minimumScenarioParts: 12,
    ),
  ];

  for (final suite in suites) {
    test('${suite.host} stays a thin scenario host', () {
      final host = File(suite.host);
      final source = host.readAsStringSync();
      final partUris = _partUris(host);
      final scenarios = partUris
          .where((uri) => uri.endsWith('_scenarios.dart'))
          .toList();

      expect(host.readAsLinesSync().length, lessThanOrEqualTo(100));
      expect(source, isNot(contains('test(')));
      expect(source, isNot(contains('testWidgets(')));
      expect(
        scenarios,
        hasLength(greaterThanOrEqualTo(suite.minimumScenarioParts)),
      );
      expect(partUris, containsAll(suite.fixtureParts));

      for (final uri in scenarios) {
        final scenario = File.fromUri(host.uri.resolve(uri));
        final scenarioSource = scenario.readAsStringSync();
        expect(
          scenario.readAsLinesSync().length,
          lessThanOrEqualTo(_scenarioLineLimit),
          reason:
              '${scenario.path} must split before it becomes a new monolith.',
        );
        expect(scenarioSource, contains('part of '), reason: scenario.path);
        expect(
          RegExp(r'void _register\w+Scenarios\(\)').allMatches(scenarioSource),
          hasLength(1),
          reason: '${scenario.path} must own one scenario registration.',
        );
      }

      for (final uri in suite.fixtureParts) {
        final fixture = File.fromUri(host.uri.resolve(uri));
        expect(
          fixture.readAsLinesSync().length,
          lessThanOrEqualTo(_fixtureLineLimit),
          reason: '${fixture.path} must remain a focused fixture builder.',
        );
      }
    });
  }
}

List<String> _partUris(File host) {
  final unit = parseString(
    content: host.readAsStringSync(),
    path: host.path,
  ).unit;
  return [
    for (final directive in unit.directives.whereType<PartDirective>())
      directive.uri.stringValue!,
  ];
}

final class _SuitePolicy {
  const _SuitePolicy({
    required this.host,
    required this.fixtureParts,
    required this.minimumScenarioParts,
  });

  final String host;
  final List<String> fixtureParts;
  final int minimumScenarioParts;
}
