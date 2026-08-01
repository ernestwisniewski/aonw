import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_effect_logical_timeline.dart';
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
    required Iterable<RendererEffect> interactionEffects,
    required Iterable<GameEvent> events,
    required Iterable<MovementCommandExecution> visibleMovementExecutions,
    required GameClientState state,
    required GameClientState previousState,
    AppLocalizations? l10n,
    String? viewerPlayerId,
    int? turn,
  }) {
    final domainEffects = projectObserved(
      interactionEffects: const [],
      events: events,
      visibleMovementExecutions: visibleMovementExecutions,
      state: state,
      previousState: previousState,
      l10n: l10n,
      viewerPlayerId: viewerPlayerId,
      turn: turn,
    );
    return ProjectedGameEffectBatch(
      projectedInteractionEffects: _scheduleInteraction(
        identity,
        interactionEffects,
      ),
      domainEffects: _schedule(identity, domainEffects),
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
      interactionEffects: interactionEffects,
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

  static List<RendererEffect> _projectObservedInEventOrder({
    required Iterable<RendererEffect> interactionEffects,
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
    final effects = <RendererEffect>[...interactionEffects];
    if (movementPlan.hasUnanchoredExecutions) {
      effects.addAll(
        _movementEffectsFromExecutions(
          movementPlan.validExecutions(excludedUnitIds: combatRetreatUnitIds),
        ),
      );
    }
    var eventIndex = 0;
    while (eventIndex < events.length) {
      final event = events[eventIndex];
      if (event is UnitMovedEvent) {
        final movementBlockStart = eventIndex;
        while (eventIndex < events.length &&
            events[eventIndex] is UnitMovedEvent) {
          eventIndex += 1;
        }
        effects.addAll(
          _observedMovementEffects(
            events: events,
            start: movementBlockStart,
            end: eventIndex,
            movementPlan: movementPlan,
            excludedUnitIds: combatRetreatUnitIds,
          ),
        );
        continue;
      }
      effects.addAll(
        rendererEffectsForEvent(
          event: event,
          state: state,
          previousState: previousState,
          l10n: l10n,
          viewerPlayerId: viewerPlayerId,
          turn: turn,
          combatAnimation: combatFacts[eventIndex],
        ),
      );
      eventIndex += 1;
    }
    return effects.isEmpty
        ? const []
        : List<RendererEffect>.unmodifiable(effects);
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

  static List<ProjectedGameEffect> _schedule(
    PresentationBatchIdentity identity,
    Iterable<RendererEffect> effects,
  ) {
    var startOffset = Duration.zero;
    var ordinal = 0;
    final projected = <ProjectedGameEffect>[];
    for (final effect in effects) {
      projected.add(
        ProjectedGameEffect(
          effect: effect,
          sourceId: identity.sourceId,
          animationId:
              '${identity.sourceId}:${identity.eventOffset}:'
              '${effect.runtimeType}:${_effectEntity(effect)}:$ordinal',
          eventOffset: identity.eventOffset,
          ordinal: ordinal,
          startOffset: startOffset,
        ),
      );
      startOffset += GameEffectLogicalTimeline.durationFor(effect);
      ordinal += 1;
    }
    return projected;
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
          animationId:
              '${identity.sourceId}:interaction:$interactionId:'
              '${effect.runtimeType}:${_effectEntity(effect)}:${ordinal++}',
          eventOffset: identity.eventOffset,
          ordinal: ordinal - 1,
          startOffset: Duration.zero,
        ),
    ];
  }

  static String _effectEntity(RendererEffect effect) {
    return switch (effect) {
      AnimateUnitMoveEffect(:final unitId) => unitId,
      PlayCombatAnimationEffect(:final attackerUnitId, :final defenderUnitId) =>
        '$attackerUnitId>$defenderUnitId',
      ShowCityProductionBubbleEffect(:final col, :final row) => '$col,$row',
      RendererEffect() => '${effect.runtimeType}',
    };
  }
}

List<RendererEffect> _observedMovementEffects({
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
  final effects = <RendererEffect>[];
  var fallbackIndex = 0;
  for (final match in matches) {
    while (fallbackIndex < fallbacks.length &&
        fallbacks[fallbackIndex].eventIndex < match.eventIndex) {
      effects.addAll(_fallbackEffects(fallbacks[fallbackIndex++].movement));
    }
    effects.addAll(_movementEffectsFromExecutions([match.execution]));
  }
  while (fallbackIndex < fallbacks.length) {
    effects.addAll(_fallbackEffects(fallbacks[fallbackIndex++].movement));
  }
  return effects;
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
