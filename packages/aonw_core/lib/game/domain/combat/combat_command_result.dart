import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// State-container-neutral result of applying one combat command.
///
/// Rejections borrow every input slice. Accepted changed collections are
/// immutable and can be applied atomically by a boundary adapter.
final class CombatCommandResult {
  const CombatCommandResult.accepted({
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.fogOfWar,
    required this.intendedAttacks,
    required this.diplomacy,
    required this.resourceTradeAgreements,
    this.events = const [],
  }) : accepted = true,
       reason = null;

  const CombatCommandResult.rejected({
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.fogOfWar,
    required this.intendedAttacks,
    required this.diplomacy,
    required this.resourceTradeAgreements,
    required this.reason,
  }) : accepted = false,
       events = const [];

  final bool accepted;
  final String? reason;
  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<WorldArtifact> artifacts;
  final FogOfWarState fogOfWar;
  final List<IntendedAttack> intendedAttacks;
  final DiplomacyState diplomacy;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
  final List<GameEvent> events;
}
