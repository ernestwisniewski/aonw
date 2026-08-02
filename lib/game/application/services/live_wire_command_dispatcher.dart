import 'dart:async';

import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/ports/wire_command_dispatcher.dart';
import 'package:aonw_core/protocol.dart';

typedef LiveMultiplayerEventHandleReader =
    FutureOr<LiveMultiplayerEventHandle?> Function();

class LiveWireCommandDispatcher implements WireCommandDispatcher {
  const LiveWireCommandDispatcher({
    required this.liveHandle,
    required this.fallback,
    this.timeout = const Duration(seconds: 10),
  });

  final LiveMultiplayerEventHandleReader liveHandle;
  final WireCommandDispatcher fallback;
  final Duration timeout;

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
    required String clientMessageId,
  }) async {
    LiveMultiplayerEventHandle? handle;
    try {
      handle = await liveHandle();
    } catch (_) {
      handle = null;
    }
    if (handle == null) {
      return fallback.send(
        saveId: saveId,
        token: token,
        afterOffset: afterOffset,
        wire: wire,
        clientMessageId: clientMessageId,
      );
    }
    return handle.sendCommand(
      afterOffset: afterOffset,
      wire: wire,
      clientMessageId: clientMessageId,
      timeout: timeout,
    );
  }
}
