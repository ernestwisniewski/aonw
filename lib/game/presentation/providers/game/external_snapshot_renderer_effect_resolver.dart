import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_event_renderer_effect_mapper.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';

abstract final class ExternalSnapshotRendererEffectResolver {
  static List<RendererEffect> resolve({
    required GameState previousState,
    required GameState nextState,
    required Iterable<GameEvent> events,
    required Iterable<MovementCommandExecution>? movementExecutions,
    bool inferDirectMoves = false,
    String? viewerPlayerId,
    int? turn,
    AppLocalizations? l10n,
  }) {
    final eventList = List<GameEvent>.of(events);
    final combatRetreatUnitIds = {
      for (final event in eventList.whereType<CombatResolvedEvent>())
        if (event.outcome.defenderRetreated) event.defenderUnitId,
    };
    final movementEffects =
        (movementExecutions == null
                ? QueuedMovementEffectBuilder.fromUnitDelta(
                    beforeUnits: previousState.units,
                    afterUnits: nextState.units,
                    inferDirectMoves: inferDirectMoves,
                  )
                : QueuedMovementEffectBuilder.fromExecutions(
                    movementExecutions,
                    beforeUnits: previousState.units,
                    afterUnits: nextState.units,
                  ))
            .where((effect) => !combatRetreatUnitIds.contains(effect.unitId))
            .toList(growable: false);
    final skipUnitMoveIds = {
      for (final effect in movementEffects) effect.unitId,
      if (movementExecutions != null)
        for (final event in eventList.whereType<UnitMovedEvent>()) event.unitId,
    };
    final effects = [
      ...movementEffects,
      ...GameEventRendererEffectMapper.effectsFor(
        events: eventList,
        state: nextState,
        previousState: previousState,
        skipUnitMoveIds: skipUnitMoveIds,
        l10n: l10n,
        viewerPlayerId: viewerPlayerId,
        turn: turn,
      ),
    ];
    return effects.isEmpty
        ? const []
        : List<RendererEffect>.unmodifiable(effects);
  }
}
