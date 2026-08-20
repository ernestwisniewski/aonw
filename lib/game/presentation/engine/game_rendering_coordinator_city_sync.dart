part of 'game_rendering_coordinator.dart';

extension _GameRenderingCoordinatorCitySync on GameRenderingCoordinator {
  void _syncCityMarkers(
    GameClientState state,
    Component world, {
    required bool showCityLabels,
    required bool strategicView,
  }) {
    final knownCities = state.citiesKnownToActivePlayer;
    final visibility = state.activePlayerVisibility;
    final selection = state.selection;
    final selectedCityId = selection?.type == GameSelectionType.city
        ? selection?.city?.id
        : null;
    final selectedTerritoryCityId = _selectedTerritoryCityId(
      selection,
      knownCities,
    );
    final highlightedEmpirePlayerId = _cityOwnerPlayerId(
      selectedTerritoryCityId,
      knownCities,
    );
    cityTerritory.sync(
      parent: grid,
      cities: knownCities,
      selectedCityId: selectedTerritoryCityId,
      strategicView: strategicView,
      canShowHex: visibility.isEnabled
          ? (hex) => visibility.canRememberStaticAt(hex.col, hex.row)
          : null,
    );
    cityMarkers.sync(
      parent: world,
      cities: knownCities,
      selectedCityId: selectedCityId,
      highlightedPlayerId: highlightedEmpirePlayerId,
      healthFractions: _cityHealthFractions(state, knownCities),
      showLabels: showCityLabels,
      citiesWithStoredArtifacts: _citiesWithStoredArtifacts(state),
      research: state.research,
    );
  }

  Set<String> _citiesWithStoredArtifacts(GameClientState state) {
    return {
      for (final artifact in state.artifacts)
        if (artifact.location.isStored && artifact.location.cityId != null)
          artifact.location.cityId!,
    };
  }

  String? _cityOwnerPlayerId(String? cityId, Iterable<GameCity> cities) {
    if (cityId == null) return null;
    for (final city in cities) {
      if (city.id == cityId) return city.ownerPlayerId;
    }
    return null;
  }

  String? _selectedTerritoryCityId(
    GameSelection? selection,
    Iterable<GameCity> cities,
  ) {
    if (selection == null) return null;
    if (selection.type == GameSelectionType.city) {
      return selection.city?.id;
    }
    if (selection.type != GameSelectionType.fieldImprovement) {
      return null;
    }

    final improvement = selection.fieldImprovement;
    if (improvement == null) return null;

    final builtByCityId = improvement.builtByCityId;
    for (final city in cities) {
      if (city.id == builtByCityId || city.controlsHex(improvement.hex)) {
        return city.id;
      }
    }
    return null;
  }

  void _syncFieldImprovementMarkers(GameClientState state, Component world) {
    final visibility = state.activePlayerVisibility;
    final visibleImprovements = state.fieldImprovements
        .where(
          (improvement) =>
              !visibility.isEnabled ||
              visibility.canRememberStaticAt(
                improvement.hex.col,
                improvement.hex.row,
              ),
        )
        .toList(growable: false);
    fieldImprovementMarkers.sync(
      parent: world,
      improvements: visibleImprovements,
      cities: state.cities,
      research: state.research,
      selectedHex: _selectedFieldImprovementHex(state),
    );
  }

  CityHex? _selectedFieldImprovementHex(GameClientState state) {
    final selection = state.selection;
    if (selection?.type != GameSelectionType.fieldImprovement) return null;
    return selection?.fieldImprovement?.hex;
  }

  Map<String, double> _cityHealthFractions(
    GameClientState state,
    Iterable<GameCity> cities,
  ) {
    return {
      for (final city in cities) city.id: MarkerHealthFraction.forCity(city),
    };
  }

  void _syncCityManagement(GameClientState state, {required bool dimmed}) {
    final visibility = state.activePlayerVisibility;
    cityManagement.sync(
      parent: grid,
      state: state,
      mapData: grid.mapData,
      cityRuleset: CityRulesets.standard,
      canShowHex: visibility.isEnabled
          ? (hex) => visibility.canSeeDynamicAt(hex.col, hex.row)
          : null,
      dimmed: dimmed,
    );
  }

  bool _shouldDimCityManagementOverlay(GameClientState state) {
    final mode = state.interactionMode;
    final selectedUnit = state.selectedUnit;
    if (mode == GameInteractionMode.moveTargeting &&
        selectedUnit != null &&
        selectedUnit.isWorker &&
        !selectedUnit.isWorking &&
        state.canControlUnit(selectedUnit)) {
      return false;
    }
    return mode != GameInteractionMode.standard &&
        mode != GameInteractionMode.workerAction &&
        mode != GameInteractionMode.cityWorkedHexSelection &&
        mode != GameInteractionMode.cityExpansionSelection;
  }

  void _syncCityFounding(GameClientState state, Component world) {
    if (!grid.isMounted) return;
    final visibility = state.activePlayerVisibility;
    cityFounding.sync(
      parent: world,
      draft: state.cityFoundingDraft,
      mapData: grid.mapData,
      cities: state.cities,
      canShowHex: visibility.isEnabled
          ? (hex) => visibility.canSeeDynamicAt(hex.col, hex.row)
          : null,
    );
  }
}
