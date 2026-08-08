import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';

abstract final class ReplayRendererEffectPlanner {
  static List<RendererEffect> effectsForStep({
    required Iterable<RendererEffect> interactionEffects,
    required Iterable<GameEvent> events,
    Iterable<MovementCommandExecution> movementExecutions = const [],
    required GameClientState state,
    required GameClientState previousState,
    AppLocalizations? l10n,
  }) {
    return batchForStep(
      identity: const PresentationBatchIdentity(
        sourceId: 'replay-preview',
        eventOffset: 0,
      ),
      interactionEffects: interactionEffects,
      events: events,
      movementExecutions: movementExecutions,
      state: state,
      previousState: previousState,
      l10n: l10n,
    ).effects;
  }

  static ProjectedGameEffectBatch batchForStep({
    required PresentationBatchIdentity identity,
    required Iterable<RendererEffect> interactionEffects,
    required Iterable<GameEvent> events,
    Iterable<MovementCommandExecution> movementExecutions = const [],
    required GameClientState state,
    required GameClientState previousState,
    AppLocalizations? l10n,
  }) {
    final replayInteractionEffects = [
      ...interactionEffects.where(
        (effect) => effect is JumpCameraEffect || effect is SmoothCameraEffect,
      ),
    ];
    return DomainEventPresentationProjector.projectObservedBatch(
      identity: identity,
      interactionEffects: replayInteractionEffects,
      events: events,
      visibleMovementExecutions: movementExecutions,
      state: state,
      previousState: previousState,
      l10n: l10n,
    );
  }

  static bool hasPerspectiveVisibleEffect({
    required Iterable<RendererEffect> effects,
    required GameClientState state,
    required GameClientState previousState,
    required String? perspectivePlayerId,
  }) {
    if (hasPerspectiveVisibleMovement(
      effects: effects,
      state: state,
      previousState: previousState,
      perspectivePlayerId: perspectivePlayerId,
    )) {
      return true;
    }
    for (final effect in effects) {
      switch (effect) {
        case ShowFloatingTextEffect(:final col, :final row) ||
            SpawnParticleBurstEffect(:final col, :final row) ||
            ShowCityProductionBubbleEffect(:final col, :final row) ||
            ShowCombatHexAlertEffect(:final col, :final row) ||
            JumpCameraEffect(:final col, :final row) ||
            SmoothCameraEffect(:final col, :final row):
          if (_canSeeEffectAt(
            col,
            row,
            state: state,
            previousState: previousState,
            perspectivePlayerId: perspectivePlayerId,
          )) {
            return true;
          }
        case AnimateUnitMoveEffect() ||
            PlayCombatAnimationEffect() ||
            ShakeCameraEffect() ||
            ShowActionTargetFocusEffect():
          break;
      }
    }
    return false;
  }

  static bool hasPerspectiveVisibleMovement({
    required Iterable<RendererEffect> effects,
    required GameClientState state,
    required GameClientState previousState,
    required String? perspectivePlayerId,
  }) {
    final perspective = perspectivePlayerId;
    for (final effect in effects.whereType<AnimateUnitMoveEffect>()) {
      if (perspective == null || perspective.isEmpty) return true;

      final unit =
          state.unitById(effect.unitId) ??
          previousState.unitById(effect.unitId);
      if (unit?.ownerPlayerId == perspective) return true;

      if (_canSeeMovement(effect, previousState) ||
          _canSeeMovement(effect, state)) {
        return true;
      }
    }
    return false;
  }

  static bool _canSeeMovement(
    AnimateUnitMoveEffect effect,
    GameClientState state,
  ) {
    if (_canSeeDynamicAt(state, effect.fromCol, effect.fromRow)) return true;
    for (final step in effect.steps) {
      if (_canSeeDynamicAt(state, step.col, step.row)) return true;
    }
    return false;
  }

  static bool _canSeeEffectAt(
    int col,
    int row, {
    required GameClientState state,
    required GameClientState previousState,
    required String? perspectivePlayerId,
  }) {
    if (perspectivePlayerId == null || perspectivePlayerId.isEmpty) {
      return true;
    }
    return _canSeeDynamicAt(previousState, col, row) ||
        _canSeeDynamicAt(state, col, row);
  }

  static bool _canSeeDynamicAt(GameClientState state, int col, int row) {
    final visibility = state.activePlayerVisibility;
    if (!visibility.isEnabled ||
        !state.fogOfWar.playerIds.contains(visibility.playerId)) {
      return true;
    }
    return visibility.canSeeDynamicAt(col, row);
  }
}
