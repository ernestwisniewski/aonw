import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';

sealed class WonderStandingEffect {
  const WonderStandingEffect();
}

final class EmpireFlatYieldEffect extends WonderStandingEffect {
  const EmpireFlatYieldEffect(this.yieldPerCity);

  final TileYield yieldPerCity;
}

final class HostCityFlatYieldEffect extends WonderStandingEffect {
  const HostCityFlatYieldEffect(this.yield);

  final TileYield yield;
}

final class EmpireScienceEffect extends WonderStandingEffect {
  const EmpireScienceEffect(this.perCity);

  final int perCity;
}

final class EmpireGoldMultiplierEffect extends WonderStandingEffect {
  const EmpireGoldMultiplierEffect(this.multiplier);

  final double multiplier;
}

final class EmpireProductionMultiplierEffect extends WonderStandingEffect {
  const EmpireProductionMultiplierEffect(this.multiplier);

  final double multiplier;
}

final class StabilityEffect extends WonderStandingEffect {
  const StabilityEffect(this.delta);

  final int delta;
}

sealed class WonderCompletionEffect {
  const WonderCompletionEffect();
}

final class GrantFreeTechnology extends WonderCompletionEffect {
  const GrantFreeTechnology();
}

final class ProductionBurst extends WonderCompletionEffect {
  const ProductionBurst(this.amount);

  final int amount;
}

final class GrantGold extends WonderCompletionEffect {
  const GrantGold(this.amount);

  final int amount;
}
