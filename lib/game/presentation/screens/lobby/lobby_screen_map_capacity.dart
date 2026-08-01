part of 'lobby_screen.dart';

extension _LobbyScreenMapCapacity on _LobbyScreenState {
  void _scheduleMapPlayerCapacitySync(WorldMap mapData) {
    final maximumPlayers = MapPlayerCapacityRules.maxPlayersForWorldMap(
      mapData,
    );
    if (_players.maximumPlayers == maximumPlayers ||
        _scheduledMapMaximumPlayers == maximumPlayers) {
      return;
    }
    _scheduledMapMaximumPlayers = maximumPlayers;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduledMapMaximumPlayers = null;
      if (_players.updateMaximumPlayers(maximumPlayers)) {
        _refreshAfterMapCapacityChange();
      }
    });
  }
}
