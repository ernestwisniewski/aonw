import 'package:aonw/game/presentation/controllers/lobby_connection_controller.dart';
import 'package:aonw/game/presentation/screens/lobby/lobby_public_match_refresh_coordinator.dart';
import 'package:aonw_core/protocol.dart';

final Expando<LobbyPublicMatchRefreshCoordinator>
_lobbyPublicRefreshCoordinators = Expando();

extension LobbyConnectionPublicActions on LobbyConnectionController {
  List<WireMatch> get publicMatches => internalPublicMatches;

  bool get publicMatchesLoaded => internalPublicMatchesLoaded;

  Future<void> openPublicLobby() async {
    if (busy) return;
    stopLobbyUpdates();
    setStateInternal(
      error: null,
      activeMatch: null,
      mode: LobbyMultiplayerMode.publicBrowse,
    );
    setPublicMatchesInternal(const [], loaded: false);
    await refreshPublicMatches();
    if (canContinueInternal() && mode == LobbyMultiplayerMode.publicBrowse) {
      _publicRefreshCoordinator.start();
    }
  }

  Future<void> refreshPublicMatches() async {
    if (busy || mode != LobbyMultiplayerMode.publicBrowse) return;
    await runNetworkActionInternal(() async {
      final generation = ++internalPublicRefreshGeneration;
      try {
        final matches = await matchActionCoordinatorInternal()
            .listPublicMatches();
        if (!_isCurrentPublicRefresh(generation)) {
          return;
        }
        setPublicMatchesInternal(matches, loaded: true);
      } catch (_) {
        if (_isCurrentPublicRefresh(generation)) {
          setPublicMatchesInternal(const [], loaded: true);
        }
        rethrow;
      }
    });
  }

  Future<void> createPublicMatch({required String name}) async {
    if (busy) return;
    _publicRefreshCoordinator.stop();
    internalPublicRefreshGeneration += 1;
    var enteredLobby = false;
    await runNetworkActionInternal(() async {
      await matchActionCoordinatorInternal().createPublic(
        name: name,
        config: matchActionConfigInternal(),
      );
      if (!canContinueInternal() || activeMatch == null) return;
      setModeInternal(LobbyMultiplayerMode.publicMatch);
      setPublicMatchesInternal(const [], loaded: false);
      enteredLobby = true;
    });
    if (canContinueInternal() &&
        !enteredLobby &&
        mode == LobbyMultiplayerMode.publicBrowse) {
      _publicRefreshCoordinator.start();
    }
  }

  Future<void> leaveLobby() async {
    var leftLobby = false;
    await runNetworkActionInternal(() async {
      await matchActionCoordinatorInternal().leaveActiveLobby(
        activeMatch: activeMatch,
      );
      leftLobby = true;
    });
    if (!leftLobby || !canContinueInternal()) return;
    setStateInternal(
      error: null,
      activeMatch: null,
      mode: LobbyMultiplayerMode.home,
    );
  }

  Future<void> back() async {
    if (activeMatch == null) returnHome();
    if (activeMatch != null) await leaveLobby();
  }

  Future<void> joinPublicMatch({required String matchId}) async {
    if (busy) return;
    _publicRefreshCoordinator.stop();
    internalPublicRefreshGeneration += 1;
    var enteredLobby = false;
    await runNetworkActionInternal(() async {
      await matchActionCoordinatorInternal().joinPublic(
        matchId: matchId,
        config: matchActionConfigInternal(),
      );
      if (!canContinueInternal() || activeMatch == null) return;
      setModeInternal(LobbyMultiplayerMode.publicMatch);
      setPublicMatchesInternal(const [], loaded: false);
      enteredLobby = true;
    });
    if (canContinueInternal() &&
        !enteredLobby &&
        mode == LobbyMultiplayerMode.publicBrowse) {
      _publicRefreshCoordinator.start();
    }
  }

  void setPublicMatchesInternal(
    List<WireMatch> matches, {
    required bool loaded,
  }) {
    if (identical(matches, internalPublicMatches) &&
        loaded == internalPublicMatchesLoaded) {
      return;
    }
    internalPublicMatches = List.unmodifiable(matches);
    internalPublicMatchesLoaded = loaded;
    notifyStateChangedInternal();
  }

  LobbyPublicMatchRefreshCoordinator get _publicRefreshCoordinator {
    return _lobbyPublicRefreshCoordinators[this] ??=
        LobbyPublicMatchRefreshCoordinator(
          canRefresh: () =>
              canContinueInternal() &&
              !busy &&
              mode == LobbyMultiplayerMode.publicBrowse,
          refresh: _refreshPublicMatchesInBackground,
        );
  }

  Future<void> _refreshPublicMatchesInBackground() async {
    final generation = ++internalPublicRefreshGeneration;
    try {
      final matches = await matchActionCoordinatorInternal()
          .listPublicMatches();
      if (!_isCurrentPublicRefresh(generation)) return;
      setPublicMatchesInternal(matches, loaded: true);
    } catch (_) {
      if (_isCurrentPublicRefresh(generation)) {
        setPublicMatchesInternal(const [], loaded: true);
      }
    }
  }

  Future<void> restorePublicBrowseAfterUnavailableInternal() async {
    await _refreshPublicMatchesInBackground();
    if (canContinueInternal() && mode == LobbyMultiplayerMode.publicBrowse) {
      _publicRefreshCoordinator.start();
    }
  }

  bool _isCurrentPublicRefresh(int generation) {
    return canContinueInternal() &&
        mode == LobbyMultiplayerMode.publicBrowse &&
        generation == internalPublicRefreshGeneration;
  }
}

void stopLobbyUpdateCoordinatorsInternal(LobbyConnectionController controller) {
  controller.internalAutoStartCoordinator.cancel();
  _lobbyPublicRefreshCoordinators[controller]?.stop();
  controller.internalPublicRefreshGeneration += 1;
}
