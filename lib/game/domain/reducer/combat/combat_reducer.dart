import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

part 'combat_reducer_targeting.dart';

typedef _AttackSetup = ({GameUnit attacker, GameUnit defender});

typedef _CityAttackSetup = ({GameUnit attacker, GameCity city});

abstract final class CombatReducer {
  static GameStateTransition selectAttackTargetWithEnvironment(
    GameState state,
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

  static GameStateTransition attackHexWithEnvironment(
    GameState state,
    AttackHexCommand command,
    ReducerEnvironment environment,
  ) {
    return attackHex(
      state,
      command,
      environment.mapData,
      combatRuleset: environment.ruleset.combat,
      technologyRuleset: environment.ruleset.technology,
      context: environment.context,
      fogOfWarService: environment.fogOfWarService,
    );
  }

  static GameStateTransition selectAttackTarget(
    GameState state,
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

    final next = state.copyWithInteraction(
      pendingAction: pendingAction.copyWith(
        defenderCol: defenderCol,
        defenderRow: defenderRow,
      ),
      moveCommandActive: false,
      movePreview: null,
    );
    return GameStateTransition(state: next);
  }

  static GameStateTransition attackHex(
    GameState state,
    AttackHexCommand command,
    MapTileLookup mapTiles, {
    CombatRuleset combatRuleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    GameCommandContext context = const GameCommandContext(),
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    final attacker = state.unitById(command.attackerUnitId);
    if (attacker != null &&
        (!context.canControlUnit(state, attacker) ||
            !_CombatTargetingPolicy.pendingAllowsCommand(
              state: state,
              command: command,
              attacker: attacker,
              allowExistingTargetOverride: false,
            ))) {
      return GameStateTransition(state: state);
    }
    final actorPlayerId = context.hasActor
        ? context.actorPlayerId!
        : state.activePlayerId.isNotEmpty
        ? state.activePlayerId
        : attacker?.ownerPlayerId ?? '';
    final result = CombatCommandResolver(fogOfWarService: fogOfWarService)
        .resolve(
          state: CombatCommandState(
            units: state.units,
            cities: state.cities,
            artifacts: state.artifacts,
            fogOfWar: state.fogOfWar,
            research: state.research,
            intendedAttacks: state.intendedAttacks,
            diplomacy: state.diplomacy,
            resourceTradeAgreements: state.resourceTradeAgreements,
            playerIds: knownPlayerIds(state),
          ),
          command: command,
          actorPlayerId: actorPlayerId,
          turn: context.combatSeedTurn,
          commandTick: context.commandTick,
          mapTiles: mapTiles,
          ruleset: GameRuleset.defaults.copyWith(
            combat: combatRuleset,
            technology: technologyRuleset,
          ),
          ignoreFogOfWar: context.ignoreFogOfWar,
        );
    if (!result.accepted) {
      return _rejectedAttackTransition(
        state,
        command,
        reason: result.reason,
        context: context,
      );
    }

    final authoritativeState = state.copyWith(
      units: result.units,
      cities: result.cities,
      artifacts: result.artifacts,
      fogOfWar: result.fogOfWar,
      intendedAttacks: result.intendedAttacks,
      diplomacy: result.diplomacy,
      resourceTradeAgreements: result.resourceTradeAgreements,
    );
    final next = _clearAttackInteractionState(
      authoritativeState,
      attackerUnitId: command.attackerUnitId,
      mapTiles: mapTiles,
      changedCityId: _changedCityId(result.events),
    );
    return GameStateTransition(state: next, events: result.events);
  }

  static GameStateTransition _rejectedAttackTransition(
    GameState state,
    AttackHexCommand command, {
    String? reason,
    required GameCommandContext context,
  }) {
    final targetIsVisible = context
        .visibilityFor(state)
        .canSeeDynamicAt(command.defenderCol, command.defenderRow);
    final protectedTarget =
        reason == 'attack_target_protected_by_treaty' ||
        (reason == null &&
            _selectionTargetsProtectedPlayer(state, command, context));
    final feedback = protectedTarget && targetIsVisible
        ? const ShowHudFeedbackEffect(
            reason: HudFeedbackReason.attackProtectedByTreaty,
          )
        : null;
    return GameStateTransition(state: state, uiEffects: [?feedback]);
  }

  static bool _selectionTargetsProtectedPlayer(
    GameState state,
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

  static String? _changedCityId(Iterable<GameEvent> events) {
    for (final event in events) {
      if (event case CityAttackedEvent(:final cityId)) return cityId;
    }
    return null;
  }

  static GameState _clearAttackInteractionState(
    GameState state, {
    required String attackerUnitId,
    required MapTileLookup mapTiles,
    String? changedCityId,
  }) {
    var next = state.copyWithInteraction(
      movePreview: null,
      cityFoundingDraft: null,
      moveCommandActive: false,
    );
    final pendingAction = next.pendingAction;
    if (pendingAction is PendingAttackTargeting &&
        pendingAction.attackerUnitId == attackerUnitId) {
      next = next.copyWithInteraction(pendingAction: null);
    }
    return _refreshSelection(next, mapTiles, changedCityId: changedCityId);
  }

  static bool _isProtectedRelation(
    GameState state,
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

  static GameState _refreshSelection(
    GameState state,
    MapTileLookup mapTiles, {
    String? changedCityId,
  }) {
    final selection = state.selection;
    if (selection == null) return state;
    return switch (selection.type) {
      GameSelectionType.tile => state,
      GameSelectionType.fieldImprovement => state,
      GameSelectionType.unit => _refreshUnit(state, selection, mapTiles),
      GameSelectionType.city =>
        selection.city?.id == changedCityId
            ? state.copyWithInteraction(selection: null)
            : state,
    };
  }

  static GameState _refreshUnit(
    GameState state,
    GameSelection selection,
    MapTileLookup mapTiles,
  ) {
    final selectedId = selection.unit?.id;
    if (selectedId == null) return state.copyWithInteraction(selection: null);
    final unit = state.unitById(selectedId);
    if (unit == null) return state.copyWithInteraction(selection: null);
    final tile = mapTiles.tileAt(unit.col, unit.row);
    final refreshed = GameSelection.unit(unit, tile: tile).withVisibleResources(
      playerId: state.activePlayerId,
      research: state.research,
    );
    return state.copyWithInteraction(selection: refreshed);
  }
}
