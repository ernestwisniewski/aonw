import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/stability.dart';

final class HudStabilityDetails {
  HudStabilityDetails({
    required GameState state,
    required String playerId,
    required MapData mapData,
    StabilityRuleset ruleset = StabilityRuleset.standard,
  }) : _state = state,
       _playerId = playerId,
       _mapData = mapData,
       _ruleset = ruleset;

  HudStabilityDetails.empty()
    : _state = null,
      _playerId = '',
      _mapData = null,
      _ruleset = StabilityRuleset.standard;

  HudStabilityDetails.fixed({
    required StabilityBreakdown breakdown,
    required int standingAdjustment,
  }) : _state = null,
       _playerId = '',
       _mapData = null,
       _ruleset = StabilityRuleset.standard,
       _computed = (
         breakdown: breakdown,
         standingAdjustment: standingAdjustment,
       );

  final GameState? _state;
  final String _playerId;
  final MapData? _mapData;
  final StabilityRuleset _ruleset;

  ({StabilityBreakdown breakdown, int standingAdjustment})? _computed;

  StabilityBreakdown get breakdown => _details.breakdown;

  int get standingAdjustment => _details.standingAdjustment;

  ({StabilityBreakdown breakdown, int standingAdjustment}) get _details =>
      _computed ??= _compute();

  ({StabilityBreakdown breakdown, int standingAdjustment}) _compute() {
    final state = _state;
    final mapData = _mapData;
    if (state == null || mapData == null || _playerId.isEmpty) {
      return _emptyDetails;
    }
    final inputs = StabilityInputBuilder.forPlayers(
      state: state.toPersistentState(),
      playerIds: [_playerId],
      mapData: mapData,
      ruleset: _ruleset,
    )[_playerId];
    if (inputs == null) return _emptyDetails;
    final breakdown = StabilityCalculator.calculate(
      inputs: inputs,
      ruleset: _ruleset,
    );
    final effectiveNet = StabilityPolicy.effectiveNet(
      breakdown.net,
      relativeStanding: StabilityPolicy.relativeStandingFor(
        controlPercent: inputs.controlPercent,
        playerCount: inputs.playerCount,
      ),
      ruleset: _ruleset,
    );
    return (
      breakdown: breakdown,
      standingAdjustment: effectiveNet - breakdown.net,
    );
  }
}

const _emptyDetails = (
  breakdown: StabilityBreakdown(
    playerId: '',
    baseOrder: 0,
    buildingSources: 0,
    luxurySources: 0,
    techSources: 0,
    artifactSources: 0,
    cityCost: 0,
    populationCost: 0,
    cohesionCost: 0,
    conqueredCityCost: 0,
    warWearinessCost: 0,
    hegemonyTax: 0,
  ),
  standingAdjustment: 0,
);
