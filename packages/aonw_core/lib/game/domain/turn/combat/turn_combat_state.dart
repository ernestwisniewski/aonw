import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';

/// Persistence-neutral input for the combat phase of a turn.
final class TurnCombatState {
  const TurnCombatState({
    required this.units,
    required this.cities,
    required this.artifacts,
    required this.intendedAttacks,
    required this.diplomacy,
    required this.resourceTradeAgreements,
  });

  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<WorldArtifact> artifacts;
  final List<IntendedAttack> intendedAttacks;
  final DiplomacyState diplomacy;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
}

/// Persistence-neutral output of the combat phase of a turn.
final class TurnCombatResolution {
  const TurnCombatResolution({required this.state, this.events = const []});

  final TurnCombatState state;
  final List<GameEvent> events;
}
