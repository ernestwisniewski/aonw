import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/game/domain/wonder/wonder_effect.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/game/domain/wonder/wonder_type.dart';

abstract final class WonderEffectResolver {
  static TileYield yieldForCity({
    required GameCity city,
    required Iterable<GameCity> cities,
    required WonderRegistry registry,
    WonderRuleset ruleset = WonderRuleset.standard,
  }) {
    var total = TileYield.zero;
    for (final entry in _activeWonders(
      cities: cities,
      registry: registry,
      ruleset: ruleset,
    )) {
      final hostCity = entry.hostCity;
      final effects = entry.effects;
      if (hostCity.ownerPlayerId != city.ownerPlayerId) continue;
      for (final effect in effects) {
        total = switch (effect) {
          EmpireFlatYieldEffect(:final yieldPerCity) => total + yieldPerCity,
          HostCityFlatYieldEffect(:final yield) when hostCity.id == city.id =>
            total + yield,
          HostCityFlatYieldEffect() => total,
          EmpireScienceEffect() ||
          EmpireGoldMultiplierEffect() ||
          EmpireProductionMultiplierEffect() ||
          StabilityEffect() => total,
        };
      }
    }
    return total;
  }

  static int scienceForCity({
    required GameCity city,
    required Iterable<GameCity> cities,
    required WonderRegistry registry,
    WonderRuleset ruleset = WonderRuleset.standard,
  }) {
    var total = 0;
    for (final entry in _activeWonders(
      cities: cities,
      registry: registry,
      ruleset: ruleset,
    )) {
      final hostCity = entry.hostCity;
      final effects = entry.effects;
      if (hostCity.ownerPlayerId != city.ownerPlayerId) continue;
      for (final effect in effects) {
        if (effect case EmpireScienceEffect(:final perCity)) {
          total += perCity;
        }
      }
    }
    return total;
  }

  static double goldMultiplierForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required WonderRegistry registry,
    WonderRuleset ruleset = WonderRuleset.standard,
  }) {
    var multiplier = 0.0;
    for (final entry in _activeWonders(
      cities: cities,
      registry: registry,
      ruleset: ruleset,
    )) {
      final hostCity = entry.hostCity;
      final effects = entry.effects;
      if (hostCity.ownerPlayerId != playerId) continue;
      for (final effect in effects) {
        if (effect case EmpireGoldMultiplierEffect(multiplier: final m)) {
          multiplier += m;
        }
      }
    }
    return multiplier;
  }

  static double productionMultiplierForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required WonderRegistry registry,
    WonderRuleset ruleset = WonderRuleset.standard,
  }) {
    var multiplier = 0.0;
    for (final entry in _activeWonders(
      cities: cities,
      registry: registry,
      ruleset: ruleset,
    )) {
      final hostCity = entry.hostCity;
      final effects = entry.effects;
      if (hostCity.ownerPlayerId != playerId) continue;
      for (final effect in effects) {
        if (effect case EmpireProductionMultiplierEffect(multiplier: final m)) {
          multiplier += m;
        }
      }
    }
    return multiplier;
  }

  static int stabilityForPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required WonderRegistry registry,
    WonderRuleset ruleset = WonderRuleset.standard,
  }) {
    var total = 0;
    for (final entry in _activeWonders(
      cities: cities,
      registry: registry,
      ruleset: ruleset,
    )) {
      final hostCity = entry.hostCity;
      final effects = entry.effects;
      if (hostCity.ownerPlayerId != playerId) continue;
      for (final effect in effects) {
        if (effect case StabilityEffect(:final delta)) {
          total += delta;
        }
      }
    }
    return total;
  }

  static Iterable<
    ({
      GameCity hostCity,
      WonderType wonderType,
      List<WonderStandingEffect> effects,
    })
  >
  _activeWonders({
    required Iterable<GameCity> cities,
    required WonderRegistry registry,
    required WonderRuleset ruleset,
  }) sync* {
    for (final hostCity in cities) {
      for (final wonderType in hostCity.wonders) {
        if (!registry.isCompleted(wonderType)) continue;
        yield (
          hostCity: hostCity,
          wonderType: wonderType,
          effects: ruleset.definitionFor(wonderType).standingEffects,
        );
      }
    }
  }
}
