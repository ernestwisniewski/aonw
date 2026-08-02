import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_gold_breakdown_calculator.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_science_breakdown_calculator.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_breakdown_popup.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/foundation.dart';

final class HudResourceBreakdowns {
  HudResourceBreakdowns({
    required GameClientState state,
    required String playerId,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
  }) : _state = state,
       _playerId = playerId,
       _mapData = mapData,
       _cityRuleset = cityRuleset,
       _technologyRuleset = technologyRuleset,
       _stabilityModifier = stabilityModifier;

  HudResourceBreakdowns.empty()
    : _state = null,
      _playerId = '',
      _mapData = null,
      _cityRuleset = CityRulesets.standard,
      _technologyRuleset = TechnologyRulesets.standard,
      _stabilityModifier = StabilityModifier.stable,
      _gold = GoldBreakdown.empty,
      _science = ScienceYieldBreakdown.empty;

  HudResourceBreakdowns.fixed({
    required GoldBreakdown gold,
    required ScienceYieldBreakdown science,
  }) : _state = null,
       _playerId = '',
       _mapData = null,
       _cityRuleset = CityRulesets.standard,
       _technologyRuleset = TechnologyRulesets.standard,
       _stabilityModifier = StabilityModifier.stable,
       _gold = gold,
       _science = science;

  final GameClientState? _state;
  final String _playerId;
  final WorldMap? _mapData;
  final CityRuleset _cityRuleset;
  final TechnologyRuleset _technologyRuleset;
  final StabilityModifier _stabilityModifier;

  GoldBreakdown? _gold;
  ScienceYieldBreakdown? _science;

  GoldBreakdown get gold {
    return _gold ??= _computeGold();
  }

  ScienceYieldBreakdown get science {
    return _science ??= _computeScience();
  }

  @visibleForTesting
  bool get debugHasComputedGold => _gold != null;

  @visibleForTesting
  bool get debugHasComputedScience => _science != null;

  GoldBreakdown _computeGold() {
    final state = _state;
    final mapData = _mapData;
    if (state == null || mapData == null || _playerId.isEmpty) {
      return GoldBreakdown.empty;
    }
    return HudGoldResourceCalculator.breakdownForPlayer(
      state: state,
      playerId: _playerId,
      mapData: mapData,
      cityRuleset: _cityRuleset,
      technologyRuleset: _technologyRuleset,
      stabilityModifier: _stabilityModifier,
    );
  }

  ScienceYieldBreakdown _computeScience() {
    final state = _state;
    final mapData = _mapData;
    if (state == null || mapData == null || _playerId.isEmpty) {
      return ScienceYieldBreakdown.empty;
    }
    return HudScienceResourceCalculator.breakdownForPlayer(
      state: state,
      playerId: _playerId,
      mapData: mapData,
      cityRuleset: _cityRuleset,
      technologyRuleset: _technologyRuleset,
      stabilityModifier: _stabilityModifier,
    );
  }
}
