import 'dart:async';

import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/api/session/network_session_client.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/game/presentation/screens/lobby_auto_start_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby_live_match_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby_match_action_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby_match_navigation_coordinator.dart';
import 'package:aonw/game/presentation/screens/lobby_match_status_rules.dart';
import 'package:aonw/game/presentation/screens/lobby_network_session_coordinator.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter/foundation.dart';

enum LobbyMultiplayerMode { home, quickplay, privateHost, privateJoin }

typedef LobbyConnectionClock = DateTime Function();
typedef LobbyConnectionContinuation = bool Function();
typedef LobbyConnectionSessionReader = NetworkSession? Function();
typedef LobbyConnectionSessionSetter = void Function(NetworkSession? session);
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
typedef LobbyConnectionRouter = void Function(String location);

final class LobbyConnectionController extends ChangeNotifier {
  final String mapName;
  final MapSource mapSource;
  final NetworkSessionClient sessionClient;
  final NetworkSessionStore sessionStore;
  final MultiplayerStreamConnector streamConnector;
  final String serverpodHost;
  final LobbyConnectionClock now;
  final LobbyConnectionContinuation canContinue;
  final LobbyConnectionSessionReader currentSession;
  final LobbyConnectionSessionSetter setSession;
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
  final LobbyConnectionRouter navigateTo;

  late final LobbyAutoStartCoordinator _autoStartCoordinator;
  late final LobbyLiveMatchCoordinator _liveMatchCoordinator;
  late final LobbyMatchNavigationCoordinator _matchNavigationCoordinator;

  LobbyMultiplayerMode _mode = LobbyMultiplayerMode.home;
  bool _busy = false;
  String? _error;
  WireMatch? _activeMatch;
  bool _disposed = false;

  LobbyConnectionController({
    required this.mapName,
    required this.mapSource,
    required this.sessionClient,
    required this.sessionStore,
    required this.streamConnector,
    required this.serverpodHost,
    required this.now,
    required this.canContinue,
    required this.currentSession,
    required this.setSession,
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
    required this.navigateTo,
  }) {
    _autoStartCoordinator = LobbyAutoStartCoordinator(
      now: now,
      isQuickplayMode: () => _mode == LobbyMultiplayerMode.quickplay,
      activeMatch: () => _activeMatch,
      canContinue: _canContinue,
      refreshActiveMatch: () => unawaited(refreshActiveMatch()),
      notifyCountdownChanged: _notifyStateChanged,
    );
    _liveMatchCoordinator = LobbyLiveMatchCoordinator(
      activeMatch: () => _activeMatch,
      canContinue: _canContinue,
      subscribe: _subscribeLobbyMatch,
      applyMatchUpdate: _applyLobbyMatchUpdateNow,
      showError: _showNetworkError,
      reportStreamError: _shouldReportLobbyStreamError,
      defer: (action) => unawaited(Future<void>(action)),
    );
    _matchNavigationCoordinator = LobbyMatchNavigationCoordinator(
      activeMatch: () => _activeMatch,
      canContinue: _canContinue,
      sessionForMatch: ({required session, required match}) {
        return _networkSessionCoordinator().sessionForMatch(
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
            _mode == LobbyMultiplayerMode.privateJoin);
  }

  int humanPlayerCount({int whenMissing = 1}) {
    return LobbyMatchStatusRules.humanPlayerCount(
      _activeMatch,
      whenMissing: whenMissing,
    );
  }

  Future<void> startQuickplayQueue() async {
    if (_busy) return;
    stopLobbyUpdates();
    _setMode(LobbyMultiplayerMode.quickplay);
    await _joinQuickplayQueue();
  }

  Future<void> retryQuickplayQueue() async {
    stopLobbyUpdates();
    await startQuickplayQueue();
  }

  Future<void> cancelQuickplayQueue() async {
    await _runNetworkAction(() async {
      await _matchActionCoordinator().cancelQuickplay(
        activeMatch: _activeMatch,
      );
    });
    if (!_canContinue()) return;
    _setMode(LobbyMultiplayerMode.home);
  }

  Future<void> signOut() async {
    stopLobbyUpdates();
    await sessionStore.clear();
    setSession(null);
    if (!_canContinue()) return;
    _setState(error: null, activeMatch: null, mode: LobbyMultiplayerMode.home);
  }

  Future<void> createPrivateMatch() async {
    stopLobbyUpdates();
    await _runNetworkAction(() async {
      await _matchActionCoordinator().createPrivate(_matchActionConfig());
      if (!_canContinue()) return;
      _setMode(LobbyMultiplayerMode.privateHost);
    });
  }

  void openJoinPrivateMatch() {
    stopLobbyUpdates();
    _setState(
      error: null,
      activeMatch: null,
      mode: LobbyMultiplayerMode.privateJoin,
    );
  }

  Future<void> joinPrivateMatch({required String inviteCode}) async {
    await _runNetworkAction(() async {
      await _matchActionCoordinator().joinPrivate(
        inviteCode: inviteCode,
        inviteCodeRequiredMessage: inviteCodeRequiredMessage(),
        config: _matchActionConfig(),
      );
      if (!_canContinue()) return;
      _setMode(LobbyMultiplayerMode.privateJoin);
    });
  }

  Future<void> startPrivateMatch() async {
    await _runNetworkAction(() async {
      await _matchActionCoordinator().startPrivate(activeMatch: _activeMatch);
    });
  }

  Future<void> refreshActiveMatch() async {
    if (_busy) return;
    final matchId = _activeMatch?.id;
    if (matchId == null) return;
    try {
      await _matchActionCoordinator().refreshActiveMatch(matchId: matchId);
      if (!_canContinue()) return;
      _setError(null);
    } catch (error) {
      if (!_canContinue()) return;
      _showNetworkError(error);
    }
  }

  void returnHome() {
    stopLobbyUpdates();
    _setState(error: null, activeMatch: null, mode: LobbyMultiplayerMode.home);
  }

  void stopLobbyUpdates() {
    _autoStartCoordinator.cancel();
    unawaited(_liveMatchCoordinator.close());
  }

  Future<void> _joinQuickplayQueue() async {
    await _runNetworkAction(() async {
      await _matchActionCoordinator().joinQuickplay(_matchActionConfig());
    });
  }

  Future<void> _runNetworkAction(Future<void> Function() action) async {
    if (_busy) return;
    _setState(busy: true, error: null);
    try {
      await action();
    } catch (error) {
      if (error is _LobbyNetworkAuthCancelledException) return;
      if (!_canContinue()) return;
      _showNetworkError(error);
    } finally {
      if (_canContinue()) _setBusy(false);
    }
  }

  void _showNetworkError(Object error) {
    final message = errorTextFor(error);
    _setError(message);
    presentError(message);
  }

  bool _shouldReportLobbyStreamError(Object error) {
    if (error is sp.MultiplayerException) return true;
    final match = _activeMatch;
    return match == null || LobbyMatchStatusRules.canEnter(match);
  }

  Future<NetworkSession> _ensureNetworkSession() async {
    final storedDisplayName = await sessionStore.loadDisplayName();
    try {
      return await _networkSessionCoordinator().ensureSession(
        displayName: storedDisplayName,
      );
    } on NetworkSignInRequiredException {
      final auth = await authenticate(initialDisplayName: displayName());
      if (auth == null) throw const _LobbyNetworkAuthCancelledException();
      final session = auth.toSession(changedAt: now());
      setSession(session);
      setPrimaryDisplayName(auth.displayName);
      await sessionStore.saveDisplayName(auth.displayName);
      final stored = auth.toStoredSession(displayName: auth.displayName);
      if (stored != null) await sessionStore.save(stored);
      return session;
    }
  }

  LobbyMatchActionCoordinator _matchActionCoordinator() {
    return LobbyMatchActionCoordinator(
      ensureSession: _ensureNetworkSession,
      validateMap: validateMap,
      quickplay: sessionClient.quickplay,
      createPrivateMatch: sessionClient.createPrivateMatch,
      joinPrivateMatch: sessionClient.joinPrivateMatch,
      startMatch: sessionClient.startMatch,
      loadMatch: sessionClient.loadMatch,
      leaveMatch: sessionClient.leaveMatch,
      rememberMatch: _rememberActiveMatch,
      watchMatch: _liveMatchCoordinator.watch,
      clearMatch: (session) {
        _clearNetworkActiveMatch(session);
        _setActiveMatch(null);
      },
      enterMatch: _enterMultiplayerMatch,
      scheduleAutoStartRefresh: _scheduleAutoStartRefresh,
      stopLobbyUpdates: stopLobbyUpdates,
      canContinue: _canContinue,
    );
  }

  LobbyMatchActionConfig _matchActionConfig() {
    return LobbyMatchActionConfig(
      mapName: mapName,
      displayName: displayName(),
      country: country(),
      mapNotReadyMessage: mapNotReadyMessage(),
      matchRules: MatchRules.standard,
    );
  }

  void _rememberActiveMatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    _setActiveMatch(match);
    publishMatch(match);
    _networkSessionCoordinator().applyActiveMatch(
      session: session,
      match: match,
    );
  }

  void _clearNetworkActiveMatch(NetworkSession session) {
    _networkSessionCoordinator().clearActiveMatch(session);
  }

  void _enterMultiplayerMatch({
    required NetworkSession session,
    required WireMatch match,
  }) {
    _matchNavigationCoordinator.enter(session: session, match: match);
  }

  LobbyNetworkSessionCoordinator _networkSessionCoordinator() {
    return LobbyNetworkSessionCoordinator(
      currentSession: currentSession,
      setSession: _setNetworkSessionDeferred,
      loadStoredSession: sessionStore.load,
      saveStoredSession: sessionStore.save,
      clearStoredSession: sessionStore.clear,
      saveMatchId: sessionStore.saveMatchId,
      refreshToken: sessionClient.refresh,
      now: now,
    );
  }

  void _setNetworkSessionDeferred(NetworkSession? session) {
    unawaited(
      Future<void>(() {
        if (!_canContinue()) return;
        setSession(session);
      }),
    );
  }

  Future<LobbyLiveMatchStreamHandle> _subscribeLobbyMatch({
    required NetworkSession session,
    required WireMatch match,
    required void Function(WireMatch match) onMatch,
    required void Function(Object error, StackTrace stackTrace) onError,
  }) async {
    final handle =
        await LiveEventSubscription(
          serverpodHost: serverpodHost,
          connector: streamConnector,
        ).subscribe(
          matchId: match.id,
          token: session.token,
          fromOffset: 0,
          onEvent: (_) {},
          onSnapshotResync: (_) {},
          onMatch: onMatch,
          onError: onError,
        );
    return LiveEventLobbyMatchStreamHandle(handle);
  }

  void _applyLobbyMatchUpdateNow({
    required NetworkSession session,
    required WireMatch match,
  }) {
    if (!_canContinue() || _activeMatch?.id != match.id) return;
    if (!session.isConnected) return;
    _rememberActiveMatch(session: session, match: match);
    if (!_canContinue()) return;
    _setError(null);
    if (LobbyMatchStatusRules.canEnter(match)) {
      stopLobbyUpdates();
      _enterMultiplayerMatch(session: session, match: match);
    } else {
      _scheduleAutoStartRefresh(match);
    }
  }

  void _scheduleAutoStartRefresh(WireMatch match) {
    _autoStartCoordinator.schedule(match);
  }

  void _setState({
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
    if (changed) _notifyStateChanged();
  }

  void _setMode(LobbyMultiplayerMode mode) {
    _setState(mode: mode);
  }

  void _setBusy(bool busy) {
    _setState(busy: busy);
  }

  void _setError(String? error) {
    _setState(error: error);
  }

  void _setActiveMatch(WireMatch? match) {
    _setState(activeMatch: match);
  }

  void _notifyStateChanged() {
    if (!_canContinue()) return;
    notifyListeners();
  }

  bool _canContinue() => !_disposed && canContinue();

  @override
  void dispose() {
    _disposed = true;
    _autoStartCoordinator.cancel();
    unawaited(_liveMatchCoordinator.close());
    super.dispose();
  }
}

final class _LobbyNetworkAuthCancelledException implements Exception {
  const _LobbyNetworkAuthCancelledException();
}

const Object _unchanged = Object();
