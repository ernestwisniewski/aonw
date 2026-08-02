import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_effect_logical_timeline.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';

typedef DomainEventEffectProjection = ({
  int eventSequence,
  String eventType,
  String policy,
  List<RendererEffect> effects,
});

/// Builds the canonical timeline after domain events have been projected.
abstract final class DomainEventAnimationScheduler {
  static ProjectedGameEffectBatch schedule({
    required PresentationBatchIdentity identity,
    required Iterable<RendererEffect> interactionEffects,
    required Iterable<DomainEventEffectProjection> eventProjections,
  }) {
    final plans = _schedulePlans(identity, eventProjections);
    return ProjectedGameEffectBatch(
      identity: identity,
      projectedInteractionEffects: _scheduleInteraction(
        identity,
        interactionEffects,
      ),
      animationPlans: plans,
      domainEffects: _animationsInTimelineOrder(plans),
    );
  }

  static List<AnimationPlan> _schedulePlans(
    PresentationBatchIdentity identity,
    Iterable<DomainEventEffectProjection> projections,
  ) {
    var startOffset = Duration.zero;
    var ordinal = 0;
    final builders = <String, _AnimationPlanBuilder>{};
    for (final projection in projections) {
      final eventId = identity.eventId(projection.eventSequence);
      final builder = builders.putIfAbsent(
        eventId,
        () => _AnimationPlanBuilder(
          eventId: eventId,
          eventType: projection.eventType,
          policy: projection.policy,
          eventSequence: projection.eventSequence,
          startOffset: startOffset,
        ),
      );
      for (final effect in projection.effects) {
        final duration = GameEffectLogicalTimeline.durationFor(effect);
        builder.animations.add(
          ProjectedGameEffect(
            effect: effect,
            sourceId: identity.sourceId,
            eventId: eventId,
            animationId:
                '$eventId:${effect.runtimeType}:'
                '${_effectEntity(effect)}:${builder.nextEventOrdinal}',
            eventOffset: identity.eventOffset,
            eventSequence: projection.eventSequence,
            authoritativeTick: identity.resolvedAuthoritativeTick,
            authoritativeStartMicrosUtc:
                identity.resolvedAuthoritativeStartMicrosUtc,
            ordinal: ordinal,
            startOffset: startOffset,
            duration: duration,
          ),
        );
        startOffset += duration;
        ordinal += 1;
        builder.nextEventOrdinal += 1;
      }
    }
    return [
      for (final builder in builders.values)
        AnimationPlan(
          eventId: builder.eventId,
          eventType: builder.eventType,
          policy: builder.policy,
          batchSequence: identity.eventOffset,
          eventSequence: builder.eventSequence,
          authoritativeTick: identity.resolvedAuthoritativeTick,
          authoritativeStartMicrosUtc:
              identity.resolvedAuthoritativeStartMicrosUtc,
          startOffset: builder.startOffset,
          animations: builder.animations,
        ),
    ];
  }

  static List<ProjectedGameEffect> _scheduleInteraction(
    PresentationBatchIdentity identity,
    Iterable<RendererEffect> effects,
  ) {
    final interactionId =
        identity.interactionId ??
        '${identity.sourceId}:${identity.eventOffset}:interaction';
    var ordinal = 0;
    return [
      for (final effect in effects)
        ProjectedGameEffect(
          effect: effect,
          sourceId: identity.sourceId,
          eventId: '${identity.sourceId}:interaction:$interactionId',
          animationId:
              '${identity.sourceId}:interaction:$interactionId:'
              '${effect.runtimeType}:${_effectEntity(effect)}:${ordinal++}',
          eventOffset: identity.eventOffset,
          eventSequence: -1,
          authoritativeTick: identity.resolvedAuthoritativeTick,
          authoritativeStartMicrosUtc:
              identity.resolvedAuthoritativeStartMicrosUtc,
          ordinal: ordinal - 1,
          startOffset: Duration.zero,
          duration: GameEffectLogicalTimeline.durationFor(effect),
          isInteraction: true,
        ),
    ];
  }

  static String _effectEntity(RendererEffect effect) {
    return switch (effect) {
      AnimateUnitMoveEffect(:final unitId) => unitId,
      PlayCombatAnimationEffect(:final attackerUnitId, :final defenderUnitId) =>
        '$attackerUnitId>$defenderUnitId',
      ShowCityProductionBubbleEffect(:final cityId) => cityId,
      RendererEffect() => '${effect.runtimeType}',
    };
  }
}

final class _AnimationPlanBuilder {
  _AnimationPlanBuilder({
    required this.eventId,
    required this.eventType,
    required this.policy,
    required this.eventSequence,
    required this.startOffset,
  });

  final String eventId;
  final String eventType;
  final String policy;
  final int eventSequence;
  final Duration startOffset;
  final List<ProjectedGameEffect> animations = [];
  int nextEventOrdinal = 0;
}

List<ProjectedGameEffect> _animationsInTimelineOrder(
  Iterable<AnimationPlan> plans,
) {
  final animations =
      plans.expand((plan) => plan.animations).toList(growable: false)
        ..sort((left, right) => left.ordinal.compareTo(right.ordinal));
  return animations;
}
