import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/game/domain/wonder/wonder_effect.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/game/domain/wonder/wonder_type.dart';

class WonderCompletionResult {
  const WonderCompletionResult({
    required this.cities,
    required this.registry,
    required this.playerGold,
    required this.research,
    this.events = const [],
  });

  final List<GameCity> cities;
  final WonderRegistry registry;
  final Map<String, int> playerGold;
  final ResearchState research;
  final List<GameEvent> events;
}

abstract final class WonderCompletionResolver {
  static WonderCompletionResult resolveCompletedForPlayer({
    required String playerId,
    required List<GameCity> cities,
    required WonderRegistry registry,
    required Map<String, int> playerGold,
    required ResearchState research,
    WonderRuleset ruleset = WonderRuleset.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    var currentCities = List<GameCity>.of(cities);
    var currentRegistry = registry;
    var currentGold = Map<String, int>.from(playerGold);
    var currentResearch = research;
    final events = <GameEvent>[];

    for (var i = 0; i < currentCities.length; i++) {
      final city = currentCities[i];
      if (city.ownerPlayerId != playerId) continue;
      final queue = city.productionQueue;
      final wonderType = switch (queue?.target) {
        WonderProductionTarget(:final wonderType) => wonderType,
        _ => null,
      };
      if (queue == null || wonderType == null) continue;

      final productionCost = paceBalance.buildingProductionCost(
        ruleset.definitionFor(wonderType).productionCost,
      );
      if (queue.investedProduction < productionCost) continue;

      if (currentRegistry.isCompleted(wonderType)) {
        final refunded = _refundCity(city, events: events);
        currentCities[i] = refunded;
        continue;
      }

      final claim = _claimWonder(
        cities: currentCities,
        hostCityIndex: i,
        wonderType: wonderType,
        productionCost: productionCost,
        registry: currentRegistry,
        playerGold: currentGold,
        research: currentResearch,
        ruleset: ruleset,
      );
      currentCities = claim.cities;
      currentRegistry = claim.registry;
      currentGold = claim.playerGold;
      currentResearch = claim.research;
      events.addAll(claim.events);
    }

    return WonderCompletionResult(
      cities: List.unmodifiable(currentCities),
      registry: currentRegistry,
      playerGold: Map.unmodifiable(currentGold),
      research: currentResearch,
      events: List.unmodifiable(events),
    );
  }

  static WonderCompletionResult _claimWonder({
    required List<GameCity> cities,
    required int hostCityIndex,
    required WonderType wonderType,
    required int productionCost,
    required WonderRegistry registry,
    required Map<String, int> playerGold,
    required ResearchState research,
    required WonderRuleset ruleset,
  }) {
    final hostCity = cities[hostCityIndex];
    final ownerPlayerId = hostCity.ownerPlayerId;
    final events = <GameEvent>[
      CityBuiltWonderEvent(
        cityId: hostCity.id,
        ownerPlayerId: ownerPlayerId,
        wonderType: wonderType,
      ),
    ];
    final nextCities = List<GameCity>.of(cities);
    final nextGold = Map<String, int>.from(playerGold);
    var nextResearch = research;
    var productionBurst = 0;

    for (final effect in ruleset.definitionFor(wonderType).completionEffects) {
      switch (effect) {
        case GrantFreeTechnology():
          final applied = _grantActiveTechnology(
            playerId: ownerPlayerId,
            research: nextResearch,
          );
          nextResearch = applied.research;
          if (applied.technologyId != null) {
            events.add(
              TechnologyResearchedEvent(
                playerId: ownerPlayerId,
                technologyId: applied.technologyId!,
              ),
            );
          }
        case ProductionBurst(:final amount):
          productionBurst += amount;
        case GrantGold(:final amount):
          if (amount > 0) {
            nextGold[ownerPlayerId] = (nextGold[ownerPlayerId] ?? 0) + amount;
          }
      }
    }

    for (var i = 0; i < nextCities.length; i++) {
      final city = nextCities[i];
      final queue = city.productionQueue;
      if (queue?.target != WonderProductionTarget(wonderType)) continue;

      if (i == hostCityIndex) {
        final overflow = _completionOverflow(
          productionCost: productionCost,
          investedProduction: queue!.investedProduction,
        );
        nextCities[i] = city.copyWith(
          wonders: {...city.wonders, wonderType},
          productionQueue: null,
          productionOverflow: overflow + productionBurst,
        );
      } else {
        nextCities[i] = _refundCity(city, events: events);
      }
    }

    return WonderCompletionResult(
      cities: List.unmodifiable(nextCities),
      registry: registry.complete(type: wonderType, playerId: ownerPlayerId),
      playerGold: Map.unmodifiable(nextGold),
      research: nextResearch,
      events: List.unmodifiable(events),
    );
  }

  static GameCity _refundCity(
    GameCity city, {
    required List<GameEvent> events,
  }) {
    final queue = city.productionQueue;
    final wonderType = switch (queue?.target) {
      WonderProductionTarget(:final wonderType) => wonderType,
      _ => null,
    };
    if (queue == null || wonderType == null) return city;
    events.add(
      WonderProductionRefundedEvent(
        cityId: city.id,
        ownerPlayerId: city.ownerPlayerId,
        wonderType: wonderType,
        refundedProduction: queue.investedProduction,
      ),
    );
    return city.copyWith(
      productionQueue: null,
      productionOverflow: city.productionOverflow + queue.investedProduction,
    );
  }

  static ({ResearchState research, TechnologyId? technologyId})
  _grantActiveTechnology({
    required String playerId,
    required ResearchState research,
  }) {
    final playerResearch = research.forPlayer(playerId);
    final technologyId = playerResearch.activeTechnologyId;
    if (technologyId == null || playerResearch.hasUnlocked(technologyId)) {
      return (research: research, technologyId: null);
    }
    return (
      research: research.updatePlayer(
        playerId,
        playerResearch.unlock(technologyId),
      ),
      technologyId: technologyId,
    );
  }

  static int _completionOverflow({
    required int productionCost,
    required int investedProduction,
  }) {
    final overflow = investedProduction - productionCost;
    return overflow <= 0 ? 0 : overflow;
  }
}
