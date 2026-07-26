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
        const {
          combatPersistentAdapterPath: 1,
          combatDomainAdapterPath: 1,
          combatLocalCallSite: 1,
          combatServerCallSite: 1,
          combatPerformanceWorkloadPath: 1,
        },
        reason: 'Unexpected CombatCommandResolver.resolve call-sites.',
      );
      expect(
        movementConstructionReferenceCountsByPath(
          sources,
          'CombatCommandResolver',
        ),
        const {
          combatPersistentAdapterPath: 1,
          combatDomainAdapterPath: 1,
          combatLocalCallSite: 1,
          combatServerCallSite: 1,
          combatPerformanceWorkloadPath: 1,
        },
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
        const {
          combatPersistentAdapterPath: 1,
          combatDomainAdapterPath: 1,
          combatLocalCallSite: 1,
          combatServerCallSite: 1,
        },
        reason:
            'A reviewed runtime boundary must contain only its one kernel '
            'resolve reference.',
      );
      expect(
        movementNamedMemberReferenceCountsByPath({
          combatPerformanceWorkloadPath:
              sources[combatPerformanceWorkloadPath]!,
        }, 'resolve'),
        const {combatPerformanceWorkloadPath: 3},
        reason:
            'The combat workload must benchmark exactly the neutral, '
            'persistent, and domain resolver boundaries.',
      );
    });

    test('legacy adapters have no runtime routing consumers', () {
      final sources = productionDartSources();
      final runtime = combatCommandRuntimeSources(sources);

      for (final adapter in const {
        'PersistentCombatCommandResolver',
        'DomainCombatCommandResolver',
      }) {
        expect(
          movementInstanceMemberReferenceCountsByPath(
            runtime,
            adapter,
            'resolve',
          ),
          isEmpty,
          reason: '$adapter must not route a runtime command.',
        );
        expect(
          movementConstructionReferenceCountsByPath(runtime, adapter),
          isEmpty,
          reason: '$adapter must not be constructed by runtime production.',
        );
        expect(
          staticMemberReferenceCountsByPath(runtime, adapter, 'resolve'),
          isEmpty,
          reason: '$adapter must not gain a static runtime route.',
        );
      }

      final workload = {
        combatPerformanceWorkloadPath: sources[combatPerformanceWorkloadPath]!,
      };
      for (final adapter in const {
        'PersistentCombatCommandResolver',
        'DomainCombatCommandResolver',
      }) {
        expect(
          movementInstanceMemberReferenceCountsByPath(
            workload,
            adapter,
            'resolve',
          ),
          {combatPerformanceWorkloadPath: 1},
        );
        expect(movementConstructionReferenceCountsByPath(workload, adapter), {
          combatPerformanceWorkloadPath: 1,
        });
      }

      final forbiddenAdapterTypes = typeNamesBackedBy(sources, const {
        'PersistentCombatCommandResolver',
        'PersistentCombatCommandResult',
      });
      for (final path in const {combatLocalCallSite, combatServerCallSite}) {
        expect(
          namedTypeReferencesInSource(
            sources[path]!,
            path: path,
          ).intersection(forbiddenAdapterTypes),
          isEmpty,
          reason: '$path must not restore the persistent combat adapter.',
        );
      }
      expect(removedPersistentCombatBridgeViolations(sources), isEmpty);
    });

    test('turn combat has exactly three canonical orchestration sites', () {
      final sources = productionDartSources();

      expect(
        staticMemberReferenceCountsByPath(
          sources,
          'TurnCombatOrchestrator',
          'resolve',
        ),
        const {
          persistentTurnCombatResolverPath: 1,
          domainTurnCombatResolverPath: 1,
          combatCommandResolverPath: 1,
        },
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
typedef HiddenMap = MapData;
HiddenMap? leakedMap;
''',
        combatCommandResultPath: '''
import 'package:aonw_server/src/generated/protocol.dart';
import '../../../../../../../server/lib/src/multiplayer/reducer.dart';
DomainState? leakedState;
''',
      };

      final report = combatCommandKernelBoundaryViolations(sources).join('\n');
      for (final expected in const {
        'GameState',
        'PersistentGameState',
        'MapData',
        'HiddenMap',
        'DomainState',
        'package:aonw/',
        'package:aonw_server/',
        'server/lib/src/multiplayer/reducer.dart',
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
