import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';

class CityEconomy {
  final int population;
  final int controlledHexCount;
  final int territoryHexCount;
  final TileYield yield;

  const CityEconomy({
    required this.population,
    required this.controlledHexCount,
    required this.territoryHexCount,
    required this.yield,
  });

  factory CityEconomy.from({required GameCity city, required TileYield yield}) {
    return CityEconomy(
      population: city.population,
      controlledHexCount: city.controlledHexes.length,
      territoryHexCount: city.territoryHexes.length,
      yield: yield,
    );
  }
}
