import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw_core/protocol.dart';

abstract interface class WireCommandDispatcher {
  /// Sends one delivery attempt of [wire]. Retries of the same command must
  /// reuse [clientMessageId] so the server can deduplicate them safely.
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
  });
}
