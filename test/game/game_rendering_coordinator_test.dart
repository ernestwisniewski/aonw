import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/presentation/engine/game_render_view_model.dart';
import 'package:aonw/game/presentation/engine/game_rendering_coordinator.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/artifact_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_founding_preview_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_management_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_territory_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/era_tint_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/fog_of_war_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/threat_overlay_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_move_preview.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_move_preview_layer.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_objective_marker_layer.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _map() => MapData(
  cols: 4,
  rows: 1,
  tiles: [
    for (var col = 0; col < 4; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);

MapData _mapWithObjectives(List<MapObjectiveDefinition> objectives) => MapData(
  cols: 4,
  rows: 1,
  objectives: objectives,
  tiles: [
    for (var col = 0; col < 4; col++)
      TileData(
        col: col,
        row: 0,
        terrains: const [TerrainType.grassland],
        resources: const [],
        height: 0,
      ),
  ],
);

TileData _tile(MapData map, int col) =>
    map.tiles.firstWhere((tile) => tile.col == col && tile.row == 0);

QueuedMovePath _queuedPath() => QueuedMovePath(
  targetCol: 3,
  targetRow: 0,
  steps: const [
    UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
    UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
    UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 3),
  ],
);

GameRenderingCoordinator _coordinator({
  required MapData map,
  required _RecordingMovePreviewLayer movePreview,
  UnitMarkerLayer? unitMarkers,
  FieldImprovementMarkerLayer? fieldImprovementMarkers,
  ArtifactMarkerLayer? artifactMarkers,
  MapObjectiveMarkerLayer? mapObjectiveMarkers,
  CityMarkerLayer? cityMarkers,
  CityTerritoryOverlayLayer? cityTerritory,
  CityManagementOverlayLayer? cityManagement,
  ThreatOverlayLayer? threatOverlay,
}) {
  return GameRenderingCoordinator(
    unitMarkers: unitMarkers ?? _NoopUnitMarkerLayer(map),
    movePreview: movePreview,
    fieldImprovementMarkers:
        fieldImprovementMarkers ?? _NoopFieldImprovementMarkerLayer(),
    artifactMarkers: artifactMarkers ?? _NoopArtifactMarkerLayer(),
    mapObjectiveMarkers: mapObjectiveMarkers ?? _NoopMapObjectiveMarkerLayer(),
    cityMarkers: cityMarkers ?? _NoopCityMarkerLayer(),
    cityTerritory: cityTerritory ?? _NoopCityTerritoryOverlayLayer(),
    eraTint: _NoopEraTintOverlayLayer(),
    cityManagement: cityManagement ?? _NoopCityManagementOverlayLayer(),
    cityFounding: _NoopCityFoundingPreviewLayer(),
    fogOfWar: _NoopFogOfWarOverlayLayer(),
    threatOverlay: threatOverlay ?? _NoopThreatOverlayLayer(),
    actionPalette: ActionPaletteLayer(
      onPreviewWorkerImprovement: (_, _) {},
      onConfirmWorkerImprovement: (_) {},
      onCancelWorkerActionSelection: (_) {},
      onConfirmMovePreview: (_, _) {},
    ),
    grid: HexGrid(mapData: map, config: MapConfig.defaultConfig),
  );
}

void main() {
  group('GameRenderingCoordinator move preview', () {
    test('does not show queued path for selected enemy unit', () {
      final map = _map();
      final enemy = GameUnit(
        id: 'enemy',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      ).copyWithQueuedPath(_queuedPath());
      final movePreview = _RecordingMovePreviewLayer();

      _coordinator(map: map, movePreview: movePreview).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          units: [enemy],
          selection: GameSelection.unit(enemy, tile: _tile(map, 0)),
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(movePreview.lastPreview, isNull);
    });

    test('shows queued path for selected own unit', () {
      final map = _map();
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
      ).copyWithQueuedPath(_queuedPath());
      final movePreview = _RecordingMovePreviewLayer();

      _coordinator(map: map, movePreview: movePreview).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          units: [commander],
          selection: GameSelection.unit(commander, tile: _tile(map, 0)),
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(movePreview.lastPreview?.unitId, commander.id);
      expect(movePreview.lastPreview?.targetCol, 3);
      expect(movePreview.lastPreview?.steps, hasLength(3));
      expect(movePreview.lastUnitType, GameUnitType.commander);
      expect(movePreview.lastSubdued, isFalse);
      expect(movePreview.lastShowCostLabel, isTrue);
      expect(movePreview.lastShowConfirmationHint, isFalse);
      expect(movePreview.lastShowConfirmedTarget, isTrue);
    });

    test('shows queued path for deselected own unit', () {
      final map = _map();
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
      ).copyWithQueuedPath(_queuedPath());
      final movePreview = _RecordingMovePreviewLayer();

      _coordinator(map: map, movePreview: movePreview).syncAll(
        state: GameState(activePlayerId: 'player_1', units: [commander]),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(movePreview.lastPreview?.unitId, commander.id);
      expect(movePreview.lastPreview?.targetCol, 3);
      expect(movePreview.lastUnitType, GameUnitType.commander);
      expect(movePreview.lastSubdued, isTrue);
      expect(movePreview.lastShowCostLabel, isFalse);
      expect(movePreview.lastShowConfirmationHint, isFalse);
      expect(movePreview.lastShowConfirmedTarget, isFalse);
    });

    test('shows queued paths for every controllable unit', () {
      final map = _map();
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
      ).copyWithQueuedPath(_queuedPath());
      final worker =
          GameUnit(
            id: 'worker',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            name: GameUnitType.worker.defaultNameToken,
            col: 1,
            row: 0,
          ).copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 2,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 2,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          );
      final movePreview = _RecordingMovePreviewLayer();

      _coordinator(map: map, movePreview: movePreview).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          units: [commander, worker],
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(
        movePreview.lastPreviews.map((preview) => preview.unitId),
        containsAll([commander.id, worker.id]),
      );
    });

    test('renders merchant trade routes with the trade route style', () {
      final map = _map();
      final merchant =
          GameUnit(
            id: 'merchant',
            ownerPlayerId: 'player_1',
            type: GameUnitType.merchant,
            name: GameUnitType.merchant.defaultNameToken,
            col: 1,
            row: 0,
          ).copyWithMerchantTradeRoute(
            MerchantTradeRoute(
              originCityId: 'city_1',
              destinationCityId: 'city_2',
              steps: const [
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
                UnitMovementStep(
                  col: 3,
                  row: 0,
                  enterCost: 2,
                  cumulativeCost: 3,
                ),
              ],
            ),
          );
      final movePreview = _RecordingMovePreviewLayer();

      _coordinator(map: map, movePreview: movePreview).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          units: [merchant],
          selection: GameSelection.unit(merchant, tile: _tile(map, 1)),
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(movePreview.lastPreview?.unitId, merchant.id);
      expect(movePreview.lastPreview?.targetCol, 3);
      expect(movePreview.lastTravelledUpToIndex, 1);
      expect(movePreview.lastUnitType, GameUnitType.merchant);
      expect(movePreview.lastRouteKind, UnitMovePreviewRouteKind.trade);
      expect(movePreview.lastShowCostLabel, isFalse);
      expect(movePreview.lastShowConfirmedTarget, isTrue);
    });

    test('marks active move preview as confirmation state', () {
      final map = _map();
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final preview = UnitMovementPlan(
        unitId: commander.id,
        targetCol: 3,
        targetRow: 0,
        totalCost: 3,
        availableMovementPoints: 5,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 3),
        ],
      );
      final movePreview = _RecordingMovePreviewLayer();

      _coordinator(map: map, movePreview: movePreview).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          units: [commander],
          selection: GameSelection.unit(commander, tile: _tile(map, 0)),
          movePreview: preview,
          moveCommandActive: true,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(movePreview.lastPreview, preview);
      expect(movePreview.lastSubdued, isFalse);
      expect(movePreview.lastShowCostLabel, isFalse);
      expect(movePreview.lastShowConfirmationHint, isTrue);
      expect(movePreview.lastShowTargetPulse, isTrue);
      expect(movePreview.lastShowTargetArrow, isFalse);
      expect(movePreview.lastShowConfirmedTarget, isFalse);
    });

    test('mutes active move preview when its unit is not selected', () {
      final map = _map();
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final preview = UnitMovementPlan(
        unitId: commander.id,
        targetCol: 3,
        targetRow: 0,
        totalCost: 3,
        availableMovementPoints: 5,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
          UnitMovementStep(col: 3, row: 0, enterCost: 2, cumulativeCost: 3),
        ],
      );
      final movePreview = _RecordingMovePreviewLayer();

      _coordinator(map: map, movePreview: movePreview).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          units: [commander],
          movePreview: preview,
          moveCommandActive: true,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(movePreview.lastPreview, preview);
      expect(movePreview.lastSubdued, isTrue);
      expect(movePreview.lastShowCostLabel, isFalse);
      expect(movePreview.lastShowConfirmationHint, isFalse);
      expect(movePreview.lastShowTargetPulse, isFalse);
      expect(movePreview.lastShowTargetArrow, isFalse);
    });

    test('does not show stale active preview for enemy unit', () {
      final map = _map();
      final enemy = GameUnit(
        id: 'enemy',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 0,
      );
      final preview = UnitMovementPlan(
        unitId: enemy.id,
        targetCol: 1,
        targetRow: 0,
        totalCost: 1,
        availableMovementPoints: 5,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final movePreview = _RecordingMovePreviewLayer();

      _coordinator(map: map, movePreview: movePreview).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          units: [enemy],
          selection: GameSelection.unit(enemy, tile: _tile(map, 0)),
          movePreview: preview,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(movePreview.lastPreview, isNull);
    });

    test('passes city health to city markers', () {
      final map = _map();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
        hitPoints: 4,
      );
      final cityMarkers = _RecordingCityMarkerLayer();

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        cityMarkers: cityMarkers,
      ).syncAll(
        state: const GameState(cities: [city]),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(cityMarkers.lastHealthFractions[city.id], closeTo(0.25, 0.0001));
    });

    test('passes city label visibility to city markers', () {
      final map = _map();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );
      final cityMarkers = _RecordingCityMarkerLayer();

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        cityMarkers: cityMarkers,
      ).syncAll(
        state: const GameState(cities: [city]),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
        showCityLabels: false,
      );

      expect(cityMarkers.lastShowLabels, isFalse);
    });

    test('passes stored artifact badges to city markers', () {
      final map = _map();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );
      const artifact = WorldArtifact(
        id: 'artifact.crown',
        type: WorldArtifactType.ancientImperialCrown,
        location: WorldArtifactLocation.stored(cityId: 'city_1'),
      );
      final cityMarkers = _RecordingCityMarkerLayer();

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        cityMarkers: cityMarkers,
      ).syncAll(
        state: const GameState(cities: [city], artifacts: [artifact]),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(cityMarkers.lastCitiesWithStoredArtifacts, {city.id});
    });

    test('passes research state to city markers for technology variants', () {
      final map = _map();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.steamPower},
          ),
        },
      );
      final cityMarkers = _RecordingCityMarkerLayer();

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        cityMarkers: cityMarkers,
      ).syncAll(
        state: GameState(cities: [city], research: research),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(cityMarkers.lastResearch, research);
    });

    test('passes visible field improvements to improvement markers', () {
      final map = _map();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      const improvement = FieldImprovement(
        hex: CityHex(col: 1, row: 0),
        type: FieldImprovementType.farm,
        builtByCityId: 'city_1',
      );
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.coalMining},
          ),
        },
      );
      final fieldImprovementMarkers = _RecordingFieldImprovementMarkerLayer();

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        fieldImprovementMarkers: fieldImprovementMarkers,
      ).syncAll(
        state: GameState(
          cities: const [city],
          fieldImprovements: const [improvement],
          research: research,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(fieldImprovementMarkers.lastImprovements, const [improvement]);
      expect(fieldImprovementMarkers.lastCities, const [city]);
      expect(fieldImprovementMarkers.lastResearch, research);
    });

    test('selects improvement marker without selecting the hex grid tile', () {
      final map = _map();
      const improvement = FieldImprovement(
        hex: CityHex(col: 1, row: 0),
        type: FieldImprovementType.farm,
      );
      final fieldImprovementMarkers = _RecordingFieldImprovementMarkerLayer();
      final coordinator = _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        fieldImprovementMarkers: fieldImprovementMarkers,
      );
      final grid = coordinator.grid;

      coordinator.syncAll(
        state: GameState(
          fieldImprovements: const [improvement],
          selection: GameSelection.fieldImprovement(
            improvement,
            tile: _tile(map, 1),
          ),
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(fieldImprovementMarkers.lastSelectedHex, improvement.hex);
      expect(grid.selectedTileCoords, isNull);
    });

    test('passes visible map artifacts to artifact markers', () {
      final map = _map();
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.astronomersTablets,
        col: 1,
        row: 0,
      );
      final carried = artifact.copyWith(
        location: const WorldArtifactLocation.carried(unitId: 'scout_1'),
      );
      final artifactMarkers = _RecordingArtifactMarkerLayer();
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 1, row: 0)},
          ),
        },
      );

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        artifactMarkers: artifactMarkers,
      ).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          artifacts: [artifact, carried],
          fogOfWar: fog,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(artifactMarkers.lastArtifacts, [artifact]);
    });

    test('keeps own units visible when fog only reveals an artifact hex', () {
      final map = _map();
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.astronomersTablets,
        col: 1,
        row: 0,
      );
      final ownUnit = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 0,
        row: 0,
      );
      final hiddenEnemy = GameUnit(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 3,
        row: 0,
      );
      final unitMarkers = _RecordingUnitMarkerLayer(map);
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 1, row: 0)},
          ),
        },
      );

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        unitMarkers: unitMarkers,
      ).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          units: [ownUnit, hiddenEnemy],
          artifacts: [artifact],
          fogOfWar: fog,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(unitMarkers.lastUnits.map((unit) => unit.id), [ownUnit.id]);
    });

    test('keeps artifact markers visible under visible unit markers', () {
      final map = _map();
      final occupiedArtifact = WorldArtifact.placed(
        type: WorldArtifactType.astronomersTablets,
        col: 1,
        row: 0,
      );
      final clearArtifact = WorldArtifact.placed(
        type: WorldArtifactType.merchantsSeal,
        col: 2,
        row: 0,
      );
      final unit = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 1,
        row: 0,
      );
      final artifactMarkers = _RecordingArtifactMarkerLayer();
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 1, row: 0),
              const HexCoordinate(col: 2, row: 0),
            },
          ),
        },
      );

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        artifactMarkers: artifactMarkers,
      ).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          units: [unit],
          artifacts: [occupiedArtifact, clearArtifact],
          fogOfWar: fog,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(artifactMarkers.lastArtifacts, [occupiedArtifact, clearArtifact]);
      expect(artifactMarkers.lastOccupiedHexes, {
        const CityHex(col: 1, row: 0),
      });
    });

    test('keeps artifact markers hidden outside active vision', () {
      final map = _map();
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.merchantsSeal,
        col: 1,
        row: 0,
      );
      final artifactMarkers = _RecordingArtifactMarkerLayer();
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {const HexCoordinate(col: 1, row: 0)},
          ),
        },
      );

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        artifactMarkers: artifactMarkers,
      ).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          artifacts: [artifact],
          fogOfWar: fog,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(artifactMarkers.lastArtifacts, isEmpty);
    });

    test(
      'passes visible map objectives with progress to objective markers',
      () {
        const objective = MapObjectiveDefinition(
          id: 'pass_1',
          type: MapObjectiveType.strategicPass,
          hex: CityHex(col: 1, row: 0),
          requiredHoldTurns: 2,
        );
        final map = _mapWithObjectives([objective]);
        final unit = GameUnit(
          id: 'spearman_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.spearman,
          name: 'Wlocznik',
          col: 1,
          row: 0,
        );
        final objectiveMarkers = _RecordingMapObjectiveMarkerLayer();
        final fog = FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: {const HexCoordinate(col: 1, row: 0)},
            ),
          },
        );

        _coordinator(
          map: map,
          movePreview: _RecordingMovePreviewLayer(),
          mapObjectiveMarkers: objectiveMarkers,
        ).syncAll(
          state: GameState(
            activePlayerId: 'player_1',
            units: [unit],
            fogOfWar: fog,
            mapObjectiveHoldStatesByObjectiveId: const {
              'pass_1': MapObjectiveHoldState(
                objectiveId: 'pass_1',
                playerId: 'player_1',
                holdTurns: 2,
              ),
            },
          ),
          parent: Component(),
          viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
        );

        expect(objectiveMarkers.lastObjectives, hasLength(1));
        final progress = objectiveMarkers.lastObjectives.single;
        expect(progress.definition.id, 'pass_1');
        expect(progress.controllingPlayerId, 'player_1');
        expect(progress.completed, isTrue);
      },
    );

    test('keeps map objectives hidden outside remembered vision', () {
      const objective = MapObjectiveDefinition(
        id: 'ruins_1',
        type: MapObjectiveType.ruins,
        hex: CityHex(col: 1, row: 0),
      );
      final map = _mapWithObjectives([objective]);
      final objectiveMarkers = _RecordingMapObjectiveMarkerLayer();
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 2, row: 0)},
          ),
        },
      );

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        mapObjectiveMarkers: objectiveMarkers,
      ).syncAll(
        state: GameState(activePlayerId: 'player_1', fogOfWar: fog),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(objectiveMarkers.lastObjectives, isEmpty);
    });

    test(
      'highlights improvement city territory without selecting city marker',
      () {
        final map = _map();
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 1, row: 0)],
        );
        const improvement = FieldImprovement(
          hex: CityHex(col: 1, row: 0),
          type: FieldImprovementType.farm,
          builtByCityId: 'city_1',
        );
        final cityTerritory = _RecordingCityTerritoryOverlayLayer();
        final cityMarkers = _RecordingCityMarkerLayer();

        _coordinator(
          map: map,
          movePreview: _RecordingMovePreviewLayer(),
          cityTerritory: cityTerritory,
          cityMarkers: cityMarkers,
        ).syncAll(
          state: GameState(
            cities: const [city],
            fieldImprovements: const [improvement],
            selection: GameSelection.fieldImprovement(
              improvement,
              tile: _tile(map, 1),
            ),
          ),
          parent: Component(),
          viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
        );

        expect(cityTerritory.lastSelectedCityId, city.id);
        expect(cityMarkers.lastSelectedCityId, isNull);
      },
    );

    test('passes strategic view to city territory overlay', () {
      final map = _map();
      final cityTerritory = _RecordingCityTerritoryOverlayLayer();

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        cityTerritory: cityTerritory,
      ).syncAll(
        state: const GameState(
          cities: [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 0, row: 0),
            ),
          ],
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
        strategicView: true,
      );

      expect(cityTerritory.lastStrategicView, isTrue);
    });

    test('keeps discovered city territory visible in fog memory', () {
      final map = _map();
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_2',
        name: 'Remembered',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 2, row: 0)],
      );
      final cityTerritory = _RecordingCityTerritoryOverlayLayer();
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
            },
          ),
        },
      );

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        cityTerritory: cityTerritory,
      ).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          cities: const [city],
          fogOfWar: fog,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(cityTerritory.lastCities, const [city]);
      expect(cityTerritory.lastShownHexesByCity[city.id], const [
        CityHex(col: 0, row: 0),
        CityHex(col: 1, row: 0),
      ]);
    });

    test('syncs threat overlay while attack targeting is active', () {
      final map = _map();
      final threatOverlay = _RecordingThreatOverlayLayer();
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
      final state = GameState(
        activePlayerId: 'player_1',
        units: [warrior],
        selection: GameSelection.unit(warrior, tile: _tile(map, 0)),
        pendingAction: PendingAttackTargeting(
          ownerPlayerId: warrior.ownerPlayerId,
          attackerUnitId: warrior.id,
        ),
      );

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        threatOverlay: threatOverlay,
      ).syncAll(
        state: state,
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(threatOverlay.lastState, same(state));
      expect(threatOverlay.lastMapData, same(map));
      expect(threatOverlay.lastDimmed, isFalse);
    });

    test('keeps threat overlay hidden until attack action is selected', () {
      final map = _map();
      final threatOverlay = _RecordingThreatOverlayLayer();
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'player_1');

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        threatOverlay: threatOverlay,
      ).syncAll(
        state: GameState(
          activePlayerId: 'player_1',
          units: [warrior],
          selection: GameSelection.unit(warrior, tile: _tile(map, 0)),
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(threatOverlay.clearCount, 1);
      expect(threatOverlay.lastState, isNull);
    });

    test('keeps threat overlay out of civilian unit decisions', () {
      final map = _map();
      final threatOverlay = _RecordingThreatOverlayLayer();
      final worker = GameUnit(
        id: 'worker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 0,
        row: 0,
      );
      final enemy = GameUnit.startingWarrior(ownerPlayerId: 'player_2');

      _coordinator(
        map: map,
        movePreview: _RecordingMovePreviewLayer(),
        threatOverlay: threatOverlay,
      ).syncAll(
        state: GameState(
          units: [worker, enemy],
          selection: GameSelection.unit(worker, tile: _tile(map, 0)),
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(threatOverlay.clearCount, 1);
      expect(threatOverlay.lastState, isNull);
    });

    test('keeps context overlays quiet while move targeting is active', () {
      final map = _map();
      final movePreview = _RecordingMovePreviewLayer();
      final threatOverlay = _RecordingThreatOverlayLayer();
      final cityManagement = _RecordingCityManagementOverlayLayer();
      final warrior = GameUnit.startingWarrior(
        ownerPlayerId: 'player_1',
      ).copyWithQueuedPath(_queuedPath());

      _coordinator(
        map: map,
        movePreview: movePreview,
        cityManagement: cityManagement,
        threatOverlay: threatOverlay,
      ).syncAll(
        state: GameState(
          units: [warrior],
          selection: GameSelection.unit(warrior, tile: _tile(map, 0)),
          moveCommandActive: true,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(movePreview.lastDimmed, isFalse);
      expect(threatOverlay.clearCount, 1);
      expect(threatOverlay.lastDimmed, isNull);
      expect(cityManagement.lastDimmed, isTrue);
    });

    test(
      'keeps selected worker improvement markers readable during movement',
      () {
        final map = _map();
        final movePreview = _RecordingMovePreviewLayer();
        final cityManagement = _RecordingCityManagementOverlayLayer();
        final worker = GameUnit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: 0,
          row: 0,
        );

        _coordinator(
          map: map,
          movePreview: movePreview,
          cityManagement: cityManagement,
        ).syncAll(
          state: GameState(
            activePlayerId: 'player_1',
            units: [worker],
            selection: GameSelection.unit(worker, tile: _tile(map, 0)),
            moveCommandActive: true,
          ),
          parent: Component(),
          viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
        );

        expect(cityManagement.lastDimmed, isFalse);
      },
    );

    test('dims move preview while attack targeting owns the decision', () {
      final map = _map();
      final movePreview = _RecordingMovePreviewLayer();
      final threatOverlay = _RecordingThreatOverlayLayer();
      final attacker = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
      final preview = UnitMovementPlan(
        unitId: attacker.id,
        targetCol: 1,
        targetRow: 0,
        totalCost: 1,
        availableMovementPoints: 5,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      );

      _coordinator(
        map: map,
        movePreview: movePreview,
        threatOverlay: threatOverlay,
      ).syncAll(
        state: GameState(
          units: [attacker],
          selection: GameSelection.unit(attacker, tile: _tile(map, 0)),
          pendingAction: PendingAttackTargeting(
            ownerPlayerId: attacker.ownerPlayerId,
            attackerUnitId: attacker.id,
          ),
          movePreview: preview,
        ),
        parent: Component(),
        viewModelNotifier: ValueNotifier(GameRenderViewModel.empty),
      );

      expect(movePreview.lastDimmed, isTrue);
      expect(threatOverlay.lastDimmed, isFalse);
    });
  });
}

class _RecordingMovePreviewLayer extends UnitMovePreviewLayer {
  UnitMovementPlan? lastPreview;
  List<UnitMovementPlan> lastPreviews = const [];
  int? lastTravelledUpToIndex;
  GameUnitType? lastUnitType;
  UnitMovePreviewRouteKind? lastRouteKind;
  bool? lastDimmed;
  bool? lastSubdued;
  bool? lastShowCostLabel;
  bool? lastShowConfirmationHint;
  bool? lastShowTargetPulse;
  bool? lastShowTargetArrow;
  bool? lastShowConfirmedTarget;

  @override
  void sync({
    required Component parent,
    required UnitMovementPlan? preview,
    int travelledUpToIndex = 0,
    GameUnitType? unitType,
    UnitMovePreviewRouteKind routeKind = UnitMovePreviewRouteKind.movement,
    bool dimmed = false,
    bool showConfirmationHint = false,
    bool showTargetPulse = false,
    bool showTargetArrow = false,
    bool showConfirmedTarget = false,
  }) {
    syncMany(
      parent: parent,
      previews: preview == null
          ? const []
          : [
              UnitMovePreviewLayerEntry(
                id: preview.unitId,
                preview: preview,
                travelledUpToIndex: travelledUpToIndex,
                unitType: unitType,
                routeKind: routeKind,
                dimmed: dimmed,
                subdued: false,
                showCostLabel: true,
                showConfirmationHint: showConfirmationHint,
                showTargetPulse: showTargetPulse,
                showTargetArrow: showTargetArrow,
                showConfirmedTarget: showConfirmedTarget,
              ),
            ],
    );
  }

  @override
  void syncMany({
    required Component parent,
    required Iterable<UnitMovePreviewLayerEntry> previews,
  }) {
    final entries = previews.toList(growable: false);
    lastPreviews = [for (final entry in entries) entry.preview];
    final last = entries.isEmpty ? null : entries.last;
    lastPreview = last?.preview;
    lastTravelledUpToIndex = last?.travelledUpToIndex;
    lastUnitType = last?.unitType;
    lastRouteKind = last?.routeKind;
    lastDimmed = last?.dimmed;
    lastSubdued = last?.subdued;
    lastShowCostLabel = last?.showCostLabel;
    lastShowConfirmationHint = last?.showConfirmationHint;
    lastShowTargetPulse = last?.showTargetPulse;
    lastShowTargetArrow = last?.showTargetArrow;
    lastShowConfirmedTarget = last?.showConfirmedTarget;
  }

  @override
  void clear() {
    lastPreview = null;
    lastPreviews = const [];
    lastTravelledUpToIndex = null;
    lastUnitType = null;
    lastRouteKind = null;
    lastDimmed = null;
    lastSubdued = null;
    lastShowCostLabel = null;
    lastShowConfirmationHint = null;
    lastShowTargetPulse = null;
    lastShowTargetArrow = null;
    lastShowConfirmedTarget = null;
  }
}

class _NoopUnitMarkerLayer extends UnitMarkerLayer {
  _NoopUnitMarkerLayer(MapData map)
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
  _RecordingUnitMarkerLayer(MapData map)
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

  _RecordingCityMarkerLayer() : super(colorForPlayer: (_) => 0);

  @override
  void sync({
    required Component parent,
    required Iterable<GameCity> cities,
    required String? selectedCityId,
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
    required MapData mapData,
    required PlayerResearchState playerResearch,
  }) {}
}

class _NoopCityManagementOverlayLayer extends CityManagementOverlayLayer {
  @override
  void sync({
    required Component parent,
    required GameState state,
    required MapData mapData,
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
    required GameState state,
    required MapData mapData,
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
    required MapData mapData,
    required Iterable<GameCity> cities,
    bool Function(CityHex hex)? canShowHex,
  }) {}
}

class _NoopFogOfWarOverlayLayer extends FogOfWarOverlayLayer {
  @override
  void sync({
    required Component parent,
    required MapData mapData,
    required FogVisibilityQuery visibility,
  }) {}
}

class _NoopThreatOverlayLayer extends ThreatOverlayLayer {
  @override
  void sync({
    required Component parent,
    required GameState state,
    required MapData mapData,
    CombatRuleset combatRuleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    bool dimmed = false,
  }) {}
}

class _RecordingThreatOverlayLayer extends ThreatOverlayLayer {
  GameState? lastState;
  MapData? lastMapData;
  bool? lastDimmed;
  var clearCount = 0;

  @override
  void sync({
    required Component parent,
    required GameState state,
    required MapData mapData,
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
