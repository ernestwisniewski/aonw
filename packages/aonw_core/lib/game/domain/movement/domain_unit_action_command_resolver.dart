import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement/unit_action_command_resolver.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';

final class DomainUnitActionCommandResult {
  const DomainUnitActionCommandResult({
    required this.accepted,
    required this.state,
    required this.interaction,
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final DomainActionState interaction;
  final String? reason;
}

/// Canonical-state adapter for the persistence-neutral unit action resolver.
final class DomainUnitActionCommandResolver {
  const DomainUnitActionCommandResolver();

  DomainUnitActionCommandResult cancelUnitAction({
    required DomainState state,
    required DomainActionState interaction,
    required CancelUnitActionCommand command,
    required String actorPlayerId,
  }) {
    return _apply(
      state,
      interaction,
      UnitActionCommandResolver.cancelUnitAction(
        units: state.units,
        artifacts: state.artifacts,
        interaction: interaction,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  DomainUnitActionCommandResult skipUnitTurn({
    required DomainState state,
    required DomainActionState interaction,
    required SkipUnitTurnCommand command,
    required String actorPlayerId,
  }) {
    return _apply(
      state,
      interaction,
      UnitActionCommandResolver.skipUnitTurn(
        units: state.units,
        artifacts: state.artifacts,
        interaction: interaction,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  DomainUnitActionCommandResult fortifyUnit({
    required DomainState state,
    required DomainActionState interaction,
    required FortifyUnitCommand command,
    required String actorPlayerId,
  }) {
    return _apply(
      state,
      interaction,
      UnitActionCommandResolver.fortifyUnit(
        units: state.units,
        artifacts: state.artifacts,
        interaction: interaction,
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  static DomainUnitActionCommandResult _apply(
    DomainState state,
    DomainActionState interaction,
    UnitActionCommandResult result,
  ) {
    if (!result.accepted) {
      return DomainUnitActionCommandResult(
        accepted: false,
        state: state,
        interaction: interaction,
        reason: result.reason,
      );
    }
    final unitsChanged = !identical(result.units, state.units);
    final artifactsChanged = !identical(result.artifacts, state.artifacts);
    return DomainUnitActionCommandResult(
      accepted: true,
      state: unitsChanged || artifactsChanged
          ? state.copyWith(
              units: unitsChanged ? result.units : null,
              artifacts: artifactsChanged ? result.artifacts : null,
            )
          : state,
      interaction: result.interaction,
    );
  }
}
