import 'package:flutter_test/flutter_test.dart';

import 'support/combat_command_boundary_guard.dart';
import 'support/map_boundary_source_guard.dart';
import 'support/movement_instance_reference_guard.dart';
import 'support/static_member_reference_guard.dart';

void main() {
  test('combat animation facts have one exact end-to-end route', () {
    final sources = productionDartSources();

    expect(
      movementConstructionReferenceCountsByPath(sources, 'CombatAnimationFact'),
      const {
        combatAnimationFactCodecPath: 1,
        combatEngineHandlerPath: 1,
        combatDomainEventProjectorPath: 1,
      },
      reason:
          'Facts may only be created by the engine, decoded at the neutral '
          'codec, or projected from ordered events at the presentation boundary.',
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'CombatAnimationFactCodec',
        'fromEventPayloads',
      ),
      const {combatEventCodecPath: 2},
      reason: 'Wire fact decoding must stay behind EventCodec.',
    );
    expect(
      removedProductionSymbolViolations(
        sources,
        symbol: 'CombatAnimationFactProjector',
        uriSuffix: 'combat_animation_fact_projector.dart',
      ),
      isEmpty,
      reason: 'The generic mutable-state projector must stay removed.',
    );

    const projectorCalls = {
      combatReplayEffectPlannerPath: 1,
      combatGameActionsProviderPath: 1,
      combatHiddenAiPlaybackPath: 1,
      combatGameStateRendererEffectsPath: 1,
    };
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'DomainEventPresentationProjector',
        'projectObservedBatch',
      ),
      projectorCalls,
    );
    expect(
      staticCallNamedArgumentViolations(
        sources,
        targetType: 'DomainEventPresentationProjector',
        methodName: 'projectObservedBatch',
        argumentName: 'visibleMovementExecutions',
        expectedCalls: projectorCalls,
      ),
      isEmpty,
    );

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'GameEventRendererEffectMapper',
        'effectsFor',
      ),
      const {combatDomainEventProjectorPath: 1},
    );
  });

  test('movement fact guard rejects omitted and duplicate arguments', () {
    final violations = staticCallNamedArgumentViolations(
      const {
        'missing.dart': '''
void render() => DomainEventPresentationProjector.projectObservedBatch(events: events);
''',
        'duplicate.dart': '''
void render() => DomainEventPresentationProjector.projectObservedBatch(
  visibleMovementExecutions: first,
  visibleMovementExecutions: second,
);
''',
      },
      targetType: 'DomainEventPresentationProjector',
      methodName: 'projectObservedBatch',
      argumentName: 'visibleMovementExecutions',
      expectedCalls: const {'missing.dart': 1, 'duplicate.dart': 1},
    );

    expect(violations, hasLength(2));
    expect(
      violations.singleWhere((entry) => entry.contains('missing.dart')),
      contains('exactly one visibleMovementExecutions'),
    );
    expect(
      violations.singleWhere((entry) => entry.contains('duplicate.dart')),
      contains('exactly one visibleMovementExecutions'),
    );
  });
}
