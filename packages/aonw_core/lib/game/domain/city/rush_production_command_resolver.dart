import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/city_economy_breakdown.dart';
import 'package:aonw_core/game/domain/city/city_production_queue.dart';
import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_specialization.dart';
import 'package:aonw_core/game/domain/city/city_technology_effect_rules.dart';
import 'package:aonw_core/game/domain/city/city_unit_production_rules.dart';
import 'package:aonw_core/game/domain/city/city_yield_calculator.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/match_rules/pace_balance.dart';
import 'package:aonw_core/game/domain/stability/stability_policy.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/game/domain/wonder/wonder_completion_resolver.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

part 'rush_production_command_completion.dart';
part 'rush_production_command_economy.dart';

/// Persistence-neutral result of applying a production rush.
///
/// Rejections preserve the identity of every returned state slice. Changed
/// collections are owned by the result and cannot be mutated; unchanged
/// slices retain their input identity.
final class RushProductionCommandResult {
  const RushProductionCommandResult._accepted({
    required this.cities,
    required this.units,
    required this.playerGold,
    required this.research,
    required this.wonderRegistry,
    this.events = const [],
  }) : accepted = true,
       reason = null;

  const RushProductionCommandResult._rejected({
    required this.cities,
    required this.units,
    required this.playerGold,
    required this.research,
    required this.wonderRegistry,
    required this.reason,
  }) : accepted = false,
       events = const [];

  final bool accepted;
  final String? reason;
  final List<GameCity> cities;
  final List<GameUnit> units;
  final Map<String, int> playerGold;
  final ResearchState research;
  final WonderRegistry wonderRegistry;
  final List<GameEvent> events;
}

/// Applies the authoritative production-rush rules without a state container.
abstract final class RushProductionCommandResolver {
  static RushProductionCommandResult resolve({
    required List<GameCity> cities,
    required List<GameUnit> units,
    required List<WorldArtifact> artifacts,
    required List<FieldImprovement> fieldImprovements,
    required Map<String, int> playerGold,
    required Map<String, int> playerStabilityNet,
    required ResearchState research,
    required WonderRegistry wonderRegistry,
    required RushProductionCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityRuleset stabilityRuleset,
    required WonderRuleset wonderRuleset,
    required PaceBalance paceBalance,
  }) {
    return _RushProductionResolver(
      _RushProductionInput(
        cities: cities,
        units: units,
        artifacts: artifacts,
        fieldImprovements: fieldImprovements,
        playerGold: playerGold,
        playerStabilityNet: playerStabilityNet,
        research: research,
        wonderRegistry: wonderRegistry,
        command: command,
        actorPlayerId: actorPlayerId,
        mapTiles: mapTiles,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        stabilityRuleset: stabilityRuleset,
        wonderRuleset: wonderRuleset,
        paceBalance: paceBalance,
      ),
    ).resolve();
  }
}

final class _RushProductionResolver {
  const _RushProductionResolver(this.input);

  final _RushProductionInput input;

  RushProductionCommandResult resolve() {
    final validation = _validateTarget();
    final reason = validation.reason;
    if (reason != null) return _reject(reason);

    final target = validation.target!;
    final quote = _quoteFor(target);
    if (quote == null) return _reject('rush_production_unavailable');
    return _RushProductionCompletion(
      input: input,
      target: target,
      quote: quote,
    ).resolve();
  }

  _RushValidation _validateTarget() {
    final cityIndex = _cityIndexById(input.command.cityId);
    if (cityIndex == null) {
      return const (target: null, reason: 'city_not_found');
    }
    final city = input.cities[cityIndex];
    if (city.ownerPlayerId != input.actorPlayerId) {
      return const (target: null, reason: 'city_not_controlled');
    }
    final queue = city.productionQueue;
    if (queue == null) {
      return const (target: null, reason: 'production_queue_empty');
    }
    if (!CityProductionRules.canRush(queue.target)) {
      return const (target: null, reason: 'project_cannot_be_rushed');
    }
    return (
      target: _RushTarget(cityIndex: cityIndex, city: city, queue: queue),
      reason: null,
    );
  }

  _RushQuote? _quoteFor(_RushTarget target) {
    final targetCost = CityProductionRules.targetCost(
      target.queue.target,
      ruleset: input.cityRuleset,
      wonderRuleset: input.wonderRuleset,
      paceBalance: input.paceBalance,
    );
    final productionPerTurn = _RushProductionEconomy.productionPerTurn(
      input: input,
      city: target.city,
      target: target.queue.target,
    );
    final rushedProduction = CityProductionRules.rushProductionAmount(
      productionCost: targetCost,
      investedProduction: target.queue.investedProduction,
      productionPerTurn: productionPerTurn,
    );
    final rushCost = CityProductionRules.rushGoldCost(
      productionCost: targetCost,
      investedProduction: target.queue.investedProduction,
      productionPerTurn: productionPerTurn,
    );
    final currentGold = input.playerGold[target.city.ownerPlayerId] ?? 0;
    if (rushedProduction <= 0 || rushCost <= 0 || currentGold < rushCost) {
      return null;
    }
    return _RushQuote(
      targetCost: targetCost,
      rushedProduction: rushedProduction,
      rushCost: rushCost,
      currentGold: currentGold,
    );
  }

  int? _cityIndexById(String cityId) {
    for (var index = 0; index < input.cities.length; index++) {
      if (input.cities[index].id == cityId) return index;
    }
    return null;
  }

  RushProductionCommandResult _reject(String reason) {
    return RushProductionCommandResult._rejected(
      cities: input.cities,
      units: input.units,
      playerGold: input.playerGold,
      research: input.research,
      wonderRegistry: input.wonderRegistry,
      reason: reason,
    );
  }
}

final class _RushProductionInput {
  const _RushProductionInput({
    required this.cities,
    required this.units,
    required this.artifacts,
    required this.fieldImprovements,
    required this.playerGold,
    required this.playerStabilityNet,
    required this.research,
    required this.wonderRegistry,
    required this.command,
    required this.actorPlayerId,
    required this.mapTiles,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.stabilityRuleset,
    required this.wonderRuleset,
    required this.paceBalance,
  });

  final List<GameCity> cities;
  final List<GameUnit> units;
  final List<WorldArtifact> artifacts;
  final List<FieldImprovement> fieldImprovements;
  final Map<String, int> playerGold;
  final Map<String, int> playerStabilityNet;
  final ResearchState research;
  final WonderRegistry wonderRegistry;
  final RushProductionCommand command;
  final String actorPlayerId;
  final MapTileLookup mapTiles;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final StabilityRuleset stabilityRuleset;
  final WonderRuleset wonderRuleset;
  final PaceBalance paceBalance;
}

final class _RushTarget {
  const _RushTarget({
    required this.cityIndex,
    required this.city,
    required this.queue,
  });

  final int cityIndex;
  final GameCity city;
  final CityProductionQueue queue;
}

final class _RushQuote {
  const _RushQuote({
    required this.targetCost,
    required this.rushedProduction,
    required this.rushCost,
    required this.currentGold,
  });

  final int targetCost;
  final int rushedProduction;
  final int rushCost;
  final int currentGold;
}

typedef _RushValidation = ({_RushTarget? target, String? reason});
