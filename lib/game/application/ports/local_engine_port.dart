import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/command.dart';

abstract interface class LocalEnginePort {
  /// Returns `null` only when this engine cannot handle the command.
  Future<CommandTransportResult?> dispatchIfSupported({
    required String saveId,
    required GameClientState currentState,
    required DomainCommand command,
    required GameCommandContext context,
    required bool fromMovePreviewConfirmation,
  });
}
