import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_resolver.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_result.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_command_state.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';

final class DomainDiplomacyCommandResult {
  const DomainDiplomacyCommandResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final List<GameEvent> events;
  final String? reason;
}

/// Canonical-state adapter for the persistence-neutral diplomacy resolver.
final class DomainDiplomacyCommandResolver {
  const DomainDiplomacyCommandResolver();

  DomainDiplomacyCommandResult resolve({
    required DomainState state,
    required DiplomaticCommand command,
    required String actorPlayerId,
    required int turn,
    bool canAct = true,
  }) {
    return _apply(
      state,
      DiplomacyCommandResolver.resolve(
        state: _commandState(state),
        command: command,
        actorPlayerId: actorPlayerId,
        turn: turn,
        canAct: canAct,
      ),
    );
  }

  static DiplomacyCommandState _commandState(DomainState state) {
    return DiplomacyCommandState(
      playerColors: state.playerColors,
      playerCountries: state.playerCountries,
      playerGold: state.playerGold,
      units: state.units,
      cities: state.cities,
      fogOfWar: state.fogOfWar,
      diplomacy: state.diplomacy,
      intendedAttacks: state.intendedAttacks,
      resourceTradeAgreements: state.resourceTradeAgreements,
    );
  }

  static DomainDiplomacyCommandResult _apply(
    DomainState state,
    DiplomacyCommandResult result,
  ) {
    if (!result.accepted) {
      return DomainDiplomacyCommandResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return DomainDiplomacyCommandResult(
      accepted: true,
      state: _applyAccepted(state, result),
      events: result.events,
    );
  }

  static DomainState _applyAccepted(
    DomainState state,
    DiplomacyCommandResult result,
  ) {
    final goldChanged = !identical(result.playerGold, state.playerGold);
    final diplomacyChanged = !identical(result.diplomacy, state.diplomacy);
    final attacksChanged = !identical(
      result.intendedAttacks,
      state.intendedAttacks,
    );
    final tradesChanged = !identical(
      result.resourceTradeAgreements,
      state.resourceTradeAgreements,
    );
    if (!goldChanged &&
        !diplomacyChanged &&
        !attacksChanged &&
        !tradesChanged) {
      return state;
    }
    return state.copyWith(
      playerGold: goldChanged ? result.playerGold : null,
      diplomacy: diplomacyChanged ? result.diplomacy : null,
      intendedAttacks: attacksChanged ? result.intendedAttacks : null,
      resourceTradeAgreements: tradesChanged
          ? result.resourceTradeAgreements
          : null,
    );
  }
}
