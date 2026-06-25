import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/protocol.dart';

typedef LobbyNavigationActiveMatchReader = WireMatch? Function();
typedef LobbyNavigationContinuation = bool Function();
typedef LobbyNavigationSessionBuilder =
    NetworkSession Function({
      required NetworkSession session,
      required WireMatch match,
    });
typedef LobbyNavigationSessionSetter = void Function(NetworkSession session);
typedef LobbyNavigationRouter = void Function(String location);
typedef LobbyNavigationStopper = void Function();
typedef LobbyNavigationDeferrer = void Function(void Function() action);

final class LobbyMatchNavigationCoordinator {
  final LobbyNavigationActiveMatchReader activeMatch;
  final LobbyNavigationContinuation canContinue;
  final LobbyNavigationSessionBuilder sessionForMatch;
  final LobbyNavigationSessionSetter setSession;
  final LobbyNavigationRouter navigateTo;
  final LobbyNavigationStopper stopLobbyUpdates;
  final LobbyNavigationDeferrer defer;
  final MapSource mapSource;

  String? _enteringMatchId;

  LobbyMatchNavigationCoordinator({
    required this.activeMatch,
    required this.canContinue,
    required this.sessionForMatch,
    required this.setSession,
    required this.navigateTo,
    required this.stopLobbyUpdates,
    required this.defer,
    this.mapSource = MapSource.asset,
  });

  void enter({required NetworkSession session, required WireMatch match}) {
    if (_enteringMatchId == match.id) return;
    _enteringMatchId = match.id;
    stopLobbyUpdates();
    defer(() => _enterDeferred(session: session, match: match));
  }

  void _enterDeferred({
    required NetworkSession session,
    required WireMatch match,
  }) {
    if (!canContinue() ||
        activeMatch()?.id != match.id ||
        !session.isConnected) {
      _clearEnteringGuard(match.id);
      return;
    }

    setSession(sessionForMatch(session: session, match: match));
    navigateTo(gameLocation(match: match, mapSource: mapSource));
  }

  void _clearEnteringGuard(String matchId) {
    if (_enteringMatchId == matchId) _enteringMatchId = null;
  }

  static String gameLocation({
    required WireMatch match,
    MapSource mapSource = MapSource.asset,
  }) {
    return Uri(
      path: '/game',
      queryParameters: {
        'saveId': match.id,
        'name': match.mapName,
        'source': mapSource.name,
      },
    ).toString();
  }
}
