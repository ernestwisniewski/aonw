import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';

final _savedAt = DateTime.utc(2026, 7, 29);

/// Mirrors the local transport boundary without persistence side effects.
///
/// Client-only interaction commands stay in [GameIntentResolver]. Authoritative
/// commands, including commands derived from a tile or city intent, execute
/// through [LocalCommandResolver] and therefore the canonical game engine.
GameStateTransition dispatchCanonicalTestCommand({
  required GameStateReducer reducer,
  required GameClientState state,
  required Object command,
  GameCommandContext context = const GameCommandContext(),
}) {
  if (command is GameIntent) {
    final intentResolver = GameIntentResolver(
      reducer: reducer,
      context: context,
    );
    final resolution = intentResolver.resolve(
      state.interaction,
      command,
      state,
    );
    final authoritativeCommand = resolution.domainCommand;
    if (authoritativeCommand != null) {
      return _dispatchDomainTestCommand(
        reducer: reducer,
        state: state,
        command: authoritativeCommand,
        context: context,
        fromMovePreviewConfirmation:
            command is TileTappedCommand &&
            authoritativeCommand is MoveUnitCommand,
      );
    }
    return GameStateTransition(
      state: resolution.interaction == state.interaction
          ? state
          : state.copyWith(interaction: resolution.interaction),
      uiEffects: resolution.presentationFocus,
    );
  }
  if (command is! DomainCommand) {
    throw StateError(
      '${command.runtimeType} reached the authoritative test boundary.',
    );
  }
  return _dispatchDomainTestCommand(
    reducer: reducer,
    state: state,
    command: command,
    context: context,
  );
}

GameStateTransition _dispatchDomainTestCommand({
  required GameStateReducer reducer,
  required GameClientState state,
  required DomainCommand command,
  required GameCommandContext context,
  bool fromMovePreviewConfirmation = false,
}) {
  final resolved = LocalCommandResolver(reducer: reducer).resolve(
    baseSnapshot: GameSnapshotFactory.fromClientState(
      save: _saveFor(state, context),
      state: state,
    ),
    currentState: state,
    command: command,
    savedAt: _savedAt,
    context: context,
    movementPresentationOrigin: fromMovePreviewConfirmation
        ? LocalMovementPresentationOrigin.previewConfirmation
        : LocalMovementPresentationOrigin.direct,
  );
  return GameStateTransition(
    state: resolved.state,
    uiEffects: resolved.uiEffects,
    events: resolved.events,
  );
}

GameSave _saveFor(GameClientState state, GameCommandContext context) {
  final playerIds = <String>{
    ...state.domain.knownPlayerIds,
    if (state.activePlayerId.isNotEmpty) state.activePlayerId,
    if (context.hasActor) context.actorPlayerId!,
  };
  if (playerIds.isEmpty) playerIds.add('player_1');
  final orderedPlayerIds = playerIds.toList()..sort();
  return GameSave(
    id: 'canonical_command_test',
    name: 'Canonical command test',
    mapName: 'canonical_command_test',
    turn: 1,
    playerStates: {
      for (final playerId in orderedPlayerIds) playerId: PlayerTurnState.active,
    },
    savedAt: _savedAt,
    camera: CameraState.zero,
    players: [
      for (final playerId in orderedPlayerIds)
        Player(
          id: playerId,
          name: playerId,
          colorValue: state.playerColors[playerId] ?? 0,
          country: state.playerCountries[playerId] ?? PlayerCountry.poland,
        ),
    ],
    gameMode: GameMode.hotSeat,
  );
}
