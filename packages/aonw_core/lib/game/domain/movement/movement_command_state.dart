import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/transport/transport_network_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// Borrowed state slices required by authoritative unit-movement rules.
///
/// This view does not own or copy its inputs. State-boundary adapters remain
/// responsible for applying changed slices returned by [MovementCommandResult].
final class MovementCommandState {
  const MovementCommandState({
    required this.units,
    required this.cities,
    required this.fogOfWar,
    required this.diplomacy,
    required this.playerIds,
    this.transportNetwork = TransportNetworkState.empty,
  });

  final List<GameUnit> units;
  final List<GameCity> cities;
  final FogOfWarState fogOfWar;
  final DiplomacyState diplomacy;
  final Iterable<String> playerIds;
  final TransportNetworkState transportNetwork;
}
