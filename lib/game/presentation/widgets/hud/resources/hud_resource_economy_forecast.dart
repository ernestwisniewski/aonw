import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_gold_breakdown_calculator.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_science_breakdown_calculator.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';

final class HudResourceEconomyForecast {
  const HudResourceEconomyForecast({
    required this.gold,
    required this.goldIncome,
    required this.unitUpkeep,
    required this.goldPerTurn,
    required this.sciencePerTurn,
  });

  final int gold;
  final int goldIncome;
  final int unitUpkeep;
  final int goldPerTurn;
  final int sciencePerTurn;

  factory HudResourceEconomyForecast.forPlayer({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
  }) {
    final goldForecast = HudGoldResourceCalculator.forecastForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
    );
    return HudResourceEconomyForecast(
      gold: goldForecast.treasury,
      goldIncome: goldForecast.grossIncome,
      unitUpkeep: goldForecast.unitUpkeep,
      goldPerTurn: goldForecast.netPerTurn,
      sciencePerTurn: HudScienceResourceCalculator.totalForPlayer(
        state: state,
        playerId: playerId,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        stabilityModifier: stabilityModifier,
      ),
    );
  }
}
