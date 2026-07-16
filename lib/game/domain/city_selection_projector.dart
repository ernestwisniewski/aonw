import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Projects the canonical city state into the local interaction selection.
abstract final class CitySelectionProjector {
  static GameSelection project({
    required GameState state,
    required GameCity city,
    required MapTileLookup mapTiles,
    required CityRuleset cityRuleset,
    required StabilityRuleset stabilityRuleset,
    required TechnologyRuleset technologyRuleset,
    required WonderRuleset wonderRuleset,
    required PaceBalance paceBalance,
  }) {
    final cityTileYieldBreakdown = CityYieldCalculator.breakdownFor(
      city,
      mapTiles,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: cityRuleset,
    );
    final cityYield = cityTileYieldBreakdown.total;
    final cityEconomy = CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapTiles: mapTiles,
      ruleset: cityRuleset,
      technologyEffects: TechnologyEffectSummary.forPlayer(
        playerId: city.ownerPlayerId,
        research: state.research,
        ruleset: technologyRuleset,
      ),
      cities: state.cities,
      wonderRegistry: state.wonderRegistry,
      wonderRuleset: wonderRuleset,
      stabilityModifier: StabilityPolicy.modifierForNet(
        state.playerStabilityNet[city.ownerPlayerId] ?? 0,
        ruleset: stabilityRuleset,
      ),
      paceBalance: paceBalance,
    );
    return GameSelection.city(
      city,
      cityYield: cityYield,
      cityTileYieldBreakdown: cityTileYieldBreakdown,
      cityEconomy: cityEconomy,
      playerColor:
          state.colorForPlayer(city.ownerPlayerId) ?? Player.palette.first,
    );
  }
}
