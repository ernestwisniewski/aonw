import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_animation_policy.dart';
import 'package:aonw/game/presentation/engine/domain_event_animation_scheduler.dart';
import 'package:aonw/game/presentation/engine/game_event_renderer_effect_mapper.dart';
import 'package:aonw/game/presentation/engine/movement_event_execution_matcher.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';

/// The single presentation boundary for ordered authoritative domain events.
///
/// Callers may prepend effects produced by client interaction, but domain
/// movement, combat, and construction effects are always projected here.
abstract final class DomainEventPresentationProjector {
  static ProjectedGameEffectBatch projectObservedBatch({
    required PresentationBatchIdentity identity,
    PresentationSequenceDirective sequenceDirective =
        PresentationSequenceDirective.advance,
    required Iterable<RendererEffect> interactionEffects,
    required Iterable<GameEvent> events,
    required Iterable<MovementCommandExecution> visibleMovementExecutions,
    required GameClientState state,
    required GameClientState previousState,
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
  }) {
    final projections = _projectObservedEventEffects(
      events: events,
      visibleMovementExecutions: visibleMovementExecutions,
      state: state,
      previousState: previousState,
      l10n: l10n,
      viewerPlayerId: viewerPlayerId,
      turn: turn,
    );
    return DomainEventAnimationScheduler.schedule(
      identity: identity,
      sequenceDirective: sequenceDirective,
      interactionEffects: interactionEffects,
      eventProjections: projections,
    );
  }

  static List<RendererEffect> project({
    required Iterable<RendererEffect> interactionEffects,
    required Iterable<GameEvent> events,
    required GameClientState state,
    required GameClientState previousState,
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
  }) {
    return _project(
      interactionEffects: interactionEffects,
      movementEffects: const [],
      events: events,
      state: state,
      previousState: previousState,
      l10n: l10n,
      viewerPlayerId: viewerPlayerId,
      turn: turn,
    );
  }

  /// Projects recipient-filtered authoritative movement evidence.
  ///
  /// Visible events anchor executions on the global event timeline. When an
  /// execution has no public event, the complete server-reviewed movement
  /// stream remains authoritative and is presented before the event stream.
  static List<RendererEffect> projectObserved({
    required Iterable<RendererEffect> interactionEffects,
    required Iterable<GameEvent> events,
    required Iterable<MovementCommandExecution> visibleMovementExecutions,
    required GameClientState state,
    required GameClientState previousState,
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
  }) {
    final effects = <RendererEffect>[
      ...interactionEffects,
      ..._projectObservedEventEffects(
        events: events,
        visibleMovementExecutions: visibleMovementExecutions,
        state: state,
        previousState: previousState,
        l10n: l10n,
        viewerPlayerId: viewerPlayerId,
        turn: turn,
      ).expand((projection) => projection.effects),
    ];
    return effects.isEmpty
        ? const []
        : List<RendererEffect>.unmodifiable(effects);
  }

  static List<DomainEventEffectProjection> _projectObservedEventEffects({
    required Iterable<GameEvent> events,
    required Iterable<MovementCommandExecution> visibleMovementExecutions,
    required GameClientState state,
    required GameClientState previousState,
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
  }) {
    final orderedEvents = events.toList(growable: false);
    final movementPlan = MovementEventExecutionMatcher.match(
      events: orderedEvents,
      executions: visibleMovementExecutions,
      beforeUnits: previousState.units,
      afterUnits: state.units,
    );
    final combatRetreatUnitIds = {
      for (final event in orderedEvents.whereType<CombatResolvedEvent>())
        if (event.outcome.defenderRetreated) event.defenderUnitId,
    };
    return _projectObservedInEventOrder(
      events: orderedEvents,
      movementPlan: movementPlan,
      combatRetreatUnitIds: combatRetreatUnitIds,
      state: state,
      previousState: previousState,
      l10n: l10n,
      viewerPlayerId: viewerPlayerId,
      turn: turn,
    );
  }

  static List<DomainEventEffectProjection> _projectObservedInEventOrder({
    required List<GameEvent> events,
    required MovementEventExecutionPlan movementPlan,
    required Set<String> combatRetreatUnitIds,
    required GameClientState state,
    required GameClientState previousState,
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
  }) {
    final combatFacts = {
      for (final fact in _combatFacts(
        events: events,
        previousState: previousState,
        state: state,
      ))
        fact.eventIndex: fact,
    };
    final projections = <DomainEventEffectProjection>[];
    if (movementPlan.hasUnanchoredExecutions) {
      projections.add((
        eventSequence: -1,
        eventType: 'AuthoritativeMovementEvidence',
        policy: 'recipient-visible authoritative movement evidence',
        effects: _movementEffectsFromExecutions(
          movementPlan.validExecutions(excludedUnitIds: combatRetreatUnitIds),
        ),
      ));
    }
    var eventIndex = 0;
    while (eventIndex < events.length) {
      final event = events[eventIndex];
      final policy = DomainEventAnimationPolicy.forEvent(event);
      if (event is UnitMovedEvent) {
        eventIndex = _appendObservedMovementBlock(
          projections: projections,
          events: events,
          start: eventIndex,
          movementPlan: movementPlan,
          excludedUnitIds: combatRetreatUnitIds,
        );
        continue;
      }
      projections.add((
        eventSequence: eventIndex,
        eventType: '${event.runtimeType}',
        policy: policy.reviewReason,
        effects: rendererEffectsForEvent(
          event: event,
          state: state,
          previousState: previousState,
          l10n: l10n,
          viewerPlayerId: viewerPlayerId,
          turn: turn,
          combatAnimation: combatFacts[eventIndex],
        ),
      ));
      eventIndex += 1;
    }
    return projections.isEmpty
        ? const []
        : List<DomainEventEffectProjection>.unmodifiable(projections);
  }

  static List<RendererEffect> _project({
    required Iterable<RendererEffect> interactionEffects,
    required Iterable<AnimateUnitMoveEffect> movementEffects,
    required Iterable<GameEvent> events,
    required GameClientState state,
    required GameClientState previousState,
    Set<String> skipUnitMoveIds = const {},
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
  }) {
    final orderedEvents = events.toList(growable: false);
    final effects = [
      ...interactionEffects,
      ...movementEffects,
      ...GameEventRendererEffectMapper.effectsFor(
        events: orderedEvents,
        state: state,
        previousState: previousState,
        skipUnitMoveIds: skipUnitMoveIds,
        l10n: l10n,
        viewerPlayerId: viewerPlayerId,
        turn: turn,
        combatAnimations: _combatFacts(
          events: orderedEvents,
          previousState: previousState,
          state: state,
        ),
      ),
    ];
    return effects.isEmpty
        ? const []
        : List<RendererEffect>.unmodifiable(effects);
  }

  static List<CombatAnimationFact> _combatFacts({
    required List<GameEvent> events,
    required GameClientState previousState,
    required GameClientState state,
  }) {
    final unitPositions = {
      for (final unit in previousState.units) unit.id: (unit.col, unit.row),
    };
    final facts = <CombatAnimationFact>[];
    for (var index = 0; index < events.length; index++) {
      switch (events[index]) {
        case UnitMovedEvent(:final unitId, :final toCol, :final toRow):
          unitPositions[unitId] = (toCol, toRow);
        case CombatResolvedEvent(:final attackerUnitId, :final defenderUnitId):
          final attacker =
              unitPositions[attackerUnitId] ??
              _unitPosition(state, attackerUnitId);
          final defender =
              unitPositions[defenderUnitId] ??
              _unitPosition(state, defenderUnitId) ??
              _cityPosition(previousState, defenderUnitId) ??
              _cityPosition(state, defenderUnitId);
          if (attacker == null || defender == null) continue;
          facts.add(
            CombatAnimationFact(
              eventIndex: index,
              attackerUnitId: attackerUnitId,
              defenderId: defenderUnitId,
              attackerFromCol: attacker.$1,
              attackerFromRow: attacker.$2,
              attackerToCol: defender.$1,
              attackerToRow: defender.$2,
            ),
          );
        default:
          break;
      }
    }
    return facts;
  }

  static (int, int)? _unitPosition(GameClientState state, String unitId) {
    final unit = state.unitById(unitId);
    return unit == null ? null : (unit.col, unit.row);
  }

  static (int, int)? _cityPosition(GameClientState state, String cityId) {
    final city = state.cityById(cityId);
    return city == null ? null : (city.center.col, city.center.row);
  }
}

int _appendObservedMovementBlock({
  required List<DomainEventEffectProjection> projections,
  required List<GameEvent> events,
  required int start,
  required MovementEventExecutionPlan movementPlan,
  required Set<String> excludedUnitIds,
}) {
  var end = start;
  while (end < events.length && events[end] is UnitMovedEvent) {
    end += 1;
  }
  final movementProjections = _observedMovementProjections(
    events: events,
    start: start,
    end: end,
    movementPlan: movementPlan,
    excludedUnitIds: excludedUnitIds,
  );
  projections.addAll(movementProjections);
  final plannedSequences = {
    for (final projection in movementProjections) projection.eventSequence,
  };
  for (var index = start; index < end; index += 1) {
    if (plannedSequences.contains(index)) continue;
    final movementEvent = events[index];
    projections.add((
      eventSequence: index,
      eventType: '${movementEvent.runtimeType}',
      policy: DomainEventAnimationPolicy.forEvent(movementEvent).reviewReason,
      effects: const [],
    ));
  }
  return end;
}

List<DomainEventEffectProjection> _observedMovementProjections({
  required List<GameEvent> events,
  required int start,
  required int end,
  required MovementEventExecutionPlan movementPlan,
  required Set<String> excludedUnitIds,
}) {
  final matches = movementPlan.hasUnanchoredExecutions
      ? const <({int eventIndex, MovementCommandExecution execution})>[]
      : movementPlan
            .executionsForEventRange(
              start,
              end,
              excludedUnitIds: excludedUnitIds,
            )
            .toList(growable: false);
  final fallbacks = _movementFallbacks(
    events: events,
    start: start,
    end: end,
    matches: matches,
    movementPlan: movementPlan,
    excludedUnitIds: excludedUnitIds,
  );
  final projections = <DomainEventEffectProjection>[];
  var fallbackIndex = 0;
  for (final match in matches) {
    while (fallbackIndex < fallbacks.length &&
        fallbacks[fallbackIndex].eventIndex < match.eventIndex) {
      final fallback = fallbacks[fallbackIndex++];
      projections.add(
        _movementProjection(
          events,
          fallback.eventIndex,
          _fallbackEffects(fallback.movement),
        ),
      );
    }
    projections.add(
      _movementProjection(
        events,
        match.eventIndex,
        _movementEffectsFromExecutions([match.execution]),
      ),
    );
  }
  while (fallbackIndex < fallbacks.length) {
    final fallback = fallbacks[fallbackIndex++];
    projections.add(
      _movementProjection(
        events,
        fallback.eventIndex,
        _fallbackEffects(fallback.movement),
      ),
    );
  }
  return projections;
}

DomainEventEffectProjection _movementProjection(
  List<GameEvent> events,
  int eventIndex,
  List<RendererEffect> effects,
) {
  final event = events[eventIndex];
  return (
    eventSequence: eventIndex,
    eventType: '${event.runtimeType}',
    policy: DomainEventAnimationPolicy.forEvent(event).reviewReason,
    effects: effects,
  );
}

List<({int eventIndex, UnitMovedEvent movement})> _movementFallbacks({
  required List<GameEvent> events,
  required int start,
  required int end,
  required List<({int eventIndex, MovementCommandExecution execution})> matches,
  required MovementEventExecutionPlan movementPlan,
  required Set<String> excludedUnitIds,
}) {
  final matchedIndices = {for (final match in matches) match.eventIndex};
  final executionUnits = movementPlan.validExecutionUnitIds;
  final lastDestinationByUnit = <String, (int, int)>{};
  final fallbacks = <({int eventIndex, UnitMovedEvent movement})>[];
  for (var index = start; index < end; index++) {
    final movement = events[index] as UnitMovedEvent;
    if (excludedUnitIds.contains(movement.unitId) ||
        executionUnits.contains(movement.unitId)) {
      continue;
    }
    if (matchedIndices.contains(index)) {
      lastDestinationByUnit[movement.unitId] = movement.destination;
      continue;
    }
    final previous = lastDestinationByUnit[movement.unitId];
    if (previous != null && previous != movement.origin) continue;
    fallbacks.add((eventIndex: index, movement: movement));
    lastDestinationByUnit[movement.unitId] = movement.destination;
  }
  return fallbacks;
}

List<AnimateUnitMoveEffect> _movementEffectsFromExecutions(
  Iterable<MovementCommandExecution> executions,
) => QueuedMovementEffectBuilder.fromExecutions(executions);

List<RendererEffect> _fallbackEffects(UnitMovedEvent movement) =>
    unitMovementRendererEffects(movement, const {});

extension on UnitMovedEvent {
  (int, int) get origin => (fromCol, fromRow);
  (int, int) get destination => (toCol, toRow);
}
