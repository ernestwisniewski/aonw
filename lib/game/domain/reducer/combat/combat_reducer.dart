import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

part 'combat_reducer_targeting.dart';

typedef _AttackSetup = ({GameUnit attacker, GameUnit defender});

typedef _CityAttackSetup = ({GameUnit attacker, GameCity city});

/// Client-only attack targeting policy.
///
/// Authoritative combat application is owned by `GameEngine`.
abstract final class CombatReducer {
  static GameStateTransition selectAttackTargetWithEnvironment(
    GameClientState state,
    AttackHexCommand command,
    ReducerEnvironment environment,
  ) {
    return selectAttackTarget(
      state,
      command,
      environment.mapData,
      combatRuleset: environment.ruleset.combat,
      technologyRuleset: environment.ruleset.technology,
      context: environment.context,
    );
  }

  static GameStateTransition selectAttackTarget(
    GameClientState state,
    AttackHexCommand command,
    MapTileLookup mapTiles, {
    CombatRuleset combatRuleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    GameCommandContext context = const GameCommandContext(),
  }) {
    final setup = _CombatTargetingPolicy.unitTarget(
      state,
      command,
      mapTiles,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
      context: context,
      allowExistingTargetOverride: true,
    );
    final citySetup = setup == null
        ? _CombatTargetingPolicy.cityTarget(
            state,
            command,
            mapTiles,
            combatRuleset: combatRuleset,
            technologyRuleset: technologyRuleset,
            context: context,
            allowExistingTargetOverride: true,
          )
        : null;
    if (setup == null && citySetup == null) {
      return _rejectedAttackTransition(state, command, context: context);
    }

    final attackerId = setup?.attacker.id ?? citySetup!.attacker.id;
    final defenderCol = setup?.defender.col ?? citySetup!.city.center.col;
    final defenderRow = setup?.defender.row ?? citySetup!.city.center.row;
    final pendingAction = state.pendingAction;
    if (pendingAction is! PendingAttackTargeting ||
        pendingAction.attackerUnitId != attackerId) {
      return GameStateTransition(state: state);
    }
    return GameStateTransition(
      state: state.copyWithInteraction(
        pendingAction: pendingAction.copyWith(
          defenderCol: defenderCol,
          defenderRow: defenderRow,
        ),
        moveCommandActive: false,
        movePreview: null,
      ),
    );
  }

  static GameStateTransition _rejectedAttackTransition(
    GameClientState state,
    AttackHexCommand command, {
    required GameCommandContext context,
  }) {
    final targetIsVisible = context
        .visibilityFor(state)
        .canSeeDynamicAt(command.defenderCol, command.defenderRow);
    final feedback =
        targetIsVisible &&
            _selectionTargetsProtectedPlayer(state, command, context)
        ? const ShowHudFeedbackEffect(
            reason: HudFeedbackReason.attackProtectedByTreaty,
          )
        : null;
    return GameStateTransition(state: state, uiEffects: [?feedback]);
  }

  static bool _selectionTargetsProtectedPlayer(
    GameClientState state,
    AttackHexCommand command,
    GameCommandContext context,
  ) {
    final attacker = state.unitById(command.attackerUnitId);
    if (attacker == null ||
        !context.canControlUnit(state, attacker) ||
        attacker.isWorking ||
        attacker.movementPoints <= 0) {
      return false;
    }
    final targetOwnerPlayerId =
        state.unitAt(command.defenderCol, command.defenderRow)?.ownerPlayerId ??
        state.cityAt(command.defenderCol, command.defenderRow)?.ownerPlayerId;
    return targetOwnerPlayerId != null &&
        targetOwnerPlayerId != attacker.ownerPlayerId &&
        _isProtectedRelation(
          state,
          attacker.ownerPlayerId,
          targetOwnerPlayerId,
        );
  }

  static bool _isProtectedRelation(
    GameClientState state,
    String attackerPlayerId,
    String defenderPlayerId,
  ) {
    final status = state.diplomacy.statusBetween(
      attackerPlayerId,
      defenderPlayerId,
    );
    return status == DiplomaticRelationStatus.friendly ||
        status == DiplomaticRelationStatus.truce;
  }
}
