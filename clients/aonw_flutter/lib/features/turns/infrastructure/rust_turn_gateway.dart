import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../../map/application/movement_session_port.dart';
import '../../map/infrastructure/rust_game_session_context.dart';
import '../../map/read_model/player_map_view.dart';
import '../application/turn_session_port.dart';
import '../read_model/turn_command_view.dart';
import 'turn_view_mapper.dart';

typedef RustRequestSender =
    Future<AonwClientResponse> Function(
      AonwRustSession session,
      AonwClientRequest request,
    );
typedef TurnPatchApplier =
    Future<PlayerMapView> Function(
      RustGameSessionContext context,
      AonwCommandResult command,
    );

final class RustTurnGateway {
  const RustTurnGateway({TurnViewMapper mapper = const TurnViewMapper()})
    : _mapper = mapper;

  final TurnViewMapper _mapper;

  Future<TurnCommandResultView> execute({
    required RustGameSessionContext context,
    required int expectedRevision,
    required RustRequestSender send,
    required TurnPatchApplier applyPatch,
  }) async {
    try {
      final response = await send(
        context.session,
        AonwClientRequest.endTurn(expectedRevision: expectedRevision),
      );
      final command = response.require<AonwCommandResponse>().result;
      if (!command.accepted) {
        return _rejected(context, command, applyPatch);
      }
      final execution = _mapper.accepted(
        command,
        map: context.map,
        expectedRevision: expectedRevision,
      );
      final player = await applyPatch(context, command);
      return TurnCommandResultView.accepted(
        player: player,
        activities: execution.activities,
        evidence: execution.evidence,
      );
    } on TurnSessionException {
      rethrow;
    } on MovementSessionException catch (error) {
      throw _movementFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw TurnSessionException(
        code: 'invalid_session_protocol',
        message: 'The turn response is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }

  Future<TurnCommandResultView> _rejected(
    RustGameSessionContext context,
    AonwCommandResult command,
    TurnPatchApplier applyPatch,
  ) async {
    final rejection = _mapper.rejected(
      command,
      map: context.map,
      currentRevision: context.player.stamp.revision,
    );
    await applyPatch(context, command);
    return TurnCommandResultView.rejected(code: rejection);
  }
}

TurnSessionException _movementFailure(MovementSessionException error) =>
    TurnSessionException(
      code: error.code,
      message: 'The turn request could not be completed.',
      diagnosticCause: error.diagnosticCause,
      diagnosticStackTrace: error.diagnosticStackTrace,
      resyncedPlayer: error.resyncedPlayer,
    );
