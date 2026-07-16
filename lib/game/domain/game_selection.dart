import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

enum GameSelectionType { tile, fieldImprovement, unit, city }

final class SelectedTile implements MapTileView {
  SelectedTile._({
    required this.col,
    required this.row,
    required this.height,
    required Iterable<TerrainType> terrains,
    required Iterable<ResourceType> resources,
  }) : terrains = List.unmodifiable(terrains),
       resources = List.unmodifiable(resources);

  SelectedTile._withFrozenResources(SelectedTile source, this.resources)
    : col = source.col,
      row = source.row,
      height = source.height,
      terrains = source.terrains;

  factory SelectedTile.fromMapTileView(MapTileView tile) {
    if (tile is SelectedTile) return tile;
    return SelectedTile._(
      col: tile.col,
      row: tile.row,
      height: tile.height,
      terrains: tile.terrains,
      resources: tile.resources,
    );
  }

  @override
  final int col;

  @override
  final int row;

  @override
  final int height;

  @override
  final List<TerrainType> terrains;

  @override
  final List<ResourceType> resources;

  @override
  TerrainType get primaryTerrain =>
      terrains.isEmpty ? TerrainType.ocean : terrains.first;

  SelectedTile withResources(Iterable<ResourceType> visibleResources) {
    final copied = List<ResourceType>.unmodifiable(visibleResources);
    if (_sameValues(resources, copied)) return this;
    return SelectedTile._withFrozenResources(this, copied);
  }

  static bool _sameValues<T>(List<T> left, List<T> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

class GameSelection {
  final GameSelectionType type;
  final SelectedTile? tile;
  final FieldImprovement? fieldImprovement;
  final GameUnit? unit;
  final GameCity? city;
  final TileYield? cityYield;
  final CityTileYieldBreakdown? cityTileYieldBreakdown;
  final CityEconomyBreakdown? cityEconomy;
  final int? cityPlayerColor;

  GameSelection._({
    required this.type,
    this.tile,
    this.fieldImprovement,
    this.unit,
    this.city,
    this.cityYield,
    this.cityTileYieldBreakdown,
    this.cityEconomy,
    this.cityPlayerColor,
  }) : assert(
         type != GameSelectionType.city ||
             (cityTileYieldBreakdown == null) == (cityEconomy == null),
         'City tile breakdown and economy must form one cached snapshot.',
       ),
       assert(
         cityTileYieldBreakdown == null ||
             cityYield == cityTileYieldBreakdown.total,
         'Cached city tile breakdown must match the raw city yield.',
       ),
       assert(
         cityEconomy == null || cityEconomy.tileYield == cityYield,
         'Cached city economy must match the raw city yield.',
       );

  GameSelection.tile(MapTileView tile)
    : this._(
        type: GameSelectionType.tile,
        tile: SelectedTile.fromMapTileView(tile),
      );

  GameSelection.unit(GameUnit unit, {MapTileView? tile})
    : this._(
        type: GameSelectionType.unit,
        unit: unit,
        tile: tile == null ? null : SelectedTile.fromMapTileView(tile),
      );

  GameSelection.fieldImprovement(
    FieldImprovement fieldImprovement, {
    MapTileView? tile,
  }) : this._(
         type: GameSelectionType.fieldImprovement,
         fieldImprovement: fieldImprovement,
         tile: tile == null ? null : SelectedTile.fromMapTileView(tile),
       );

  GameSelection.city(
    GameCity city, {
    required TileYield cityYield,
    CityTileYieldBreakdown? cityTileYieldBreakdown,
    CityEconomyBreakdown? cityEconomy,
    required int playerColor,
  }) : this._(
         type: GameSelectionType.city,
         city: city,
         cityYield: cityYield,
         cityTileYieldBreakdown: cityTileYieldBreakdown,
         cityEconomy: cityEconomy,
         cityPlayerColor: playerColor,
       );

  GameSelection withVisibleResources({
    required String playerId,
    required ResearchState research,
  }) {
    final selectedTile = tile;
    if (selectedTile == null) return this;

    final visibleResources = ResourceVisibilityRules.visibleResources(
      resources: selectedTile.resources,
      playerId: playerId,
      research: research,
    );
    final visibleTile = selectedTile.withResources(visibleResources);
    if (identical(visibleTile, selectedTile)) return this;
    return switch (type) {
      GameSelectionType.tile => GameSelection.tile(visibleTile),
      GameSelectionType.unit =>
        unit == null ? this : GameSelection.unit(unit!, tile: visibleTile),
      GameSelectionType.fieldImprovement =>
        fieldImprovement == null
            ? this
            : GameSelection.fieldImprovement(
                fieldImprovement!,
                tile: visibleTile,
              ),
      GameSelectionType.city => this,
    };
  }
}
