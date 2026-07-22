import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// Borrowed state slices required by diplomacy command rules.
///
/// This view never owns or copies its inputs. Adapters remain responsible for
/// applying returned slices to their state container.
final class DiplomacyCommandState {
  const DiplomacyCommandState({
    required this.playerColors,
    required this.playerCountries,
    required this.playerGold,
    required this.units,
    required this.cities,
    required this.fogOfWar,
    required this.diplomacy,
    required this.intendedAttacks,
    required this.resourceTradeAgreements,
  });

  final Map<String, int> playerColors;
  final Map<String, PlayerCountry> playerCountries;
  final Map<String, int> playerGold;
  final List<GameUnit> units;
  final List<GameCity> cities;
  final FogOfWarState fogOfWar;
  final DiplomacyState diplomacy;
  final List<IntendedAttack> intendedAttacks;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
}
