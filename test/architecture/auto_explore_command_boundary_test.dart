import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/movement_command_boundary_guard.dart';
import 'support/movement_instance_reference_guard.dart';
import 'support/static_member_reference_guard.dart';

void main() {
  test('auto-explore kernel and adapter expose only reviewed APIs', () {
    final sources = productionDartSources();

    expect(autoExplorePublicApiViolations(sources), isEmpty);
    expect(autoExploreClosedImportViolations(sources), isEmpty);
    expect(
      autoExploreResolverForwardingViolations(sources[autoExploreResolverPath]),
      isEmpty,
    );
  });

  test('runtime and diagnostic call-sites remain separate and exact', () {
    final sources = productionDartSources();
    final runtime = autoExploreRuntimeSources(sources);
    final diagnostic = {
      autoExploreDiagnosticWorkloadPath:
          sources[autoExploreDiagnosticWorkloadPath]!,
    };

    expect(
      movementInstanceMemberReferenceCountsByPath(
        runtime,
        'AutoExploreCommandResolver',
        'resolve',
      ),
      const {
        autoExplorePersistentAdapterPath: 1,
        autoExploreLocalCallSite: 1,
        autoExploreServerCallSite: 1,
      },
    );
    expect(
      movementConstructionReferenceCountsByPath(
        runtime,
        'AutoExploreCommandResolver',
      ),
      const {
        autoExplorePersistentAdapterPath: 1,
        autoExploreLocalCallSite: 1,
        autoExploreServerCallSite: 1,
      },
    );
    expect(
      staticMemberReferenceCountsByPath(
        runtime,
        'AutoExploreCommandResolver',
        'resolve',
      ),
      isEmpty,
    );
    expect(
      movementInstanceMemberReferenceCountsByPath(
        runtime,
        'PersistentAutoExploreCommandResolver',
        'resolve',
      ),
      const {movementMctsConsumerPath: 1, movementEconomyConsumerPath: 1},
      reason: 'Only full-state AI compatibility consumers may use the adapter.',
    );
    expect(
      movementConstructionReferenceCountsByPath(
        runtime,
        'PersistentAutoExploreCommandResolver',
      ),
      const {movementMctsConsumerPath: 1, movementEconomyConsumerPath: 1},
    );

    expect(
      movementInstanceMemberReferenceCountsByPath(
        runtime,
        'PersistentUnitActionResolver',
        'autoExploreUnit',
      ),
      isEmpty,
      reason: 'The removed full-state AutoExplore route must not return.',
    );

    expect(
      movementInstanceMemberReferenceCountsByPath(
        diagnostic,
        'AutoExploreCommandResolver',
        'resolve',
      ),
      const {autoExploreDiagnosticWorkloadPath: 1},
    );
    expect(
      movementConstructionReferenceCountsByPath(
        diagnostic,
        'AutoExploreCommandResolver',
      ),
      const {autoExploreDiagnosticWorkloadPath: 1},
    );
    expect(
      movementNamedMemberReferenceCountsByPath(diagnostic, 'resolve'),
      const {autoExploreDiagnosticWorkloadPath: 1},
    );
  });

  test('direct consumers do not restore compatibility state bridges', () {
    final sources = productionDartSources();
    final local = sources[autoExploreLocalCallSite]!;
    final server = sources[autoExploreServerCallSite]!;

    expect(
      namedTypeReferencesInSource(
        local,
        path: autoExploreLocalCallSite,
      ).intersection(const {
        'CanonicalGameSnapshot',
        'DomainState',
        'PersistentAutoExploreCommandResolver',
        'PersistentAutoExploreCommandResult',
        'PersistentGameState',
        'PersistentMoveUnitResolver',
        'PersistentMoveUnitResult',
        'PersistentUnitActionResolver',
        'PersistentUnitActionResult',
      }),
      isEmpty,
    );
    expect(
      namedTypeReferencesInSource(
        server,
        path: autoExploreServerCallSite,
      ).intersection(const {
        'DomainState',
        'PersistentAutoExploreCommandResolver',
        'PersistentAutoExploreCommandResult',
        'PersistentMoveUnitResolver',
        'PersistentMoveUnitResult',
        'PersistentUnitActionResolver',
        'PersistentUnitActionResult',
      }),
      isEmpty,
    );
    for (final member in const {'toDomainState', 'toPersistentState'}) {
      expect(
        movementNamedMemberReferenceCountsByPath({
          autoExploreLocalCallSite: local,
          autoExploreServerCallSite: server,
        }, member),
        isEmpty,
        reason: '$member must not bridge either direct consumer.',
      );
    }
  });

  test('result guard rejects a borrowed mutable event list', () {
    final sources = productionDartSources();
    final mutable = sources[autoExploreResultPath]!.replaceFirst(
      'List<GameEvent>.unmodifiable(events)',
      'events.toList()',
    );

    expect(
      autoExploreResultShapeViolations(mutable),
      contains('accepted result must own a defensive unmodifiable event list'),
    );
  });

  test('phase guard rejects an unreviewed private policy member', () {
    final sources = productionDartSources();
    final widened = sources[autoExplorePhasePath]!.replaceFirst(
      '  bool get isContinuation => this == continuation;',
      '  bool get isContinuation => this == continuation;\n'
          '  bool get _backdoor => true;',
    );

    expect(
      autoExplorePhaseShapeViolations(widened),
      contains(
        'AutoExploreCommandPhase must contain only the reviewed continuation '
        'policy getter',
      ),
    );
  });

  test('forwarding guard rejects commandFor and dropped constraints', () {
    final sources = productionDartSources();
    final widened = sources[autoExploreResolverPath]!
        .replaceFirst('.targetFor(', '.commandFor(')
        .replaceFirst(
          'pathConstraints: target.pathConstraints',
          'pathConstraints: const MovementCommandPathConstraints.none()',
        );

    expect(
      autoExploreResolverForwardingViolations(widened).join('\n'),
      allOf(
        contains('targetFor exactly once'),
        contains('exact target constraints'),
      ),
    );
  });

  test('closed imports reject a state-container bridge', () {
    final sources = productionDartSources();
    sources[autoExploreResolverPath] =
        "import 'package:aonw_core/game/domain/state/"
        "persistent_game_state.dart';\n"
        '${sources[autoExploreResolverPath]!}\n'
        'PersistentGameState? leakedState;';

    expect(
      autoExploreClosedImportViolations(sources).join('\n'),
      allOf(contains('imports'), contains('PersistentGameState')),
    );
  });
}
