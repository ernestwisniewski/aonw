import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/application/services/live_snapshot_presentation_policy.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/audio/game_audio_controller.dart';
import 'package:aonw/game/presentation/audio/game_sound_cue_mapper.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw/game/presentation/engine/renderer_view_model.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/game/presentation/providers/game/game_state_runtime.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';

final class GameStateEffects {
  const GameStateEffects(this._binding);

  final GameStateBinding _binding;

  Future<void> presentExternalSnapshot({
    required GameClientState? previousState,
    required GameClientState nextState,
    required List<GameEvent> events,
    required List<MovementCommandExecution> movementExecutions,
    required PresentationBatchIdentity identity,
    required PresentationSequenceDirective sequenceDirective,
    required String? viewerPlayerId,
    required int turn,
    required RendererViewModel? renderer,
    required GameAudioController audioController,
    required GameEventNotificationsNotifier notifications,
  }) async {
    if (previousState == null) return;
    final transitionEffects =
        DomainEventPresentationProjector.projectObservedBatch(
          identity: identity,
          sequenceDirective: sequenceDirective,
          interactionEffects: const [],
          previousState: previousState,
          state: nextState,
          events: events,
          visibleMovementExecutions: movementExecutions,
          viewerPlayerId: viewerPlayerId,
          turn: eventTurnFor(events, fallbackTurn: turn),
        );
    final cues = [
      ...GameSoundCueMapper.forRendererEffects(
        effects: transitionEffects.effects,
        state: nextState,
        previousState: previousState,
      ),
      ...GameSoundCueMapper.forEvents(
        events: events,
        state: nextState,
        previousState: previousState,
      ),
    ];
    if (cues.isNotEmpty) audioController.playAll(cues);
    if (renderer != null) {
      await renderer.applyProjectedTransition(
        nextState,
        transitionEffects,
        currentTurn: turn,
      );
    }
    if (!_binding.isMounted()) return;
    notifications.addAll(
      events,
      nextState,
      previousState: previousState,
      turn: turn,
    );
  }

  int eventTurnFor(Iterable<GameEvent> events, {required int fallbackTurn}) {
    for (final event in events) {
      final completedTurn = GameEventDescriptor.forEvent(event).completedTurn;
      if (completedTurn != null) return completedTurn;
    }
    return fallbackTurn;
  }

  void warn(String message, [Object? error, StackTrace? stackTrace]) {
    if (!_binding.isMounted()) return;
    _binding.ref
        .read(gameLoggerProvider)
        .warn('GameStateNotifier', message, error, stackTrace);
  }
}

PresentationBatchIdentity liveBatchIdentity(
  String sourceId,
  int eventOffset,
  LiveServerEvent? liveEvent,
) {
  final wire = liveEvent?.wire;
  return PresentationBatchIdentity(
    sourceId: sourceId,
    eventOffset: eventOffset,
    authoritativeTick: wire?.tick,
    authoritativeStartMicrosUtc: wire?.timestamp
        .add(multiplayerPresentationStartBuffer)
        .microsecondsSinceEpoch,
  );
}

List<GameEvent> presentedLiveEvents(
  LiveSnapshotPresentationDecision presentation,
  LiveServerEvent? liveEvent,
) {
  final event = presentation.canPresentLiveTransition ? liveEvent : null;
  return event?.events ?? const [];
}
