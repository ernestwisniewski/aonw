import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// Borrowed state slices required by authoritative combat-command rules.
///
/// State-boundary adapters remain responsible for applying changed slices
/// returned by [CombatCommandResult].
final class CombatCommandState {
  const CombatCommandState({
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.fogOfWar,
    required this.research,
    required this.intendedAttacks,
    required this.diplomacy,
    required this.resourceTradeAgreements,
    required this.playerIds,
  });

  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<WorldArtifact> artifacts;
  final FogOfWarState fogOfWar;
  final ResearchState research;
  final List<IntendedAttack> intendedAttacks;
  final DiplomacyState diplomacy;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
  final Iterable<String> playerIds;
}
