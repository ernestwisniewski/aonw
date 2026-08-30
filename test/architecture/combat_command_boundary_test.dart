import 'package:flutter_test/flutter_test.dart';

import 'support/combat_command_boundary_guard.dart';
import 'support/map_boundary_source_guard.dart';
import 'support/movement_instance_reference_guard.dart';
import 'support/static_member_reference_guard.dart';

void main() {
  group('combat command boundary', () {
    test('all command paths share exactly one neutral combat kernel', () {
      final sources = productionDartSources();

      expect(
        movementInstanceMemberReferenceCountsByPath(
          sources,
          'CombatCommandResolver',
          'resolve',
        ),
        const {combatDomainAdapterPath: 1, combatPerformanceWorkloadPath: 1},
        reason: 'Unexpected CombatCommandResolver.resolve call-sites.',
      );
      expect(
        movementConstructionReferenceCountsByPath(
          sources,
          'CombatCommandResolver',
        ),
        const {combatDomainAdapterPath: 1, combatPerformanceWorkloadPath: 1},
        reason:
            'Every resolver construction must stay inside its exact reviewed '
            'call-site.',
      );
      expect(
        staticMemberReferenceCountsByPath(
          sources,
          'CombatCommandResolver',
          'resolve',
        ),
        isEmpty,
        reason: 'CombatCommandResolver.resolve must remain an instance API.',
      );

      final runtimeReviewed = {
        for (final path in combatCommandRuntimeCallSites) path: sources[path]!,
      };
      expect(
        movementNamedMemberReferenceCountsByPath(runtimeReviewed, 'resolve'),
        const {combatDomainAdapterPath: 1},
        reason:
            'A reviewed runtime boundary must contain only its one kernel '
            'resolve reference.',
      );
      expect(
        movementNamedMemberReferenceCountsByPath({
          combatPerformanceWorkloadPath:
              sources[combatPerformanceWorkloadPath]!,
        }, 'resolve'),
        const {combatPerformanceWorkloadPath: 2},
        reason:
            'The combat workload must benchmark exactly the neutral, '
            'domain, and GameEngine boundaries.',
      );
    });

    test(
      'legacy adapter is removed and canonical adapter has one consumer',
      () {
        final sources = productionDartSources();
        final runtime = combatCommandRuntimeSources(sources);

        expect(
          sources.keys,
          isNot(contains(endsWith('persistent_combat_command_resolver.dart'))),
        );

        expect(
          movementInstanceMemberReferenceCountsByPath(
            runtime,
            'DomainCombatCommandResolver',
            'resolve',
          ),
          const {combatEngineHandlerPath: 1},
          reason:
              'The canonical combat adapter must have exactly one GameEngine '
              'consumer.',
        );
        expect(
          movementConstructionReferenceCountsByPath(
            runtime,
            'DomainCombatCommandResolver',
          ),
          const {combatEngineHandlerPath: 1},
        );

        final workload = {
          combatPerformanceWorkloadPath:
              sources[combatPerformanceWorkloadPath]!,
        };
        expect(
          movementInstanceMemberReferenceCountsByPath(
            workload,
            'DomainCombatCommandResolver',
            'resolve',
          ),
          {combatPerformanceWorkloadPath: 1},
        );
        expect(
          movementConstructionReferenceCountsByPath(
            workload,
            'DomainCombatCommandResolver',
          ),
          {combatPerformanceWorkloadPath: 1},
        );
        expect(removedPersistentCombatBridgeViolations(sources), isEmpty);
      },
    );

    test('turn combat has exactly two canonical orchestration sites', () {
      final sources = productionDartSources();

      expect(
        staticMemberReferenceCountsByPath(
          sources,
          'TurnCombatOrchestrator',
          'resolve',
        ),
        const {domainTurnCombatResolverPath: 1, combatCommandResolverPath: 1},
        reason: 'Unexpected TurnCombatOrchestrator.resolve call-sites.',
      );
      expect(
        movementInstanceMemberReferenceCountsByPath(
          sources,
          'TurnCombatOrchestrator',
          'resolve',
        ),
        isEmpty,
        reason: 'TurnCombatOrchestrator.resolve must remain a static API.',
      );
    });

    test('kernel stays final and state-container neutral', () {
      final sources = productionDartSources();

      expect(
        combatCommandResolverShapeViolations(
          sources[combatCommandResolverPath],
        ),
        isEmpty,
      );
      expect(combatCommandKernelBoundaryViolations(sources), isEmpty);
    });

    test('combat engine-family routing has an exact reviewed inventory', () {
      final sources = productionDartSources();

      expect(
        staticMemberReferenceCountsByPath(
          sources,
          'GameEngineCommandFamily',
          'combat',
        ),
        const {
          'lib/game/application/services/'
                  'accepted_engine_command_interaction_source.dart':
              1,
          'lib/game/application/services/local_command_resolver.dart': 1,
          'lib/game/application/services/local_combat_command_resolver.dart': 1,
          'packages/aonw_core/lib/game/application/engine/game_engine.dart': 2,
        },
        reason:
            'Every combat family branch must remain an explicit reviewed '
            'GameEngine route.',
      );
      expect(
        movementInstanceMemberReferenceCountsByPath(
          sources,
          'CombatReducer',
          'attackHex',
        ),
        isEmpty,
        reason: 'Authoritative combat must not return to the UI reducer.',
      );
      final dartServerCombatSources = sources.keys.where(
        (path) =>
            path.startsWith('server/lib/src/game/') &&
            path.contains('combat_reducer'),
      );
      expect(
        dartServerCombatSources,
        isEmpty,
        reason: 'Server combat must stay in the Rust runtime.',
      );
      final serverBridge = [
        for (final entry in sources.entries)
          ...sourceSymbolReferenceViolations(
            entry.value,
            entry.key,
            symbol: '_applyCombatCommand',
          ),
      ];
      expect(serverBridge, isEmpty);
    });
  });

  group('combat command guard fails closed', () {
    test(
      'kernel call-site guard catches aliases, tear-offs, and duplicates',
      () {
        final sources = <String, String>{
          'direct.dart': '''
void apply() => const CombatCommandResolver().resolve();
''',
          'alias.dart': '''
typedef FightKernel = CombatCommandResolver;
final makeKernel = FightKernel.new;
void apply() => makeKernel().resolve();
''',
          'prefixed.dart': '''
void apply() => const core.CombatCommandResolver().resolve();
''',
          'tear_off.dart': '''
final resolver = CombatCommandResolver();
final applyCombat = resolver.resolve;
''',
          'duplicate.dart': '''
final resolver = CombatCommandResolver();
void applyOnce() => resolver.resolve();
final applyAgain = resolver.resolve;
''',
          'static.dart': '''
final applyCombat = CombatCommandResolver.resolve;
''',
        };

        expect(
          movementInstanceMemberReferenceCountsByPath(
            sources,
            'CombatCommandResolver',
            'resolve',
          ),
          const {
            'direct.dart': 1,
            'alias.dart': 1,
            'prefixed.dart': 1,
            'tear_off.dart': 1,
            'duplicate.dart': 2,
          },
        );
        expect(
          movementConstructionReferenceCountsByPath(
            sources,
            'CombatCommandResolver',
          ),
          const {
            'direct.dart': 1,
            'alias.dart': 1,
            'prefixed.dart': 1,
            'tear_off.dart': 1,
            'duplicate.dart': 1,
          },
        );
        expect(
          staticMemberReferenceCountsByPath(
            sources,
            'CombatCommandResolver',
            'resolve',
          ),
          const {'static.dart': 1},
        );
      },
    );

    test('adapter guard catches aliases, factories, and member tear-offs', () {
      final sources = <String, String>{
        'direct.dart': '''
void apply() => const PersistentCombatCommandResolver().resolve();
''',
        'alias.dart': '''
typedef LegacyCombat = PersistentCombatCommandResolver;
final makeLegacy = LegacyCombat.new;
void apply() => makeLegacy().resolve();
''',
        'tear_off.dart': '''
final makeLegacy = PersistentCombatCommandResolver.new;
final resolver = makeLegacy();
final applyCombat = resolver.resolve;
''',
      };

      expect(
        movementInstanceMemberReferenceCountsByPath(
          sources,
          'PersistentCombatCommandResolver',
          'resolve',
        ),
        const {'direct.dart': 1, 'alias.dart': 1, 'tear_off.dart': 1},
      );
      expect(
        movementConstructionReferenceCountsByPath(
          sources,
          'PersistentCombatCommandResolver',
        ),
        const {'direct.dart': 1, 'alias.dart': 1, 'tear_off.dart': 1},
      );
    });

    test(
      'turn orchestrator guard catches aliases, tear-offs, and duplicates',
      () {
        final sources = <String, String>{
          'direct.dart': '''
void apply() => TurnCombatOrchestrator.resolve();
''',
          'alias.dart': '''
typedef TurnFight = TurnCombatOrchestrator;
final applyCombat = TurnFight.resolve;
''',
          'prefixed.dart': '''
void apply() => core.TurnCombatOrchestrator.resolve();
''',
          'tear_off.dart': '''
final applyCombat = TurnCombatOrchestrator.resolve;
''',
          'duplicate.dart': '''
void once() => TurnCombatOrchestrator.resolve();
final again = TurnCombatOrchestrator.resolve;
''',
        };

        expect(
          staticMemberReferenceCountsByPath(
            sources,
            'TurnCombatOrchestrator',
            'resolve',
          ),
          const {
            'direct.dart': 1,
            'alias.dart': 1,
            'prefixed.dart': 1,
            'tear_off.dart': 1,
            'duplicate.dart': 2,
          },
        );
      },
    );

    test('resolver shape rejects a non-final parallel kernel', () {
      expect(
        combatCommandResolverShapeViolations('''
class CombatCommandResolver {
  void resolve() {}
}
'''),
        contains('CombatCommandResolver must remain a final class'),
      );
    });

    test('kernel boundary catches aliases and root or server imports', () {
      final sources = <String, String>{
        combatCommandResolverPath: '''
import 'package:aonw/game/domain/game_state.dart';
final class CombatCommandResolver {
  PersistentGameState? leakedState;
}
''',
        combatCommandStatePath: '''
typedef HiddenMap = WorldMap;
HiddenMap? leakedMap;
''',
        combatCommandResultPath: '''
import 'package:aonw_server/src/generated/protocol.dart';
import '../../../../../../../server/lib/src/game/reducer.dart';
DomainState? leakedState;
''',
      };

      final report = combatCommandKernelBoundaryViolations(sources).join('\n');
      for (final expected in const {
        'PersistentGameState',
        'WorldMap',
        'HiddenMap',
        'DomainState',
        'package:aonw/',
        'package:aonw_server/',
        'server/lib/src/game/reducer.dart',
      }) {
        expect(report, contains(expected));
      }
    });

    test('removed persistent result bridge is caught as call or tear-off', () {
      final violations = removedPersistentCombatBridgeViolations({
        'bridge.dart': '''
void _fromPersistentCombatResult() {}
void apply() {
  _fromPersistentCombatResult();
  final bridge = _fromPersistentCombatResult;
}
''',
      });

      expect(violations, hasLength(3));
      expect(
        violations.every((entry) => entry.contains('bridge.dart:')),
        isTrue,
      );
    });
  });
}
