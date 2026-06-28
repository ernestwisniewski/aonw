import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'combat_reducer_events.dart';
part 'combat_reducer_outcomes.dart';
part 'combat_reducer_setup.dart';

typedef _AttackSetup = ({
  GameUnit attacker,
  GameUnit defender,
  TileData defenderTile,
  List<CombatModifier> attackerModifiers,
  CombatStats attackerBase,
  CombatStats attackerEffective,
});

typedef _CityAttackSetup = ({
  GameUnit attacker,
  GameCity city,
  TileData cityTile,
  List<CombatModifier> attackerModifiers,
  CombatStats attackerBase,
  CombatStats attackerEffective,
  CombatStats cityBase,
  CombatStats cityEffective,
});

typedef _DefenseSetup = ({
  GameCity? defendedCity,
  List<CombatModifier> defenderModifiers,
  CombatStats defenderBase,
  CombatStats defenderEffective,
  HexCoordinate? retreatDestination,
});

typedef _CombatApplication = ({
  List<GameUnit> units,
  List<GameCity> cities,
  GameUnit? updatedAttacker,
  GameUnit? updatedDefender,
  int attackerExperience,
  int defenderExperience,
});

typedef _CityCombatApplication = ({
  List<GameUnit> units,
  List<GameCity> cities,
  GameUnit? updatedAttacker,
  int attackerExperience,
  GameCity? updatedCity,
  GameCity? capturedCity,
  GameCity? destroyedCity,
});

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
    MapData mapData, {
    CombatRuleset combatRuleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    GameCommandContext context = const GameCommandContext(),
  }) {
    final setup = _CombatSetupFactory.unitAttackSetup(
      state,
      command,
      mapData,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
      context: context,
      allowExistingTargetOverride: true,
    );
    final citySetup = setup == null
        ? _CombatSetupFactory.cityAttackSetup(
            state,
            command,
            mapData,
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
    MapData mapData, {
    CombatRuleset combatRuleset = CombatRuleset.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    GameCommandContext context = const GameCommandContext(),
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    final setup = _CombatSetupFactory.unitAttackSetup(
      state,
      command,
      mapData,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
      context: context,
    );
    if (setup == null) {
      final citySetup = _CombatSetupFactory.cityAttackSetup(
        state,
        command,
        mapData,
        combatRuleset: combatRuleset,
        technologyRuleset: technologyRuleset,
        context: context,
      );
      if (citySetup == null) {
        return _rejectedAttackTransition(state, command, context: context);
      }
      if (combatRuleset.resolutionMode == CombatResolutionMode.simultaneous) {
        return _recordIntent(
          state,
          command,
          citySetup.attacker,
          mapData,
          context,
        );
      }
      return _attackCity(
        state: state,
        command: command,
        mapData: mapData,
        setup: citySetup,
        combatRuleset: combatRuleset,
        fogOfWarService: fogOfWarService,
        context: context,
      );
    }
    final attacker = setup.attacker;
    final defender = setup.defender;
    final attackerModifiers = setup.attackerModifiers;
    final attackerBase = setup.attackerBase;
    final attackerEffective = setup.attackerEffective;

    if (combatRuleset.resolutionMode == CombatResolutionMode.simultaneous) {
      return _recordIntent(state, command, attacker, mapData, context);
    }

    final defense = _CombatSetupFactory.defenseSetup(
      state: state,
      mapData: mapData,
      attacker: attacker,
      defender: defender,
      defenderTile: setup.defenderTile,
      combatRuleset: combatRuleset,
      technologyRuleset: technologyRuleset,
    );
    final defenderModifiers = defense.defenderModifiers;
    final defenderBase = defense.defenderBase;
    final defenderEffective = defense.defenderEffective;
    final retreatDestination = defense.retreatDestination;

    final attackerCombatant = _combatant(
      unit: attacker,
      baseStats: attackerBase,
      modifiers: attackerModifiers,
      effectiveStats: attackerEffective,
    );
    final defenderCombatant = _combatant(
      unit: defender,
      baseStats: defenderBase,
      modifiers: defenderModifiers,
      effectiveStats: defenderEffective,
    );
    final outcome = CombatResolver.resolve(
      attacker: attackerCombatant,
      defender: defenderCombatant,
      ruleset: combatRuleset,
      rng: CombatRng.fromTurn(
        turn: context.combatSeedTurn,
        attackerId: attacker.id,
        defenderId: defender.id,
      ),
      defenderCanRetreat: retreatDestination != null,
    );

    final applied = _CombatOutcomeApplier.applyUnitCombat(
      state: state,
      attacker: attacker,
      defender: defender,
      outcome: outcome,
      attackerEffective: attackerEffective,
      defenderEffective: defenderEffective,
      retreatDestination: retreatDestination,
    );
    final artifacts = _CombatArtifactPolicy.afterUnitCombat(
      state.artifacts,
      attacker: attacker,
      defender: defender,
      outcome: outcome,
    );
    final fogOfWar = fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: mapData,
      playerIds: knownPlayerIds(
        state.copyWith(units: applied.units, cities: applied.cities),
      ),
      units: applied.units,
      cities: applied.cities,
    );

    final next = _clearAttackInteractionState(
      withDiscoveredDiplomaticContacts(
        state.copyWith(
          units: applied.units,
          cities: applied.cities,
          artifacts: artifacts,
          fogOfWar: fogOfWar,
          diplomacy: state.diplomacy.registerUnitAttack(
            attackerPlayerId: attacker.ownerPlayerId,
            defenderPlayerId: defender.ownerPlayerId,
            turn: context.combatSeedTurn,
          ),
        ),
      ),
      attackerUnitId: attacker.id,
      mapData: mapData,
    );

    return GameStateTransition(
      state: next,
      events: _CombatEventFactory.unitCombatEvents(
        attacker: attacker,
        defender: defender,
        outcome: outcome,
        retreatDestination: retreatDestination,
        application: applied,
      ),
      uiEffects: [
        PlayCombatAnimationEffect(
          attackerUnitId: attacker.id,
          defenderUnitId: defender.id,
          attackerKilled: outcome.attackerKilled,
          defenderKilled: outcome.defenderKilled,
        ),
      ],
    );
  }

  static GameStateTransition _attackCity({
    required GameState state,
    required AttackHexCommand command,
    required MapData mapData,
    required _CityAttackSetup setup,
    required CombatRuleset combatRuleset,
    required FogOfWarService fogOfWarService,
    required GameCommandContext context,
  }) {
    final attacker = setup.attacker;
    final attackerCombatant = Combatant(
      unitId: attacker.id,
      ownerPlayerId: attacker.ownerPlayerId,
      baseStats: setup.attackerBase,
      modifiers: setup.attackerModifiers,
      currentHp: UnitCombatHealth.currentHp(
        attacker,
        effectiveStats: setup.attackerEffective,
      ),
    );
    final cityCombatant = Combatant(
      unitId: setup.city.id,
      ownerPlayerId: setup.city.ownerPlayerId,
      baseStats: setup.cityBase,
      currentHp: CityCombatHealth.currentHp(
        setup.city,
        effectiveStats: setup.cityEffective,
      ),
    );
    final outcome = CombatResolver.resolve(
      attacker: attackerCombatant,
      defender: cityCombatant,
      ruleset: combatRuleset,
      rng: CombatRng.fromTurn(
        turn: context.combatSeedTurn,
        attackerId: attacker.id,
        defenderId: setup.city.id,
      ),
    );

    final applied = _CombatOutcomeApplier.applyCityCombat(
      state: state,
      attacker: attacker,
      city: setup.city,
      outcome: outcome,
      attackerEffective: setup.attackerEffective,
      cityEffective: setup.cityEffective,
      cityConquestAction: command.cityConquestAction,
    );
    final artifacts = _CombatArtifactPolicy.afterCityCombat(
      state.artifacts,
      attacker: attacker,
      city: setup.city,
      outcome: outcome,
      cityConquestAction: command.cityConquestAction,
    );
    final fogOfWar = fogOfWarService.recompute(
      current: state.fogOfWar,
      mapData: mapData,
      playerIds: knownPlayerIds(
        state.copyWith(units: applied.units, cities: applied.cities),
      ),
      units: applied.units,
      cities: applied.cities,
    );
    final changedCity =
        applied.capturedCity ?? applied.destroyedCity ?? applied.updatedCity;
    final next = _clearAttackInteractionState(
      withDiscoveredDiplomaticContacts(
        state.copyWith(
          units: applied.units,
          cities: applied.cities,
          artifacts: artifacts,
          fogOfWar: fogOfWar,
          diplomacy: state.diplomacy.registerCityAttack(
            attackerPlayerId: attacker.ownerPlayerId,
            defenderPlayerId: setup.city.ownerPlayerId,
            turn: context.combatSeedTurn,
          ),
        ),
      ),
      attackerUnitId: attacker.id,
      mapData: mapData,
      changedCityId: changedCity?.id,
    );

    return GameStateTransition(
      state: next,
      events: _CombatEventFactory.cityCombatEvents(
        attacker: attacker,
        city: setup.city,
        outcome: outcome,
        application: applied,
      ),
      uiEffects: [
        PlayCombatAnimationEffect(
          attackerUnitId: attacker.id,
          defenderUnitId: setup.city.id,
          attackerKilled: outcome.attackerKilled,
          defenderKilled: outcome.defenderKilled,
        ),
      ],
    );
  }

  static GameStateTransition _rejectedAttackTransition(
    GameState state,
    AttackHexCommand command, {
    required GameCommandContext context,
  }) {
    final feedback = _protectedAttackFeedback(state, command, context: context);
    return GameStateTransition(state: state, uiEffects: [?feedback]);
  }

  static ShowHudFeedbackEffect? _protectedAttackFeedback(
    GameState state,
    AttackHexCommand command, {
    required GameCommandContext context,
  }) {
    final attacker = state.unitById(command.attackerUnitId);
    if (attacker == null ||
        !context.canControlUnit(state, attacker) ||
        attacker.isWorking ||
        attacker.movementPoints <= 0) {
      return null;
    }

    final targetOwnerPlayerId = _attackTargetOwnerPlayerId(state, command);
    if (targetOwnerPlayerId == null ||
        targetOwnerPlayerId == attacker.ownerPlayerId) {
      return null;
    }
    if (!_isProtectedRelation(
      state,
      attacker.ownerPlayerId,
      targetOwnerPlayerId,
    )) {
      return null;
    }
    if (!context
        .visibilityFor(state)
        .canSeeDynamicAt(command.defenderCol, command.defenderRow)) {
      return null;
    }
    return const ShowHudFeedbackEffect(
      reason: HudFeedbackReason.attackProtectedByTreaty,
    );
  }

  static String? _attackTargetOwnerPlayerId(
    GameState state,
    AttackHexCommand command,
  ) {
    final defender = state.unitAt(command.defenderCol, command.defenderRow);
    if (defender != null) return defender.ownerPlayerId;
    return state
        .cityAt(command.defenderCol, command.defenderRow)
        ?.ownerPlayerId;
  }

  static Combatant _combatant({
    required GameUnit unit,
    required CombatStats baseStats,
    required List<CombatModifier> modifiers,
    required CombatStats effectiveStats,
  }) {
    return Combatant(
      unitId: unit.id,
      ownerPlayerId: unit.ownerPlayerId,
      baseStats: baseStats,
      modifiers: modifiers,
      currentHp: UnitCombatHealth.currentHp(
        unit,
        effectiveStats: effectiveStats,
      ),
    );
  }

  static GameStateTransition _recordIntent(
    GameState state,
    AttackHexCommand command,
    GameUnit attacker,
    MapData mapData,
    GameCommandContext context,
  ) {
    final intent = IntendedAttack(
      attackerUnitId: attacker.id,
      defenderCol: command.defenderCol,
      defenderRow: command.defenderRow,
      declaredAtTick: context.commandTick,
      declaringPlayerId: context.actorPlayerId ?? attacker.ownerPlayerId,
      cityConquestAction: command.cityConquestAction,
    );
    final next = _clearAttackInteractionState(
      state.copyWith(
        intendedAttacks: [
          for (final existing in state.intendedAttacks)
            if (existing.attackerUnitId != attacker.id) existing,
          intent,
        ],
      ),
      attackerUnitId: attacker.id,
      mapData: mapData,
    );
    return GameStateTransition(state: next);
  }

  static GameState _clearAttackInteractionState(
    GameState state, {
    required String attackerUnitId,
    required MapData mapData,
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
    return _refreshSelection(next, mapData, changedCityId: changedCityId);
  }

  static List<GameUnit> _insertAtOriginalPosition(
    List<GameUnit> units,
    List<GameUnit> original,
    GameUnit updated,
  ) {
    final result = List<GameUnit>.of(units);
    final originalIndex = original.indexWhere((unit) => unit.id == updated.id);
    var insertIndex = result.length;
    for (var i = 0; i < result.length; i++) {
      final index = original.indexWhere((unit) => unit.id == result[i].id);
      if (index > originalIndex) {
        insertIndex = i;
        break;
      }
    }
    result.insert(insertIndex, updated);
    return result;
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
    MapData mapData, {
    String? changedCityId,
  }) {
    final selection = state.selection;
    if (selection == null) return state;
    return switch (selection.type) {
      GameSelectionType.tile => state,
      GameSelectionType.fieldImprovement => state,
      GameSelectionType.unit => _refreshUnitSelection(
        state,
        selection,
        mapData,
      ),
      GameSelectionType.city =>
        selection.city?.id == changedCityId
            ? state.copyWithInteraction(selection: null)
            : state,
    };
  }

  static GameState _refreshUnitSelection(
    GameState state,
    GameSelection selection,
    MapData mapData,
  ) {
    final selectedId = selection.unit?.id;
    if (selectedId == null) return state.copyWithInteraction(selection: null);
    final unit = state.unitById(selectedId);
    if (unit == null) return state.copyWithInteraction(selection: null);
    return state.copyWithInteraction(
      selection: GameSelection.unit(
        unit,
        tile: mapData.tileAt(unit.col, unit.row),
      ),
    );
  }
}
