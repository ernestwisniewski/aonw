part of 'game_rendering_coordinator.dart';

extension _GameRenderingCoordinatorWorldSync on GameRenderingCoordinator {
  void _syncTransportNetwork(GameClientState state) {
    final visibility = state.activePlayerVisibility;
    transportNetwork.sync(
      parent: grid,
      segments: state.transportNetwork.segments.where(
        (segment) =>
            segment.builtByPlayerId == state.activePlayerId ||
            !visibility.isEnabled ||
            visibility.canRememberStaticAt(segment.hex.col, segment.hex.row),
      ),
      cityCenters: state.citiesKnownToActivePlayer.map((city) => city.center),
    );
  }

  void _syncArtifactMarkers(GameClientState state, Component world) {
    final visibility = state.activePlayerVisibility;
    final occupiedHexes = {
      for (final unit in state.unitsVisibleToActivePlayer)
        CityHex(col: unit.col, row: unit.row),
    };
    final visibleArtifacts = state.artifacts
        .where((artifact) {
          final hex = _artifactMarkerHex(artifact);
          if (hex == null) return false;
          return !visibility.isEnabled ||
              visibility.canSeeDynamicAt(hex.col, hex.row);
        })
        .toList(growable: false);
    artifactMarkers.sync(
      parent: world,
      artifacts: visibleArtifacts,
      selectedHex: _selectedArtifactHex(state),
      occupiedHexes: occupiedHexes,
    );
  }

  void _syncMapObjectiveMarkers(GameClientState state, Component world) {
    final visibility = state.activePlayerVisibility;
    final occupiedHexes = {
      for (final unit in state.unitsVisibleToActivePlayer)
        CityHex(col: unit.col, row: unit.row),
    };
    final visibleObjectives = grid.mapData.objectives
        .where((objective) {
          final hex = objective.hex;
          return !visibility.isEnabled ||
              visibility.canRememberStaticAt(hex.col, hex.row);
        })
        .toList(growable: false);
    final snapshot = MapObjectiveRules.snapshot(
      objectives: visibleObjectives,
      cities: state.citiesKnownToActivePlayer,
      units: state.unitsVisibleToActivePlayer,
      holdStatesByObjectiveId: state.mapObjectiveHoldStatesByObjectiveId,
    );
    mapObjectiveMarkers.sync(
      parent: world,
      objectives: snapshot.entries,
      occupiedHexes: occupiedHexes,
    );
  }

  CityHex? _artifactMarkerHex(WorldArtifact artifact) {
    final location = artifact.location;
    return switch (location.kind) {
      WorldArtifactLocationKind.map || WorldArtifactLocationKind.excavation =>
        switch ((location.col, location.row)) {
          (final int col, final int row) => CityHex(col: col, row: row),
          _ => null,
        },
      WorldArtifactLocationKind.carried ||
      WorldArtifactLocationKind.stored => null,
    };
  }

  CityHex? _selectedArtifactHex(GameClientState state) {
    final selection = state.selection;
    final tile = selection?.tile;
    if (tile == null) return null;
    final selectedHex = CityHex(col: tile.col, row: tile.row);
    for (final artifact in state.artifacts) {
      if (_artifactMarkerHex(artifact) == selectedHex) return selectedHex;
    }
    return null;
  }

  void _syncFogOfWar(GameClientState state) {
    fogOfWar.sync(
      parent: grid,
      mapData: grid.mapData,
      visibility: state.activePlayerVisibility,
    );
  }

  void _syncEraTint(GameClientState state) {
    eraTint.sync(
      parent: grid,
      mapData: grid.mapData,
      playerResearch: state.research.forPlayer(state.activePlayerId),
    );
  }
}
