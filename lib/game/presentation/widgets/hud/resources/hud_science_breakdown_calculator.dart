import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_city_economy_calculator.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';

abstract final class HudScienceResourceCalculator {
  static int totalForPlayer({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
  }) {
    final baseTotal = ScienceYieldCalculator.totalAmountForPlayer(
      playerId: playerId,
      cities: state.cities,
      research: state.research,
      ruleset: technologyRuleset,
      artifacts: state.artifacts,
      cityRuleset: cityRuleset,
    );
    return baseTotal +
        _projectForecastForPlayer(
          state: state,
          playerId: playerId,
          mapData: mapData,
          cityRuleset: cityRuleset,
          technologyRuleset: technologyRuleset,
          stabilityModifier: stabilityModifier,
          collectSources: false,
        ).total;
  }

  static ScienceYieldBreakdown breakdownForPlayer({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
  }) {
    final base = ScienceYieldCalculator.totalForPlayer(
      playerId: playerId,
      cities: state.cities,
      research: state.research,
      ruleset: technologyRuleset,
      artifacts: state.artifacts,
      cityRuleset: cityRuleset,
    );
    final projectForecast = _projectForecastForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
      collectSources: true,
    );

    if (projectForecast.total <= 0) return base;

    final byCityId = <String, int>{...base.byCityId};
    for (final entry in projectForecast.byCityId.entries) {
      byCityId[entry.key] = (byCityId[entry.key] ?? 0) + entry.value;
    }
    return ScienceYieldBreakdown(
      total: base.total + projectForecast.total,
      byCityId: Map.unmodifiable(byCityId),
      sources: List.unmodifiable([...base.sources, ...projectForecast.sources]),
    );
  }

  static _ScienceProjectForecast _projectForecastForPlayer({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
    required bool collectSources,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: state.research,
      ruleset: technologyRuleset,
    );
    final sources = <ScienceYieldSource>[];
    final byCityId = <String, int>{};
    var total = 0;

    for (final city in state.cities) {
      if (city.ownerPlayerId != playerId) continue;
      if (city.productionQueue?.hasProjectOutput != true) continue;
      final economy = HudCityEconomyCalculator.forCity(
        city: city,
        state: state,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyEffects: technologyEffects,
        stabilityModifier: stabilityModifier,
      );
      final projectOutput = city.productionQueue?.projectOutput(
        productionPerTurn: CityProductionRules.productionPerTurn(
          economy.netYield.production,
        ),
      );
      final projectScience = projectOutput?.science ?? 0;
      if (projectScience <= 0) continue;
      total += projectScience;
      if (collectSources) {
        byCityId[city.id] = (byCityId[city.id] ?? 0) + projectScience;
        sources.add(
          ScienceYieldSource(
            cityId: city.id,
            amount: projectScience,
            label: ScienceYieldSourceLabels.cityResearchProject,
          ),
        );
      }
    }

    return _ScienceProjectForecast(
      total: total,
      byCityId: collectSources ? Map.unmodifiable(byCityId) : const {},
      sources: collectSources ? List.unmodifiable(sources) : const [],
    );
  }
}

final class _ScienceProjectForecast {
  const _ScienceProjectForecast({
    required this.total,
    required this.byCityId,
    required this.sources,
  });

  final int total;
  final Map<String, int> byCityId;
  final List<ScienceYieldSource> sources;
}
