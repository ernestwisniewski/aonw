part of 'game_rendering_coordinator_test.dart';

class _NoopUnitMarkerLayer extends UnitMarkerLayer {
  _NoopUnitMarkerLayer(WorldMap map)
    : super(mapData: map, colorForPlayer: (_) => 0);

  @override
  void sync({
    required Component parent,
    required Iterable<GameUnit> units,
    required String? selectedUnitId,
    PendingPlayerAction? pendingAction,
    String? pendingActionUnitId,
    Set<String> attackTargetUnitIds = const {},
    Set<({int col, int row})> cityTiles = const {},
    Map<String, int> artifactExcavationTurnsByUnitId = const {},
  }) {}
}

class _RecordingUnitMarkerLayer extends UnitMarkerLayer {
  _RecordingUnitMarkerLayer(WorldMap map)
    : super(mapData: map, colorForPlayer: (_) => 0);

  List<GameUnit> lastUnits = const [];

  @override
  void sync({
    required Component parent,
    required Iterable<GameUnit> units,
    required String? selectedUnitId,
    PendingPlayerAction? pendingAction,
    String? pendingActionUnitId,
    Set<String> attackTargetUnitIds = const {},
    Set<({int col, int row})> cityTiles = const {},
    Map<String, int> artifactExcavationTurnsByUnitId = const {},
  }) {
    lastUnits = units.toList(growable: false);
  }
}

class _NoopCityMarkerLayer extends CityMarkerLayer {
  _NoopCityMarkerLayer() : super(colorForPlayer: (_) => 0);

  @override
  void sync({
    required Component parent,
    required Iterable<GameCity> cities,
    required String? selectedCityId,
    String? highlightedPlayerId,
    Map<String, double> healthFractions = const {},
    bool showLabels = true,
    Set<String> citiesWithStoredArtifacts = const {},
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {}
}

class _NoopFieldImprovementMarkerLayer extends FieldImprovementMarkerLayer {
  @override
  void sync({
    required Component parent,
    required Iterable<FieldImprovement> improvements,
    required Iterable<GameCity> cities,
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    CityHex? selectedHex,
  }) {}
}

class _NoopArtifactMarkerLayer extends ArtifactMarkerLayer {
  @override
  void sync({
    required Component parent,
    required Iterable<WorldArtifact> artifacts,
    CityHex? selectedHex,
    Set<CityHex> occupiedHexes = const {},
  }) {}
}

class _NoopMapObjectiveMarkerLayer extends MapObjectiveMarkerLayer {
  _NoopMapObjectiveMarkerLayer() : super(colorForPlayer: (_) => 0);

  @override
  void sync({
    required Component parent,
    required Iterable<MapObjectiveProgress> objectives,
    Set<CityHex> occupiedHexes = const {},
  }) {}
}

class _RecordingMapObjectiveMarkerLayer extends MapObjectiveMarkerLayer {
  _RecordingMapObjectiveMarkerLayer() : super(colorForPlayer: (_) => 0);

  List<MapObjectiveProgress> lastObjectives = const [];
  Set<CityHex> lastOccupiedHexes = const {};

  @override
  void sync({
    required Component parent,
    required Iterable<MapObjectiveProgress> objectives,
    Set<CityHex> occupiedHexes = const {},
  }) {
    lastObjectives = objectives.toList(growable: false);
    lastOccupiedHexes = Set.unmodifiable(occupiedHexes);
  }
}

class _RecordingArtifactMarkerLayer extends ArtifactMarkerLayer {
  List<WorldArtifact> lastArtifacts = const [];
  CityHex? lastSelectedHex;
  Set<CityHex> lastOccupiedHexes = const {};

  @override
  void sync({
    required Component parent,
    required Iterable<WorldArtifact> artifacts,
    CityHex? selectedHex,
    Set<CityHex> occupiedHexes = const {},
  }) {
    lastArtifacts = artifacts.toList(growable: false);
    lastSelectedHex = selectedHex;
    lastOccupiedHexes = Set.unmodifiable(occupiedHexes);
  }
}

class _RecordingFieldImprovementMarkerLayer
    extends FieldImprovementMarkerLayer {
  List<FieldImprovement> lastImprovements = const [];
  List<GameCity> lastCities = const [];
  ResearchState? lastResearch;
  CityHex? lastSelectedHex;

  @override
  void sync({
    required Component parent,
    required Iterable<FieldImprovement> improvements,
    required Iterable<GameCity> cities,
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    CityHex? selectedHex,
  }) {
    lastImprovements = improvements.toList(growable: false);
    lastCities = cities.toList(growable: false);
    lastResearch = research;
    lastSelectedHex = selectedHex;
  }
}

class _RecordingCityMarkerLayer extends CityMarkerLayer {
  Map<String, double> lastHealthFractions = const {};
  bool? lastShowLabels;
  Set<String> lastCitiesWithStoredArtifacts = const {};
  ResearchState? lastResearch;
  String? lastSelectedCityId;
  String? lastHighlightedPlayerId;

  _RecordingCityMarkerLayer() : super(colorForPlayer: (_) => 0);

  @override
  void sync({
    required Component parent,
    required Iterable<GameCity> cities,
    required String? selectedCityId,
    String? highlightedPlayerId,
    Map<String, double> healthFractions = const {},
    bool showLabels = true,
    Set<String> citiesWithStoredArtifacts = const {},
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    lastHealthFractions = Map.unmodifiable(healthFractions);
    lastShowLabels = showLabels;
    lastCitiesWithStoredArtifacts = Set.unmodifiable(citiesWithStoredArtifacts);
    lastResearch = research;
    lastSelectedCityId = selectedCityId;
    lastHighlightedPlayerId = highlightedPlayerId;
  }
}

class _RecordingCityTerritoryOverlayLayer extends CityTerritoryOverlayLayer {
  String? lastSelectedCityId;
  bool? lastStrategicView;
  List<GameCity> lastCities = const [];
  Map<String, List<CityHex>> lastShownHexesByCity = const {};

  _RecordingCityTerritoryOverlayLayer() : super(colorForPlayer: (_) => 0);

  @override
  void sync({
    required Component parent,
    required Iterable<GameCity> cities,
    bool Function(CityHex hex)? canShowHex,
    String? selectedCityId,
    bool strategicView = false,
  }) {
    lastSelectedCityId = selectedCityId;
    lastStrategicView = strategicView;
    lastCities = cities.toList(growable: false);
    lastShownHexesByCity = {
      for (final city in lastCities)
        city.id: canShowHex == null
            ? city.territoryHexes
            : city.territoryHexes.where(canShowHex).toList(growable: false),
    };
  }
}

class _NoopCityTerritoryOverlayLayer extends CityTerritoryOverlayLayer {
  _NoopCityTerritoryOverlayLayer() : super(colorForPlayer: (_) => 0);

  @override
  void sync({
    required Component parent,
    required Iterable<GameCity> cities,
    bool Function(CityHex hex)? canShowHex,
    String? selectedCityId,
    bool strategicView = false,
  }) {}
}

class _NoopEraTintOverlayLayer extends EraTintOverlayLayer {
  @override
  void sync({
    required Component parent,
    required WorldMap mapData,
    required PlayerResearchState playerResearch,
  }) {}
}

class _NoopCityManagementOverlayLayer extends CityManagementOverlayLayer {
  @override
  void sync({
    required Component parent,
    required GameClientState state,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    bool Function(CityHex hex)? canShowHex,
    bool dimmed = false,
  }) {}
}

class _RecordingCityManagementOverlayLayer extends CityManagementOverlayLayer {
  bool? lastDimmed;

  @override
  void sync({
    required Component parent,
    required GameClientState state,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    bool Function(CityHex hex)? canShowHex,
    bool dimmed = false,
  }) {
    lastDimmed = dimmed;
  }
}

class _NoopCityFoundingPreviewLayer extends CityFoundingPreviewLayer {
  _NoopCityFoundingPreviewLayer() : super(colorForPlayer: (_) => 0);

  @override
  void sync({
    required Component parent,
    required CityFoundingDraft? draft,
    required WorldMap mapData,
    required Iterable<GameCity> cities,
    bool Function(CityHex hex)? canShowHex,
  }) {}
}

class _NoopFogOfWarOverlayLayer extends FogOfWarOverlayLayer {
  @override
  void sync({
    required Component parent,
    required WorldMap mapData,
    required FogVisibilityQuery visibility,
  }) {}
}

class _RecordingThreatOverlayLayer extends ThreatOverlayLayer {
  GameClientState? lastState;
  WorldMap? lastMapData;
  bool? lastDimmed;
  var clearCount = 0;

  @override
  void sync({
    required Component parent,
    required GameClientState state,
    required WorldMap mapData,
    CombatRuleset combatRuleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    bool dimmed = false,
  }) {
    lastState = state;
    lastMapData = mapData;
    lastDimmed = dimmed;
  }

  @override
  void clear() {
    clearCount++;
    lastState = null;
    lastMapData = null;
    lastDimmed = null;
  }
}
