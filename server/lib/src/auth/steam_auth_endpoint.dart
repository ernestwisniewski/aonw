import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'steam_auth_service.dart';

class SteamAuthEndpoint extends Endpoint {
  final _service = SteamAuthService();

  @unauthenticatedClientCall
  Future<SteamAuthStart> start(Session session) {
    return _service.start(session);
  }

  @unauthenticatedClientCall
  Future<SteamAuthPollResult> poll(
    Session session, {
    required String requestId,
  }) {
    return _service.poll(session, requestId: requestId);
  }
}
