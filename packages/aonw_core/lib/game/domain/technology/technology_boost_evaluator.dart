import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/technology_boost.dart';
import 'package:aonw_core/game/domain/technology/technology_definition.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class TechnologyBoostEvaluator {
  static double bestDiscountFor({
    required String playerId,
    required TechnologyDefinition technology,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapData mapData,
  }) {
    var bestDiscount = 0.0;
    for (final boost in technology.boosts) {
      if (_isSatisfied(
        condition: boost.condition,
        playerId: playerId,
        cities: cities,
        fieldImprovements: fieldImprovements,
        mapData: mapData,
      )) {
        bestDiscount = bestDiscount < boost.discount
            ? boost.discount
            : bestDiscount;
      }
    }
    return bestDiscount;
  }

  static bool _isSatisfied({
    required TechnologyBoostCondition condition,
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapData mapData,
  }) {
    return switch (condition) {
      HasImprovementCount(:final improvementType, :final count) =>
        _ownedImprovements(
                  playerId: playerId,
                  cities: cities,
                  fieldImprovements: fieldImprovements,
                )
                .where((improvement) => improvement.type == improvementType)
                .length >=
            count,
      HasAnyImprovement(:final improvementType) => _ownedImprovements(
        playerId: playerId,
        cities: cities,
        fieldImprovements: fieldImprovements,
      ).any((improvement) => improvement.type == improvementType),
      ControlsResource(:final resourceType) => _controlledTiles(
        playerId: playerId,
        cities: cities,
        mapData: mapData,
      ).any((tile) => tile.resources.contains(resourceType)),
      ControlsAnyResource(:final resourceTypes) => _controlledTiles(
        playerId: playerId,
        cities: cities,
        mapData: mapData,
      ).any((tile) => tile.resources.any(resourceTypes.contains)),
    };
  }

  static Iterable<FieldImprovement> _ownedImprovements({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
  }) sync* {
    final playerCities = cities
        .where((city) => city.ownerPlayerId == playerId)
        .toList(growable: false);
    final playerCityIds = playerCities.map((city) => city.id).toSet();

    for (final improvement in fieldImprovements) {
      if (improvement.builtByCityId != null &&
          playerCityIds.contains(improvement.builtByCityId)) {
        yield improvement;
        continue;
      }

      if (playerCities.any((city) => city.controlsHex(improvement.hex))) {
        yield improvement;
      }
    }
  }

  static Iterable<TileData> _controlledTiles({
    required String playerId,
    required Iterable<GameCity> cities,
    required MapData mapData,
  }) sync* {
    for (final city in cities) {
      if (city.ownerPlayerId != playerId) continue;
      for (final hex in city.territoryHexes) {
        final tile = mapData.tileAt(hex.col, hex.row);
        if (tile != null) yield tile;
      }
    }
  }
}
