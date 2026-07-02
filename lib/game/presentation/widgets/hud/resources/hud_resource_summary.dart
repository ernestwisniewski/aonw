import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_stability_details.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_breakdown_popup.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

class HudResourceSummary {
  final int gold;
  final int goldIncome;
  final int unitUpkeep;
  final int goldPerTurn;
  final int sciencePerTurn;
  final CityResourceInventory resourceInventory;
  final EmpireResourceNetwork resourceNetwork;
  final GoldBreakdown goldBreakdown;
  final ScienceYieldBreakdown scienceBreakdown;
  final int stabilityNet;
  final StabilityBand stabilityBand;
  final HudStabilityDetails stabilityDetails;

  const HudResourceSummary({
    required this.gold,
    required this.goldIncome,
    required this.unitUpkeep,
    required this.goldPerTurn,
    required this.sciencePerTurn,
    required this.resourceInventory,
    required this.resourceNetwork,
    required this.goldBreakdown,
    required this.scienceBreakdown,
    required this.stabilityNet,
    required this.stabilityBand,
    required this.stabilityDetails,
  });

  factory HudResourceSummary.fromGameState({
    required GameState? state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
  }) {
    if (state == null || playerId.isEmpty) {
      return HudResourceSummary.empty();
    }

    final stabilityNet = state.playerStabilityNet[playerId] ?? 0;
    final stabilityModifier = PersistentStabilityProcessor.modifierForNet(
      stabilityNet,
    );

    final goldBreakdown = _goldBreakdownForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
    );
    final scienceBreakdown = _scienceBreakdownForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
    );

    final resourceNetwork = EmpireResourceNetworkRules.forPlayer(
      playerId: playerId,
      cities: state.cities,
      mapData: mapData,
      research: state.research,
      ruleset: cityRuleset,
      resourceTradeAgreements: state.resourceTradeAgreements,
    );

    return HudResourceSummary(
      gold: goldBreakdown.treasury,
      goldIncome: goldBreakdown.grossIncome,
      unitUpkeep: goldBreakdown.unitUpkeep,
      goldPerTurn: goldBreakdown.netPerTurn,
      sciencePerTurn: scienceBreakdown.total,
      resourceInventory: resourceNetwork.visibleInventory,
      resourceNetwork: resourceNetwork,
      goldBreakdown: goldBreakdown,
      scienceBreakdown: scienceBreakdown,
      stabilityNet: stabilityNet,
      stabilityBand: StabilityPolicy.bandFor(stabilityNet),
      stabilityDetails: HudStabilityDetails(
        state: state,
        playerId: playerId,
        mapData: mapData,
      ),
    );
  }

  factory HudResourceSummary.empty() {
    const goldBreakdown = GoldBreakdown(
      treasury: 0,
      citySources: [],
      projectSources: [],
      upkeep: UnitUpkeepBreakdown(
        playerId: '',
        unitCount: 0,
        freeUnitCount: 0,
        paidUnitCount: 0,
        grossUpkeep: 0,
      ),
    );
    return HudResourceSummary(
      gold: 0,
      goldIncome: 0,
      unitUpkeep: 0,
      goldPerTurn: 0,
      sciencePerTurn: 0,
      resourceInventory: CityResourceInventory.empty,
      resourceNetwork: EmpireResourceNetwork.empty,
      goldBreakdown: goldBreakdown,
      scienceBreakdown: ScienceYieldBreakdown.empty,
      stabilityNet: 0,
      stabilityBand: StabilityBand.stable,
      stabilityDetails: HudStabilityDetails.empty(),
    );
  }
}

GoldBreakdown _goldBreakdownForPlayer({
  required GameState state,
  required String playerId,
  required MapData mapData,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
  required StabilityModifier stabilityModifier,
}) {
  final technologyEffects = TechnologyEffectSummary.forPlayer(
    playerId: playerId,
    research: state.research,
    ruleset: technologyRuleset,
  );
  final citySources = <GoldCitySource>[];
  final projectSources = <GoldProjectSource>[];

  for (final city in state.cities) {
    if (city.ownerPlayerId != playerId) continue;
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: cityRuleset,
    );
    final economy = CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: mapData,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
      stabilityModifier: stabilityModifier,
    );
    if (economy.netYield.gold > 0) {
      citySources.add(
        GoldCitySource(city: city, amount: economy.netYield.gold),
      );
    }

    final projectType = switch (city.productionQueue?.target) {
      ProjectProductionTarget(:final projectType) => projectType,
      _ => null,
    };
    if (projectType == CityProjectType.wealth) {
      final output = CityProjectRules.outputFor(
        type: CityProjectType.wealth,
        productionPerTurn: CityProductionRules.productionPerTurn(
          economy.netYield.production,
        ),
      );
      projectSources.add(GoldProjectSource(city: city, amount: output));
    }
  }

  return GoldBreakdown(
    treasury: state.playerGold[playerId] ?? 0,
    citySources: List.unmodifiable(citySources),
    projectSources: List.unmodifiable(projectSources),
    upkeep: UnitUpkeepRules.forPlayer(
      playerId: playerId,
      units: state.units,
      cities: state.cities,
    ),
  );
}

ScienceYieldBreakdown _scienceBreakdownForPlayer({
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
  final technologyEffects = TechnologyEffectSummary.forPlayer(
    playerId: playerId,
    research: state.research,
    ruleset: technologyRuleset,
  );
  final projectSources = <ScienceYieldSource>[];
  final projectByCityId = <String, int>{};
  var projectTotal = 0;

  for (final city in state.cities) {
    if (city.ownerPlayerId != playerId) continue;
    final projectType = switch (city.productionQueue?.target) {
      ProjectProductionTarget(:final projectType) => projectType,
      _ => null,
    };
    if (projectType != CityProjectType.research) continue;

    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: cityRuleset,
    );
    final economy = CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: mapData,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
      stabilityModifier: stabilityModifier,
    );
    final output = CityProjectRules.outputFor(
      type: CityProjectType.research,
      productionPerTurn: CityProductionRules.productionPerTurn(
        economy.netYield.production,
      ),
    );
    if (output <= 0) continue;
    projectTotal += output;
    projectByCityId[city.id] = (projectByCityId[city.id] ?? 0) + output;
    projectSources.add(
      ScienceYieldSource(
        cityId: city.id,
        amount: output,
        label: 'City research project',
      ),
    );
  }

  if (projectTotal <= 0) return base;

  final byCityId = <String, int>{...base.byCityId};
  for (final entry in projectByCityId.entries) {
    byCityId[entry.key] = (byCityId[entry.key] ?? 0) + entry.value;
  }
  return ScienceYieldBreakdown(
    total: base.total + projectTotal,
    byCityId: Map.unmodifiable(byCityId),
    sources: List.unmodifiable([...base.sources, ...projectSources]),
  );
}
