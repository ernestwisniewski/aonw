import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/movement_preview_kernel_guard.dart';

void main() {
  test(
    'preview confirmation delegates authoritative movement to the kernel',
    () {
      final source = productionDartSources()[movementPreviewReducerPath];

      expect(movementPreviewKernelViolations(source), isEmpty);
    },
  );

  test('preview guard rejects a second manual movement executor', () {
    final violations = movementPreviewKernelViolations('''
abstract final class _MovePreviewReducer {
  static GameStateTransition confirmPreview(
    GameState state,
    MapTraversalView mapView, {
    required GameCommandContext context,
    required FogOfWarService fogOfWarService,
  }) {
    final plan = UnitMovementPathfinder().plan();
    final resolved = MovementCommandResolver().resolve();
    MovementCommandExecutor().execute();
    final units = replaceUnit(state.units, unit.copyWith());
    final queued = unit.copyWithQueuedPath(_queuedPathFor(plan));
    final fog = fogOfWarService.recomputeAfterUnitMove();
    withDiscoveredDiplomaticContacts(state);
    final event = UnitMovedEvent();
    final effect = AnimateUnitMoveEffect();
    final transition = MovementReducer.moveUnit(
      state,
      MoveUnitCommand(),
      mapView,
      context: context,
      fogOfWarService: fogOfWarService,
    );
    return GameStateTransition(
      state: transition.state,
      events: transition.events,
      uiEffects: transition.uiEffects,
    );
  }
}
''');
    final report = violations.join('\n');

    for (final forbidden in const [
      'UnitMovementPathfinder',
      'MovementCommandResolver',
      'MovementCommandExecutor',
      'replaceUnit',
      'copyWith',
      'copyWithQueuedPath',
      '_queuedPathFor',
      'recomputeAfterUnitMove',
      'withDiscoveredDiplomaticContacts',
      'UnitMovedEvent',
      'AnimateUnitMoveEffect',
    ]) {
      expect(report, contains(forbidden));
    }
  });

  test('preview guard fails closed when delegation output is discarded', () {
    final violations = movementPreviewKernelViolations(
      _previewFixture(
        result: 'return GameStateTransition(state: transition.state);',
      ),
    );

    expect(
      violations,
      containsAll([
        'confirmPreview must preserve the delegated transition events',
        'confirmPreview must preserve the delegated transition UI effects',
      ]),
    );
  });

  test('preview guard rejects altered or missing execution context', () {
    final foreignContext = movementPreviewKernelViolations(
      _previewFixture(contextArgument: 'context: otherContext,'),
    );
    final missingFog = movementPreviewKernelViolations(
      _previewFixture(fogArgument: ''),
    );

    expect(
      foreignContext,
      contains('confirmPreview must forward context: context exactly'),
    );
    expect(
      missingFog,
      contains(
        'confirmPreview must forward fogOfWarService: fogOfWarService exactly',
      ),
    );
    expect(
      missingFog,
      contains(
        'confirmPreview must not widen the MovementReducer.moveUnit call',
      ),
    );
  });

  test('preview guard rejects altered command forwarding', () {
    final violations = movementPreviewKernelViolations(
      _previewFixture(
        command:
            'MoveUnitCommand(other.id, preview.targetCol, preview.targetRow)',
      ),
    );

    expect(
      violations,
      contains(
        'confirmPreview must forward workState, the selected preview target, '
        'and mapView exactly',
      ),
    );
  });

  test('preview guard catches executor aliases and tear-offs', () {
    final violations = movementPreviewKernelViolations(
      _previewFixture(
        prelude: '''
typedef HiddenPathfinder = UnitMovementPathfinder;
final hiddenReplace = replaceUnit;
''',
        beforeDelegation: '''
final makePathfinder = HiddenPathfinder.new;
final emitMove = UnitMovedEvent.new;
hiddenReplace(state.units, makePathfinder());
emitMove();
''',
      ),
    );
    final report = violations.join('\n');

    expect(report, contains('HiddenPathfinder'));
    expect(report, contains('hiddenReplace'));
    expect(report, contains('UnitMovedEvent'));
  });

  test('preview guard follows a called helper through a top-level alias', () {
    final violations = movementPreviewKernelViolations(
      _previewFixture(
        prelude: '''
final hiddenManualExecutor = _MovePreviewReducer._manualExecutor;
''',
        extraMethod: '''
static void _manualExecutor(GameState state) {
  MovementCommandExecutor().execute();
  state.copyWith();
  MovementReducer.moveUnit(state, command, mapView);
}
''',
        beforeDelegation: 'hiddenManualExecutor(state);',
      ),
    );
    final report = violations.join('\n');

    expect(report, contains('MovementCommandExecutor'));
    expect(report, contains('copyWith'));
    expect(
      violations,
      contains(
        'confirmPreview must call MovementReducer.moveUnit exactly once',
      ),
    );
  });

  test('preview guard ignores dead transition member references', () {
    final violations = movementPreviewKernelViolations(
      _previewFixture(
        result: '''
transition.events;
transition.uiEffects;
return GameStateTransition(
  state: next,
  events: const [],
  uiEffects: const [],
);''',
      ),
    );

    expect(
      violations,
      containsAll([
        'confirmPreview must preserve the delegated transition events',
        'confirmPreview must preserve the delegated transition UI effects',
      ]),
    );
  });

  test('preview guard rejects altered state and interaction projection', () {
    final alteredState = movementPreviewKernelViolations(
      _previewFixture(
        result: '''
return GameStateTransition(
  state: workState,
  events: transition.events,
  uiEffects: transition.uiEffects,
);''',
      ),
    );
    final alteredProjection = movementPreviewKernelViolations(
      _previewFixture(
        stateProjection: '''
final updatedUnit = transition.state.unitById(selected.id);
final completedNow = updatedUnit != null && updatedUnit.queuedPath == null;
final next = transition.state.copyWithInteraction(movePreview: null);
''',
      ),
    );

    expect(
      alteredState,
      contains('confirmPreview must preserve the delegated transition state'),
    );
    expect(
      alteredProjection,
      contains('confirmPreview must preserve the delegated transition state'),
    );
  });

  test('preview guard rejects altered delegation input bindings', () {
    final violations = movementPreviewKernelViolations(
      _previewFixture(
        inputBindings: '''
final workState = foreignState.copyWithInteraction(movePreview: null);
final selected = foreignState.selectedUnit;
final preview = foreignState.movePreview;
''',
      ),
    );

    expect(
      violations,
      contains(
        'confirmPreview must derive workState, selected, and preview from state',
      ),
    );
  });

  test('preview guard allows read-only planning outside confirmPreview', () {
    final violations = movementPreviewKernelViolations(
      _previewFixture(
        extraMethod: '''
static void setPreview() {
  UnitMovementPathfinder().plan();
}
''',
      ),
    );

    expect(violations, isEmpty);
  });
}

String _previewFixture({
  String prelude = '',
  String extraMethod = '',
  String beforeDelegation = '',
  String command =
      'MoveUnitCommand(selected.id, preview.targetCol, preview.targetRow)',
  String contextArgument = 'context: context,',
  String fogArgument = 'fogOfWarService: fogOfWarService,',
  String inputBindings = '''
final workState = state.copyWithInteraction(movePreview: null);
final selected = state.selectedUnit;
final preview = state.movePreview;
''',
  String stateProjection = '''
final updatedUnit = transition.state.unitById(selected.id);
final completedNow = updatedUnit != null && updatedUnit.queuedPath == null;
final next = identical(transition.state, workState)
    ? MovementReducer._clearMoveTargeting(transition.state)
    : transition.state.copyWithInteraction(
        moveCommandActive: completedNow,
        movePreview: null,
      );
''',
  String result = '''
return GameStateTransition(
  state: next,
  events: transition.events,
  uiEffects: transition.uiEffects,
);''',
}) =>
    '''
$prelude
abstract final class _MovePreviewReducer {
  $extraMethod
  static GameStateTransition confirmPreview(
    GameState state,
    MapTraversalView mapView, {
    required GameCommandContext context,
    required FogOfWarService fogOfWarService,
  }) {
$beforeDelegation
    $inputBindings
    final transition = MovementReducer.moveUnit(
      workState,
      $command,
      mapView,
      $contextArgument
      $fogArgument
    );
    $stateProjection
    $result
  }
}
''';
