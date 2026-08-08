part of 'lobby_connection_controller.dart';

final Expando<LobbyPublicMatchRefreshCoordinator>
_lobbyPublicRefreshCoordinators = Expando();

extension LobbyConnectionPublicActions on LobbyConnectionController {
  List<WireMatch> get publicMatches => _publicMatches;

  bool get publicMatchesLoaded => _publicMatchesLoaded;

  Future<void> openPublicLobby() async {
    if (_busy) return;
    stopLobbyUpdates();
    _setState(
      error: null,
      activeMatch: null,
      mode: LobbyMultiplayerMode.publicBrowse,
    );
    _setPublicMatches(const [], loaded: false);
    await refreshPublicMatches();
    if (_canContinue() && _mode == LobbyMultiplayerMode.publicBrowse) {
      _publicRefreshCoordinator.start();
    }
  }

  Future<void> refreshPublicMatches() async {
    if (_busy || _mode != LobbyMultiplayerMode.publicBrowse) return;
    await _runNetworkAction(() async {
      final generation = ++_publicRefreshGeneration;
      try {
        final matches = await _matchActionCoordinator().listPublicMatches();
        if (!_isCurrentPublicRefresh(generation)) {
          return;
        }
        _setPublicMatches(matches, loaded: true);
      } catch (_) {
        if (_isCurrentPublicRefresh(generation)) {
          _setPublicMatches(const [], loaded: true);
        }
        rethrow;
      }
    });
  }

  Future<void> createPublicMatch({required String name}) async {
    if (_busy) return;
    _publicRefreshCoordinator.stop();
    _publicRefreshGeneration += 1;
    var enteredLobby = false;
    await _runNetworkAction(() async {
      await _matchActionCoordinator().createPublic(
        name: name,
        config: _matchActionConfig(),
      );
      if (!_canContinue() || _activeMatch == null) return;
      _setMode(LobbyMultiplayerMode.publicMatch);
      _setPublicMatches(const [], loaded: false);
      enteredLobby = true;
    });
    if (_canContinue() &&
        !enteredLobby &&
        _mode == LobbyMultiplayerMode.publicBrowse) {
      _publicRefreshCoordinator.start();
    }
  }

  Future<void> leaveLobby() async {
    var leftLobby = false;
    await _runNetworkAction(() async {
      await _matchActionCoordinator().leaveActiveLobby(
        activeMatch: _activeMatch,
      );
      leftLobby = true;
    });
    if (!leftLobby || !_canContinue()) return;
    _setState(error: null, activeMatch: null, mode: LobbyMultiplayerMode.home);
  }

  Future<void> back() async {
    if (_activeMatch == null) returnHome();
    if (_activeMatch != null) await leaveLobby();
  }

  Future<void> joinPublicMatch({required String matchId}) async {
    if (_busy) return;
    _publicRefreshCoordinator.stop();
    _publicRefreshGeneration += 1;
    var enteredLobby = false;
    await _runNetworkAction(() async {
      await _matchActionCoordinator().joinPublic(
        matchId: matchId,
        config: _matchActionConfig(),
      );
      if (!_canContinue() || _activeMatch == null) return;
      _setMode(LobbyMultiplayerMode.publicMatch);
      _setPublicMatches(const [], loaded: false);
      enteredLobby = true;
    });
    if (_canContinue() &&
        !enteredLobby &&
        _mode == LobbyMultiplayerMode.publicBrowse) {
      _publicRefreshCoordinator.start();
    }
  }

  void _setPublicMatches(List<WireMatch> matches, {required bool loaded}) {
    if (identical(matches, _publicMatches) && loaded == _publicMatchesLoaded) {
      return;
    }
    _publicMatches = List.unmodifiable(matches);
    _publicMatchesLoaded = loaded;
    _notifyStateChanged();
  }

  LobbyPublicMatchRefreshCoordinator get _publicRefreshCoordinator {
    return _lobbyPublicRefreshCoordinators[this] ??=
        LobbyPublicMatchRefreshCoordinator(
          canRefresh: () =>
              _canContinue() &&
              !_busy &&
              _mode == LobbyMultiplayerMode.publicBrowse,
          refresh: _refreshPublicMatchesInBackground,
        );
  }

  Future<void> _refreshPublicMatchesInBackground() async {
    final generation = ++_publicRefreshGeneration;
    try {
      final matches = await _matchActionCoordinator().listPublicMatches();
      if (!_isCurrentPublicRefresh(generation)) return;
      _setPublicMatches(matches, loaded: true);
    } catch (_) {
      if (_isCurrentPublicRefresh(generation)) {
        _setPublicMatches(const [], loaded: true);
      }
    }
  }

  Future<void> _restorePublicBrowseAfterUnavailable() async {
    await _refreshPublicMatchesInBackground();
    if (_canContinue() && _mode == LobbyMultiplayerMode.publicBrowse) {
      _publicRefreshCoordinator.start();
    }
  }

  bool _isCurrentPublicRefresh(int generation) {
    return _canContinue() &&
        _mode == LobbyMultiplayerMode.publicBrowse &&
        generation == _publicRefreshGeneration;
  }
}

void _stopLobbyUpdateCoordinators(LobbyConnectionController controller) {
  controller._autoStartCoordinator.cancel();
  _lobbyPublicRefreshCoordinators[controller]?.stop();
  controller._publicRefreshGeneration += 1;
}
