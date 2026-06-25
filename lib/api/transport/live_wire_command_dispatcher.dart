import 'dart:async';

import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/api/transport/network_command_transport.dart';
import 'package:aonw_core/protocol.dart';

typedef LiveEventSubscriptionHandleReader =
    FutureOr<LiveEventSubscriptionHandle?> Function();

class LiveWireCommandDispatcher implements WireCommandDispatcher {
  const LiveWireCommandDispatcher({
    required this.liveHandle,
    required this.fallback,
    this.timeout = const Duration(seconds: 10),
  });

  final LiveEventSubscriptionHandleReader liveHandle;
  final WireCommandDispatcher fallback;
  final Duration timeout;

  @override
  Future<WireCommandAck> send({
    required String saveId,
    required AuthToken token,
    required int afterOffset,
    required WireCommand wire,
  }) async {
    LiveEventSubscriptionHandle? handle;
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
      );
    }
    return handle.sendCommand(
      afterOffset: afterOffset,
      wire: wire,
      timeout: timeout,
    );
  }
}
