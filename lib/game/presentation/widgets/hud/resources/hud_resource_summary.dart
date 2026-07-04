import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_breakdowns.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_resource_economy_forecast.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_stability_details.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_breakdown_popup.dart'
    show GoldBreakdown;
import 'package:aonw/map/domain/map_data.dart';
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
    required this.resourceBreakdowns,
    required this.stabilityNet,
    required this.stabilityBand,
    required this.stabilityDetails,
  });

  GoldBreakdown get goldBreakdown => resourceBreakdowns.gold;

  ScienceYieldBreakdown get scienceBreakdown => resourceBreakdowns.science;

  factory HudResourceSummary.fromGameState({
    required GameState? state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    StabilityRuleset stabilityRuleset = StabilityRuleset.standard,
  }) {
    if (state == null || playerId.isEmpty) {
      return HudResourceSummary.empty();
    }

    final stabilityNet = state.playerStabilityNet[playerId] ?? 0;
    final stabilityModifier = PersistentStabilityProcessor.modifierForNet(
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
      gold: economyForecast.gold,
      goldIncome: economyForecast.goldIncome,
      unitUpkeep: economyForecast.unitUpkeep,
      goldPerTurn: economyForecast.goldPerTurn,
      sciencePerTurn: economyForecast.sciencePerTurn,
      resourceInventory: resourceNetwork.visibleInventory,
      resourceNetwork: resourceNetwork,
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
      resourceBreakdowns: HudResourceBreakdowns.empty(),
      stabilityNet: 0,
      stabilityBand: StabilityBand.stable,
      stabilityDetails: HudStabilityDetails.empty(),
    );
  }
}
