import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';

enum GameSelectionType { tile, fieldImprovement, unit, city }

class SelectedTile {
  final int col;
  final int row;
  final int height;
  final List<TerrainType> terrains;
  final List<ResourceType> resources;

  const SelectedTile({
    required this.col,
    required this.row,
    required this.height,
    required this.terrains,
    required this.resources,
  });

  factory SelectedTile.fromTileData(TileData tile) => SelectedTile(
    col: tile.col,
    row: tile.row,
    height: tile.height,
    terrains: List.unmodifiable(tile.terrains),
    resources: List.unmodifiable(tile.resources),
  );

  TileData toTileData() => TileData(
    col: col,
    row: row,
    terrains: terrains,
    resources: resources,
    height: height,
  );
}

class GameSelection {
  final GameSelectionType type;
  final SelectedTile? tile;
  final FieldImprovement? fieldImprovement;
  final GameUnit? unit;
  final GameCity? city;
  final TileYield? cityYield;
  final CityEconomyBreakdown? cityEconomy;
  final int? cityPlayerColor;

  const GameSelection._({
    required this.type,
    this.tile,
    this.fieldImprovement,
    this.unit,
    this.city,
    this.cityYield,
    this.cityEconomy,
    this.cityPlayerColor,
  });

  GameSelection.tile(TileData tile)
    : this._(
        type: GameSelectionType.tile,
        tile: SelectedTile.fromTileData(tile),
      );

  GameSelection.unit(GameUnit unit, {TileData? tile})
    : this._(
        type: GameSelectionType.unit,
        unit: unit,
        tile: tile == null ? null : SelectedTile.fromTileData(tile),
      );

  GameSelection.fieldImprovement(
    FieldImprovement fieldImprovement, {
    TileData? tile,
  }) : this._(
         type: GameSelectionType.fieldImprovement,
         fieldImprovement: fieldImprovement,
         tile: tile == null ? null : SelectedTile.fromTileData(tile),
       );

  GameSelection.city(
    GameCity city, {
    required TileYield cityYield,
    CityEconomyBreakdown? cityEconomy,
    required int playerColor,
  }) : this._(
         type: GameSelectionType.city,
         city: city,
         cityYield: cityYield,
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
    if (_sameResources(selectedTile.resources, visibleResources)) return this;

    final visibleTile = selectedTile.toTileData().copyWith(
      resources: visibleResources,
    );
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

  static bool _sameResources(
    List<ResourceType> left,
    List<ResourceType> right,
  ) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
