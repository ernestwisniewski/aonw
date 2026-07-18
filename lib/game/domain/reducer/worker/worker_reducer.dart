import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/interaction/interaction_reducer.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class WorkerReducer {
  static GameStateTransition selectWorkerImprovement(
    GameState state,
    SelectWorkerImprovementCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (state.pendingAction is PendingWorkerActionSelection) {
      return GameStateTransition(
        state: InteractionReducer.selectWorkerImprovement(state, command),
      );
    }
    final input = _captureInput(state);
    final actorPlayerId = _controlledActorPlayerId(
      state,
      input.units,
      command.unitId,
      context,
    );
    if (actorPlayerId == null) return GameStateTransition(state: state);
    final result = WorkerCommandResolver.selectWorkerImprovement(
      units: input.units,
      cities: input.cities,
      fieldImprovements: input.fieldImprovements,
      research: input.research,
      interaction: input.interaction,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
    return _transitionFrom(
      state,
      input,
      result,
      unitId: command.unitId,
      mapTiles: mapTiles,
      clearWorkPresentation: true,
    );
  }

  static GameStateTransition confirmWorkerImprovement(
    GameState state,
    ConfirmWorkerImprovementCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final input = _captureInput(state);
    final actorPlayerId = _controlledActorPlayerId(
      state,
      input.units,
      command.unitId,
      context,
    );
    if (actorPlayerId == null) return GameStateTransition(state: state);
    final result = WorkerCommandResolver.confirmWorkerImprovement(
      units: input.units,
      cities: input.cities,
      fieldImprovements: input.fieldImprovements,
      research: input.research,
      interaction: input.interaction,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
    return _transitionFrom(
      state,
      input,
      result,
      unitId: command.unitId,
      mapTiles: mapTiles,
      clearWorkPresentation: true,
    );
  }

  static GameStateTransition cancelWorkerJob(
    GameState state,
    CancelWorkerJobCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final input = _captureInput(state);
    final actorPlayerId = _controlledActorPlayerId(
      state,
      input.units,
      command.unitId,
      context,
    );
    if (actorPlayerId == null) return GameStateTransition(state: state);
    final result = WorkerCommandResolver.cancelWorkerJob(
      units: input.units,
      interaction: input.interaction,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    return _transitionFrom(
      state,
      input,
      result,
      unitId: command.unitId,
      mapTiles: mapTiles,
    );
  }

  static GameStateTransition assignWorkerToHex(
    GameState state,
    AssignWorkerToHexCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final input = _captureInput(state);
    final actorPlayerId = _controlledActorPlayerId(
      state,
      input.units,
      command.unitId,
      context,
    );
    if (actorPlayerId == null) return GameStateTransition(state: state);
    final result = WorkerCommandResolver.assignWorkerToHex(
      units: input.units,
      cities: input.cities,
      fieldImprovements: input.fieldImprovements,
      interaction: input.interaction,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
    );
    return _transitionFrom(
      state,
      input,
      result,
      unitId: command.unitId,
      mapTiles: mapTiles,
      clearWorkPresentation: true,
    );
  }

  static GameStateTransition cancelWorkerAssignment(
    GameState state,
    CancelWorkerAssignmentCommand command,
    MapTileLookup mapTiles, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    final input = _captureInput(state);
    final actorPlayerId = _controlledActorPlayerId(
      state,
      input.units,
      command.unitId,
      context,
    );
    if (actorPlayerId == null) return GameStateTransition(state: state);
    final result = WorkerCommandResolver.cancelWorkerAssignment(
      units: input.units,
      interaction: input.interaction,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    return _transitionFrom(
      state,
      input,
      result,
      unitId: command.unitId,
      mapTiles: mapTiles,
    );
  }

  static GameStateTransition _transitionFrom(
    GameState state,
    _WorkerInput input,
    WorkerCommandResult result, {
    required String unitId,
    required MapTileLookup mapTiles,
    bool clearWorkPresentation = false,
  }) {
    if (!result.accepted) return GameStateTransition(state: state);
    final unitsChanged = !identical(result.units, input.units);
    var next = unitsChanged ? state.copyWith(units: result.units) : state;
    final updatedWorker = _unitById(result.units, unitId)!;
    final selection = GameSelection.unit(
      updatedWorker,
      tile: mapTiles.tileAt(updatedWorker.col, updatedWorker.row),
    );
    final pendingAction = clearWorkPresentation
        ? null
        : result.interaction.pendingAction;
    final moveCommandActive = clearWorkPresentation
        ? false
        : state.moveCommandActive;
    final movePreview = clearWorkPresentation ? null : state.movePreview;
    if (_hasPresentationState(
      next,
      cityFoundingDraft: result.interaction.cityFoundingDraft,
      pendingAction: pendingAction,
      moveCommandActive: moveCommandActive,
      movePreview: movePreview,
      selection: selection,
    )) {
      return GameStateTransition(state: next);
    }
    next = next.copyWithInteraction(
      cityFoundingDraft: result.interaction.cityFoundingDraft,
      pendingAction: pendingAction,
      moveCommandActive: moveCommandActive,
      movePreview: movePreview,
      selection: selection,
    );
    return GameStateTransition(state: next);
  }

  static bool _hasPresentationState(
    GameState state, {
    required CityFoundingDraft? cityFoundingDraft,
    required PendingPlayerAction? pendingAction,
    required bool moveCommandActive,
    required UnitMovementPlan? movePreview,
    required GameSelection selection,
  }) {
    return state.cityFoundingDraft == cityFoundingDraft &&
        state.pendingAction == pendingAction &&
        state.moveCommandActive == moveCommandActive &&
        state.movePreview == movePreview &&
        state.selection == selection;
  }

  static _WorkerInput _captureInput(GameState state) {
    return (
      units: state.units,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      interaction: PersistedInteractionState(
        cityFoundingDraft: state.cityFoundingDraft,
        pendingAction: state.pendingAction,
      ),
    );
  }

  static String? _controlledActorPlayerId(
    GameState state,
    List<GameUnit> units,
    String unitId,
    GameCommandContext context,
  ) {
    final unit = _unitById(units, unitId);
    if (unit == null || !context.canControlUnit(state, unit)) return null;
    return unit.ownerPlayerId;
  }

  static GameUnit? _unitById(List<GameUnit> units, String unitId) {
    for (final unit in units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }
}

typedef _WorkerInput = ({
  List<GameUnit> units,
  List<GameCity> cities,
  List<FieldImprovement> fieldImprovements,
  ResearchState research,
  PersistedInteractionState interaction,
});
