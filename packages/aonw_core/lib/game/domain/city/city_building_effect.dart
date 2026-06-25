import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';

sealed class CityBuildingEffect {
  const CityBuildingEffect();
}

class FlatCityYieldEffect extends CityBuildingEffect {
  final TileYield yield;

  const FlatCityYieldEffect(this.yield);
}

class FlatCityScienceEffect extends CityBuildingEffect {
  final int amount;

  const FlatCityScienceEffect(this.amount);
}

class RiverHexCityYieldEffect extends CityBuildingEffect {
  final TileYield yieldPerRiverHex;
  final int? maxApplications;

  const RiverHexCityYieldEffect({
    required this.yieldPerRiverHex,
    this.maxApplications,
  });
}

class MaxControlledHexesEffect extends CityBuildingEffect {
  final int amount;

  const MaxControlledHexesEffect(this.amount);
}

class FoodDepositMultiplierEffect extends CityBuildingEffect {
  final double multiplier;

  const FoodDepositMultiplierEffect(this.multiplier);
}
