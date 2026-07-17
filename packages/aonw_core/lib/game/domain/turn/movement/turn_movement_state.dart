import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// Persistence-neutral state used by the movement phase of a turn.
final class TurnMovementState {
  const TurnMovementState({
    required this.units,
    required this.cities,
    required this.fogOfWar,
  });

  final List<GameUnit> units;
  final List<GameCity> cities;
  final FogOfWarState fogOfWar;
}

/// Persistence-neutral output of the movement phase of a turn.
final class TurnMovementResult {
  const TurnMovementResult({required this.state, this.changed = false});

  final TurnMovementState state;
  final bool changed;
}
