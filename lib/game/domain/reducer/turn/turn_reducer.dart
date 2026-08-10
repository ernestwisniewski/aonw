import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/turn/unit_turn_action_rules.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

part 'turn_reducer_action_category.dart';
part 'turn_reducer_map_action_effects.dart';
part 'turn_reducer_navigation.dart';
part 'turn_reducer_pending_actions.dart';
part 'turn_reducer_production_feedback.dart';

abstract final class TurnReducer {
  static GameStateTransition submitTurn(
    GameClientState state,
    String playerId,
  ) {
    if (playerId.isEmpty || state.submittedPlayerIds.contains(playerId)) {
      return GameStateTransition(state: state);
    }
    var next = state.copyWith(
      submittedPlayerIds: {...state.submittedPlayerIds, playerId},
    );
    if (state.activePlayerId == playerId) {
      next = next
          .copyWith(activePlayerCanAct: false)
          .copyWithInteraction(
            moveCommandActive: false,
            movePreview: null,
            cityFoundingDraft: null,
            pendingAction: null,
          );
    }
    return GameStateTransition(state: next);
  }

  /// Finds the next turn action needing manual attention and focuses it.
  ///
  /// Repeated calls cycle through available units, cities without production,
  /// and missing research instead of restarting from the first priority.
  static GameStateTransition focusNextPendingAction(
    GameClientState state,
    String playerId,
    MapTileLookup mapTiles, {
    GameRuleset ruleset = GameRuleset.defaults,
    PaceBalance paceBalance = PaceBalance.unlimited,
    GameObjectiveAdvice? preferredObjectiveAdvice,
    int? actionIndex,
    int actionStep = 1,
  }) {
    final actions = _pendingTurnActions(
      state,
      playerId,
      mapTiles,
      ruleset.technology,
    );
    if (actions.isEmpty) return GameStateTransition(state: state);
    final requestedIndex = actionIndex;
    final nextIndex = requestedIndex != null
        ? _wrapTurnActionIndex(requestedIndex, actions.length)
        : _nextTurnActionIndex(
            state: state,
            playerId: playerId,
            actions: actions,
            preferredObjectiveAdvice: preferredObjectiveAdvice,
            actionStep: actionStep,
          );

    return _focusPendingTurnAction(
      state,
      playerId,
      actions[nextIndex],
      mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    );
  }

  /// Focuses the first turn-start action without cycling from old selection.
  static GameStateTransition focusTurnStartAction(
    GameClientState state,
    String playerId,
    MapTileLookup mapTiles, {
    GameRuleset ruleset = GameRuleset.defaults,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final actions = _pendingTurnActions(
      state,
      playerId,
      mapTiles,
      ruleset.technology,
    );
    final productionEffects = _turnStartProductionEffects(
      state,
      playerId,
      mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    );
    if (actions.isEmpty) {
      return GameStateTransition(state: state, uiEffects: productionEffects);
    }

    final focusTransition = _focusPendingTurnAction(
      state,
      playerId,
      actions.first,
      mapTiles,
      ruleset: ruleset,
      paceBalance: paceBalance,
    );
    return GameStateTransition(
      state: focusTransition.state,
      events: focusTransition.events,
      uiEffects: [...focusTransition.uiEffects, ...productionEffects],
    );
  }

  static int pendingTurnActionCount(
    GameClientState? state,
    String playerId,
    MapTileLookup mapTiles, {
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    if (state == null || playerId.isEmpty) return 0;
    return _pendingTurnActions(
      state,
      playerId,
      mapTiles,
      technologyRuleset,
    ).length;
  }

  static List<TurnActionTarget> pendingTurnActionTargets(
    GameClientState? state,
    String playerId,
    MapTileLookup mapTiles, {
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    if (state == null || playerId.isEmpty) return const [];
    return [
      for (final action in _pendingTurnActions(
        state,
        playerId,
        mapTiles,
        technologyRuleset,
      ))
        switch (action) {
          _PendingUnitAction(:final unit) => UnitTurnActionTarget(unit),
          _PendingCityProductionAction(:final city) =>
            CityProductionTurnActionTarget(city),
          _PendingResearchAction() => const ResearchTurnActionTarget(),
        },
    ];
  }

  static int currentPendingTurnActionIndex(
    GameClientState? state,
    String playerId,
    MapTileLookup mapTiles, {
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    if (state == null || playerId.isEmpty) return -1;
    final actions = _pendingTurnActions(
      state,
      playerId,
      mapTiles,
      technologyRuleset,
    );
    if (actions.isEmpty) return -1;
    return _currentTurnActionIndex(state, playerId, actions);
  }
}

sealed class TurnActionTarget {
  const TurnActionTarget();
}

final class UnitTurnActionTarget extends TurnActionTarget {
  const UnitTurnActionTarget(this.unit);

  final GameUnit unit;
}

final class CityProductionTurnActionTarget extends TurnActionTarget {
  const CityProductionTurnActionTarget(this.city);

  final GameCity city;
}

final class ResearchTurnActionTarget extends TurnActionTarget {
  const ResearchTurnActionTarget();
}
