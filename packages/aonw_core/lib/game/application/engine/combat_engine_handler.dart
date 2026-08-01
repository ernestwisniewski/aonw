import 'package:aonw_core/game/application/engine/combat_animation_fact.dart';
import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/domain/combat/domain_combat_command_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';

/// Applies authoritative combat commands to a canonical snapshot.
final class CombatEngineHandler {
  const CombatEngineHandler({
    this.resolver = const DomainCombatCommandResolver(),
  });

  final DomainCombatCommandResolver resolver;

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    if (command is! AttackHexCommand) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'unsupported_domain_command',
      );
    }
    final result = resolver.resolve(
      state: snapshot.domain,
      command: command,
      actorPlayerId: context.actorPlayerId,
      commandTick: context.commandTick,
      mapTiles: context.mapView,
      ruleset: context.ruleset,
      ignoreFogOfWar: context.combatVisibilityMode.ignoresFogOfWar,
    );
    if (!result.accepted) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: result.reason ?? 'command_rejected',
      );
    }
    final domainChanged = !identical(result.state, snapshot.domain);
    final interaction = _interactionAfterAcceptedCombat(snapshot, command);
    final interactionChanged = !identical(interaction, snapshot.domain.actions);
    final events = [for (final event in result.events) event as DomainEvent];
    return GameEngineResult.accepted(
      snapshot: domainChanged || interactionChanged
          ? snapshot.copyWith(
              domain: domainChanged ? result.state : null,
              actions: interactionChanged ? interaction : null,
            )
          : snapshot,
      events: events,
      combatAnimations: _animationFacts(
        snapshot: snapshot,
        command: command,
        events: events,
      ),
    );
  }

  static DomainActionState _interactionAfterAcceptedCombat(
    CanonicalGameSnapshot snapshot,
    AttackHexCommand command,
  ) {
    final pending = snapshot.domain.actions.pendingAction;
    final clearPending =
        pending is PendingAttackTargeting &&
        pending.attackerUnitId == command.attackerUnitId;
    if (!clearPending && snapshot.domain.actions.cityFoundingDraft == null) {
      return snapshot.domain.actions;
    }
    return snapshot.domain.actions.copyWith(
      cityFoundingDraft: null,
      pendingAction: clearPending ? null : pending,
    );
  }

  static List<CombatAnimationFact> _animationFacts({
    required CanonicalGameSnapshot snapshot,
    required AttackHexCommand command,
    required List<DomainEvent> events,
  }) {
    final attacker = snapshot.domain.units.byId(command.attackerUnitId);
    if (attacker == null) return const [];
    return [
      for (var index = 0; index < events.length; index++)
        if (events[index] case final CombatResolvedEvent event)
          CombatAnimationFact(
            eventIndex: index,
            attackerUnitId: event.attackerUnitId,
            defenderId: event.defenderUnitId,
            attackerFromCol: attacker.col,
            attackerFromRow: attacker.row,
            attackerToCol: command.defenderCol,
            attackerToRow: command.defenderRow,
          ),
    ];
  }
}
