import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdowns.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_economy_forecast.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_stability_details.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_strategic_resource_summary.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_breakdown_popup.dart'
    show GoldBreakdown;
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';

class HudResourceSummary {
  final int gold;
  final int goldIncome;
  final int unitUpkeep;
  final int goldPerTurn;
  final int sciencePerTurn;
  final CityResourceInventory resourceInventory;
  final EmpireResourceNetwork resourceNetwork;
  final HudStrategicResourceSummary strategicResources;
  final HudResourceBreakdowns resourceBreakdowns;
  final int stabilityNet;
  final StabilityBand stabilityBand;
  final HudStabilityDetails stabilityDetails;

  HudResourceSummary({
    required this.gold,
    required this.goldIncome,
    required this.unitUpkeep,
    required this.goldPerTurn,
    required this.sciencePerTurn,
    required this.resourceInventory,
    required this.resourceNetwork,
    required this.strategicResources,
    required this.resourceBreakdowns,
    required this.stabilityNet,
    required this.stabilityBand,
    required this.stabilityDetails,
  });

  GoldBreakdown get goldBreakdown => resourceBreakdowns.gold;

  ScienceYieldBreakdown get scienceBreakdown => resourceBreakdowns.science;

  factory HudResourceSummary.fromGameState({
    required GameClientState? state,
    required String playerId,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
    HudResourceEconomyForecastCache? economyForecastCache,
  }) {
    if (state == null || playerId.isEmpty) {
      return HudResourceSummary.empty();
    }

    final stabilityNet = state.playerStabilityNet[playerId] ?? 0;
    final stabilityModifier = StabilityPolicy.modifierForNet(
      stabilityNet,
      ruleset: stabilityRuleset,
    );

    final economyForecast = HudResourceEconomyForecast.forPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
      cache: economyForecastCache,
    );

    final resources = _resourceProjections(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );

    return HudResourceSummary(
      gold: economyForecast.gold,
      goldIncome: economyForecast.goldIncome,
      unitUpkeep: economyForecast.unitUpkeep,
      goldPerTurn: economyForecast.goldPerTurn,
      sciencePerTurn: economyForecast.sciencePerTurn,
      resourceInventory: resources.network.visibleInventory,
      resourceNetwork: resources.network,
      strategicResources: resources.strategic,
      resourceBreakdowns: HudResourceBreakdowns(
        state: state,
        playerId: playerId,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        stabilityModifier: stabilityModifier,
      ),
      stabilityNet: stabilityNet,
      stabilityBand: StabilityPolicy.bandFor(
        stabilityNet,
        ruleset: stabilityRuleset,
      ),
      stabilityDetails: HudStabilityDetails(
        state: state,
        playerId: playerId,
        mapData: mapData,
        ruleset: stabilityRuleset,
      ),
    );
  }

  factory HudResourceSummary.empty() {
    return HudResourceSummary(
      gold: 0,
      goldIncome: 0,
      unitUpkeep: 0,
      goldPerTurn: 0,
      sciencePerTurn: 0,
      resourceInventory: CityResourceInventory.empty,
      resourceNetwork: EmpireResourceNetwork.empty,
      strategicResources: HudStrategicResourceSummary.empty,
      resourceBreakdowns: HudResourceBreakdowns.empty(),
      stabilityNet: 0,
      stabilityBand: StabilityBand.stable,
      stabilityDetails: HudStabilityDetails.empty(),
    );
  }
}

({EmpireResourceNetwork network, HudStrategicResourceSummary strategic})
_resourceProjections({
  required GameClientState state,
  required String playerId,
  required WorldMap mapData,
  required CityRuleset cityRuleset,
  required TechnologyRuleset technologyRuleset,
}) => (
  network: EmpireResourceNetworkRules.forPlayer(
    playerId: playerId,
    cities: state.cities,
    mapTiles: mapData,
    research: state.research,
    ruleset: cityRuleset,
    resourceTradeAgreements: state.resourceTradeAgreements,
  ),
  strategic: HudStrategicResourceSummary.fromGameState(
    state: state,
    playerId: playerId,
    mapData: mapData,
    cityRuleset: cityRuleset,
    technologyRuleset: technologyRuleset,
  ),
);
