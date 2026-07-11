part of 'lobby_connection_controller.dart';

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
  }

  Future<void> refreshPublicMatches() async {
    if (_busy || _mode != LobbyMultiplayerMode.publicBrowse) return;
    await _runNetworkAction(() async {
      try {
        final matches = await _matchActionCoordinator().listPublicMatches();
        if (!_canContinue() || _mode != LobbyMultiplayerMode.publicBrowse) {
          return;
        }
        _setPublicMatches(matches, loaded: true);
      } finally {
        if (_canContinue() && _mode == LobbyMultiplayerMode.publicBrowse) {
          _setPublicMatches(_publicMatches, loaded: true);
        }
      }
    });
  }

  Future<void> createPublicMatch({required String name}) async {
    if (_busy) return;
    stopLobbyUpdates();
    await _runNetworkAction(() async {
      await _matchActionCoordinator().createPublic(
        name: name,
        config: _matchActionConfig(),
      );
      if (!_canContinue()) return;
      _setMode(LobbyMultiplayerMode.publicMatch);
      _setPublicMatches(const [], loaded: false);
    });
  }

  Future<void> joinPublicMatch({required String matchId}) async {
    if (_busy) return;
    stopLobbyUpdates();
    await _runNetworkAction(() async {
      await _matchActionCoordinator().joinPublic(
        matchId: matchId,
        config: _matchActionConfig(),
      );
      if (!_canContinue()) return;
      _setMode(LobbyMultiplayerMode.publicMatch);
      _setPublicMatches(const [], loaded: false);
    });
  }

  void _setPublicMatches(List<WireMatch> matches, {required bool loaded}) {
    if (identical(matches, _publicMatches) && loaded == _publicMatchesLoaded) {
      return;
    }
    _publicMatches = List.unmodifiable(matches);
    _publicMatchesLoaded = loaded;
    _notifyStateChanged();
  }
}
