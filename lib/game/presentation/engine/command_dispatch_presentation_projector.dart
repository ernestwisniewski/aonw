import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';

ProjectedGameEffectBatch projectCommandDispatchPresentation({
  required PresentationBatchIdentity identity,
  required Iterable<RendererEffect> interactionEffects,
  required Iterable<GameEvent> events,
  required Iterable<MovementCommandExecution> movementExecutions,
  required GameClientState state,
  required GameClientState previousState,
  required AppLocalizations? l10n,
  required int? turn,
}) {
  return DomainEventPresentationProjector.projectObservedBatch(
    identity: identity,
    interactionEffects: interactionEffects,
    events: events,
    visibleMovementExecutions: movementExecutions,
    state: state,
    previousState: previousState,
    l10n: l10n,
    turn: turn,
  );
}
