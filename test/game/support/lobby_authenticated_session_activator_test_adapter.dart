import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/presentation/controllers/lobby_connection_controller.dart';

final class LobbyControllerTestSessionActivator
    implements LobbyAuthenticatedSessionActivator {
  LobbyControllerTestSessionActivator(this.onActivate);

  final Future<void> Function({
    required NetworkSession session,
    required String displayName,
  })
  onActivate;

  @override
  Future<void> activate({
    required NetworkSession session,
    required String displayName,
  }) {
    return onActivate(session: session, displayName: displayName);
  }
}
