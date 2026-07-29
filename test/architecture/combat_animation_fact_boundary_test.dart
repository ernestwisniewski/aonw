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
        combatAnimationFactUpcasterPath: 1,
      },
      reason:
          'Facts may only be created by the engine, decoded at the neutral '
          'codec, or upcast at the explicit historical replay boundary.',
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'HistoricalCombatAnimationFactUpcaster',
        'fromEvents',
      ),
      const {combatReplayEffectPlannerPath: 1},
      reason: 'Historical combat reconstruction must have one consumer.',
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

    const rendererBuilderCalls = {
      combatReplayEffectPlannerPath: 1,
      combatGameActionsProviderPath: 1,
      combatHiddenAiPlaybackPath: 1,
    };
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'GameRendererEffectSequenceBuilder',
        'build',
      ),
      rendererBuilderCalls,
    );
    expect(
      staticCallNamedArgumentViolations(
        sources,
        targetType: 'GameRendererEffectSequenceBuilder',
        methodName: 'build',
        argumentName: 'combatAnimations',
        expectedCalls: rendererBuilderCalls,
      ),
      isEmpty,
    );

    const eventMapperCalls = {
      combatRendererSequenceBuilderPath: 1,
      combatExternalSnapshotResolverPath: 1,
    };
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'GameEventRendererEffectMapper',
        'effectsFor',
      ),
      eventMapperCalls,
    );
    expect(
      staticCallNamedArgumentViolations(
        sources,
        targetType: 'GameEventRendererEffectMapper',
        methodName: 'effectsFor',
        argumentName: 'combatAnimations',
        expectedCalls: eventMapperCalls,
      ),
      isEmpty,
    );

    const externalSnapshotCalls = {combatGameStateRendererEffectsPath: 1};
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'ExternalSnapshotRendererEffectResolver',
        'resolve',
      ),
      externalSnapshotCalls,
    );
    expect(
      staticCallNamedArgumentViolations(
        sources,
        targetType: 'ExternalSnapshotRendererEffectResolver',
        methodName: 'resolve',
        argumentName: 'combatAnimations',
        expectedCalls: externalSnapshotCalls,
      ),
      isEmpty,
    );
  });

  test('fact forwarding guard rejects omitted and duplicate arguments', () {
    final violations = staticCallNamedArgumentViolations(
      const {
        'missing.dart': '''
void render() => GameRendererEffectSequenceBuilder.build(events: events);
''',
        'duplicate.dart': '''
void render() => GameRendererEffectSequenceBuilder.build(
  combatAnimations: first,
  combatAnimations: second,
);
''',
      },
      targetType: 'GameRendererEffectSequenceBuilder',
      methodName: 'build',
      argumentName: 'combatAnimations',
      expectedCalls: const {'missing.dart': 1, 'duplicate.dart': 1},
    );

    expect(violations, hasLength(2));
    expect(
      violations.singleWhere((entry) => entry.contains('missing.dart')),
      contains('exactly one combatAnimations'),
    );
    expect(
      violations.singleWhere((entry) => entry.contains('duplicate.dart')),
      contains('exactly one combatAnimations'),
    );
  });
}
