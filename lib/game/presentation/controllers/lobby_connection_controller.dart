import 'dart:async';

import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/ports/multiplayer_failure.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/network_session_store.dart';
import 'package:aonw/game/presentation/controllers/lobby_connection_public_actions.dart';
import 'package:aonw/game/presentation/controllers/lobby_connection_session_actions.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_auto_start_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_live_match_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_action_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_navigation_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_match_status_rules.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_network_session_coordinator.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter/foundation.dart';

export 'lobby_connection_public_actions.dart';
export 'lobby_connection_session_actions.dart';

part 'lobby_connection_match_state.dart';

enum LobbyMultiplayerMode {
  home,
  quickplay,
  publicBrowse,
  publicMatch,
  privateHost,
  privateJoin,
}

typedef LobbyConnectionClock = DateTime Function();
typedef LobbyConnectionContinuation = bool Function();
typedef LobbyConnectionSessionReader = NetworkSession? Function();
typedef LobbyConnectionSessionSetter = void Function(NetworkSession? session);
typedef LobbyConnectionSessionTerminator = Future<void> Function();
typedef LobbyConnectionSessionSignOut = Future<void> Function();
typedef LobbyAuthenticatedSessionActivator =
    Future<void> Function({
      required NetworkSession session,
      required String displayName,
    });
typedef LobbyConnectionAuthenticator =
    Future<NetworkAuthResult?> Function({required String initialDisplayName});
typedef LobbyConnectionDisplayNameReader = String Function();
typedef LobbyConnectionDisplayNameWriter = void Function(String displayName);
typedef LobbyConnectionCountryReader = PlayerCountry Function();
typedef LobbyConnectionMapValidator = Future<MapValidationResult> Function();
typedef LobbyConnectionMessageReader = String Function();
typedef LobbyConnectionErrorText = String Function(Object error);
typedef LobbyConnectionErrorPresenter = void Function(String message);
typedef LobbyConnectionMatchPublisher = void Function(WireMatch match);
typedef LobbyConnectionMatchInvalidator = void Function(String matchId);
typedef LobbyConnectionUnavailablePresenter = void Function();
typedef LobbyConnectionTransportStatusReporter =
    void Function({
      required String matchId,
      required NetworkConnectionStatus status,
      String? message,
    });
typedef LobbyConnectionRouter = void Function(String location);

final class LobbyConnectionController extends ChangeNotifier {
  final String mapName;
  final MapSource mapSource;
  final MultiplayerSessionGateway sessionClient;
  final NetworkSessionStorePort sessionStore;
  final LiveMultiplayerEvents liveEvents;
  final LobbyConnectionClock now;
  final LobbyConnectionContinuation canContinue;
  final LobbyConnectionSessionReader currentSession;
  final LobbyConnectionSessionSetter setSession;
  final LobbyConnectionSessionTerminator? terminateSession;
  final LobbyConnectionSessionSignOut? signOutSession;
  final LobbyAuthenticatedSessionActivator? activateAuthenticatedSession;
  final LobbyConnectionAuthenticator authenticate;
  final LobbyConnectionDisplayNameReader displayName;
  final LobbyConnectionDisplayNameWriter setPrimaryDisplayName;
  final LobbyConnectionCountryReader country;
  final LobbyConnectionMapValidator validateMap;
  final LobbyConnectionMessageReader mapNotReadyMessage;
  final LobbyConnectionMessageReader inviteCodeRequiredMessage;
  final LobbyConnectionErrorText errorTextFor;
  final LobbyConnectionErrorPresenter presentError;
  final LobbyConnectionMatchPublisher publishMatch;
  final LobbyConnectionMatchInvalidator? invalidatePublishedMatch;
  final LobbyConnectionUnavailablePresenter? presentLobbyUnavailable;
  final LobbyConnectionTransportStatusReporter? reportTransportStatus;
  final LobbyConnectionRouter navigateTo;
  final LobbyValidSessionEnsurer? ensureValidSession;

  late final LobbyAutoStartCoordinator internalAutoStartCoordinator;
  late final LobbyLiveMatchCoordinator _liveMatchCoordinator;
  late final LobbyMatchNavigationCoordinator _matchNavigationCoordinator;

  LobbyMultiplayerMode _mode = LobbyMultiplayerMode.home;
  bool _busy = false;
  String? _error;
  WireMatch? _activeMatch;
  List<WireMatch> internalPublicMatches = const [];
  bool internalPublicMatchesLoaded = false;
  int internalPublicRefreshGeneration = 0;
  final Set<String> _unavailableMatchIds = <String>{};
  bool _disposed = false;

  LobbyConnectionController({
    required this.mapName,
    required this.mapSource,
    required this.sessionClient,
    required this.sessionStore,
    required this.liveEvents,
    required this.now,
    required this.canContinue,
    required this.currentSession,
    required this.setSession,
    this.terminateSession,
    this.signOutSession,
    this.activateAuthenticatedSession,
    required this.authenticate,
    required this.displayName,
    required this.setPrimaryDisplayName,
    required this.country,
    required this.validateMap,
    required this.mapNotReadyMessage,
    required this.inviteCodeRequiredMessage,
    required this.errorTextFor,
    required this.presentError,
    required this.publishMatch,
    this.invalidatePublishedMatch,
    this.presentLobbyUnavailable,
    this.reportTransportStatus,
    required this.navigateTo,
    this.ensureValidSession,
  }) {
    internalAutoStartCoordinator = LobbyAutoStartCoordinator(
      now: now,
      isQuickplayMode: () => _mode == LobbyMultiplayerMode.quickplay,
      activeMatch: () => _activeMatch,
      canContinue: canContinueInternal,
      refreshActiveMatch: () => unawaited(refreshActiveMatch()),
      notifyCountdownChanged: notifyStateChangedInternal,
    );
    _liveMatchCoordinator = LobbyLiveMatchCoordinator(
      activeMatch: () => _activeMatch,
      canContinue: canContinueInternal,
      subscribe: _subscribeLobbyMatch,
      applyMatchUpdate: _applyLobbyMatchUpdateNow,
      showError: _handleLobbyStreamError,
      reportStreamError: _shouldReportLobbyStreamError,
      defer: (action) => unawaited(Future<void>(action)),
    );
    _matchNavigationCoordinator = LobbyMatchNavigationCoordinator(
      activeMatch: () => _activeMatch,
      canContinue: canContinueInternal,
      sessionForMatch: ({required session, required match}) {
        return networkSessionCoordinatorInternal().sessionForMatch(
          session: session,
          match: match,
        );
      },
      setSession: setSession,
      navigateTo: navigateTo,
      stopLobbyUpdates: stopLobbyUpdates,
      defer: (action) => unawaited(Future<void>(action)),
      mapSource: mapSource,
    );
  }

  LobbyMultiplayerMode get mode => _mode;

  bool get busy => _busy;

  String? get error => _error;

  WireMatch? get activeMatch => _activeMatch;

  String? get inviteCode => _activeMatch?.inviteCode;

  bool get showProfile {
    return _activeMatch == null &&
        (_mode == LobbyMultiplayerMode.home ||
            _mode == LobbyMultiplayerMode.publicBrowse ||
            _mode == LobbyMultiplayerMode.privateJoin);
  }

  int connectedHumanPlayerCount({int whenMissing = 0}) {
    return LobbyMatchStatusRules.connectedHumanCount(
      _activeMatch,
      whenMissing: whenMissing,
    );
  }

  Future<void> startQuickplayQueue() async {
    if (_busy) return;
    stopLobbyUpdates();
    setModeInternal(LobbyMultiplayerMode.quickplay);
    await _joinQuickplayQueue();
  }

  Future<void> retryQuickplayQueue() async {
    stopLobbyUpdates();
    await startQuickplayQueue();
  }

  Future<void> cancelQuickplayQueue() async {
    var leftQueue = false;
    await runNetworkActionInternal(() async {
      await matchActionCoordinatorInternal().cancelQuickplay(
        activeMatch: _activeMatch,
      );
      leftQueue = true;
    });
    if (!leftQueue || !canContinueInternal()) return;
    setModeInternal(LobbyMultiplayerMode.home);
  }

  Future<void> createPrivateMatch() async {
    stopLobbyUpdates();
    await runNetworkActionInternal(() async {
      await matchActionCoordinatorInternal().createPrivate(
        matchActionConfigInternal(),
      );
      if (!canContinueInternal() || _activeMatch == null) return;
      setModeInternal(LobbyMultiplayerMode.privateHost);
    });
  }

  void openJoinPrivateMatch() {
    stopLobbyUpdates();
    setStateInternal(
      error: null,
      activeMatch: null,
      mode: LobbyMultiplayerMode.privateJoin,
    );
  }

  Future<void> joinPrivateMatch({required String inviteCode}) async {
    await runNetworkActionInternal(() async {
      await matchActionCoordinatorInternal().joinPrivate(
        inviteCode: inviteCode,
        inviteCodeRequiredMessage: inviteCodeRequiredMessage(),
        config: matchActionConfigInternal(),
      );
      if (!canContinueInternal() || _activeMatch == null) return;
      setModeInternal(LobbyMultiplayerMode.privateJoin);
    });
  }

  Future<void> startPrivateMatch() async {
    await runNetworkActionInternal(() async {
      await matchActionCoordinatorInternal().startHostedMatch(
        activeMatch: _activeMatch,
      );
    });
  }

  Future<void> startPublicMatch() async {
    await runNetworkActionInternal(() async {
      await matchActionCoordinatorInternal().startHostedMatch(
        activeMatch: _activeMatch,
      );
    });
  }

  Future<void> refreshActiveMatch() async {
    if (_busy) return;
    final matchId = _activeMatch?.id;
    if (matchId == null) return;
    try {
      await matchActionCoordinatorInternal().refreshActiveMatch(
        matchId: matchId,
      );
      if (!canContinueInternal()) return;
      _setError(null);
    } catch (error) {
      if (!canContinueInternal()) return;
      showNetworkErrorInternal(error);
    }
  }

  void returnHome() {
    stopLobbyUpdates();
    setStateInternal(
      error: null,
      activeMatch: null,
      mode: LobbyMultiplayerMode.home,
    );
    setPublicMatchesInternal(const [], loaded: false);
  }

  void stopLobbyUpdates() {
    unawaited(stopLobbyUpdatesAndWaitInternal());
  }

  Future<void> stopLobbyUpdatesAndWaitInternal() async {
    stopLobbyUpdateCoordinatorsInternal(this);
    await _liveMatchCoordinator.close();
  }

  Future<void> _joinQuickplayQueue() async {
    await runNetworkActionInternal(() async {
      await matchActionCoordinatorInternal().joinQuickplay(
        matchActionConfigInternal(),
      );
    });
  }

  Future<void> runNetworkActionInternal(Future<void> Function() action) async {
    if (_busy) return;
    setStateInternal(busy: true, error: null);
    try {
      await action();
    } catch (error) {
      if (error is LobbyNetworkAuthCancelledException) return;
      if (!canContinueInternal()) return;
      showNetworkErrorInternal(error);
    } finally {
      if (canContinueInternal()) _setBusy(false);
    }
  }

  void showNetworkErrorInternal(Object error) {
    final message = errorTextFor(error);
    _setError(message);
    presentError(message);
  }

  bool _shouldReportLobbyStreamError(Object error) {
    if (error is MultiplayerFailure &&
        error.kind == MultiplayerFailureKind.multiplayer) {
      return true;
    }
    final match = _activeMatch;
    return match == null || LobbyMatchStatusRules.canEnter(match);
  }

  void setStateInternal({
    LobbyMultiplayerMode? mode,
    bool? busy,
    Object? error = _unchanged,
    Object? activeMatch = _unchanged,
  }) {
    var changed = false;
    if (mode != null && mode != _mode) {
      _mode = mode;
      changed = true;
    }
    if (busy != null && busy != _busy) {
      _busy = busy;
      changed = true;
    }
    if (!identical(error, _unchanged) && error != _error) {
      _error = error as String?;
      changed = true;
    }
    if (!identical(activeMatch, _unchanged) && activeMatch != _activeMatch) {
      _activeMatch = activeMatch as WireMatch?;
      changed = true;
    }
    if (changed) notifyStateChangedInternal();
  }

  void setModeInternal(LobbyMultiplayerMode mode) =>
      setStateInternal(mode: mode);

  void _setBusy(bool busy) {
    setStateInternal(busy: busy);
  }

  void _setError(String? error) {
    setStateInternal(error: error);
  }

  void _setActiveMatch(WireMatch? match) {
    setStateInternal(activeMatch: match);
  }

  void notifyStateChangedInternal() {
    if (!canContinueInternal()) return;
    notifyListeners();
  }

  bool canContinueInternal() => !_disposed && canContinue();

  @override
  void dispose() {
    _disposed = true;
    stopLobbyUpdateCoordinatorsInternal(this);
    unawaited(_liveMatchCoordinator.close());
    super.dispose();
  }
}

final class LobbyNetworkAuthCancelledException implements Exception {
  const LobbyNetworkAuthCancelledException();
}

const Object _unchanged = Object();
