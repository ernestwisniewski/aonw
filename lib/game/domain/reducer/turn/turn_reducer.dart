import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/city_selection_projector.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/turn/unit_turn_action_rules.dart';
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

typedef _ClientState = GameClientState;

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

  static int _nextTurnActionIndex({
    required _ClientState state,
    required String playerId,
    required List<_PendingTurnAction> actions,
    required GameObjectiveAdvice? preferredObjectiveAdvice,
    required int actionStep,
  }) {
    final currentIndex = _currentTurnActionIndex(state, playerId, actions);
    final preferredIndex = _preferredTurnActionIndex(
      actions,
      preferredObjectiveAdvice,
    );
    final step = actionStep == 0 ? 1 : actionStep;
    final currentMatchesPreferred =
        currentIndex != -1 &&
        _turnActionMatchesAdvice(
          actions[currentIndex],
          preferredObjectiveAdvice,
        );
    if (step > 0 && preferredIndex != -1 && !currentMatchesPreferred) {
      return preferredIndex;
    }
    if (currentIndex == -1) return step > 0 ? 0 : actions.length - 1;
    return _wrapTurnActionIndex(currentIndex + step, actions.length);
  }

  static int _wrapTurnActionIndex(int index, int actionCount) {
    final wrapped = index.remainder(actionCount);
    return wrapped < 0 ? wrapped + actionCount : wrapped;
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

  static List<ShowCityProductionBubbleEffect> _turnStartProductionEffects(
    _ClientState state,
    String playerId,
    MapTileLookup mapTiles, {
    GameRuleset ruleset = GameRuleset.defaults,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (playerId.isEmpty) return const [];
    final effects = <ShowCityProductionBubbleEffect>[];
    for (final city in state.cities) {
      if (city.ownerPlayerId != playerId) continue;
      final queue = city.productionQueue;
      if (queue == null) continue;
      effects.add(
        ShowCityProductionBubbleEffect(
          target: queue.target,
          col: city.center.col,
          row: city.center.row,
          turnsRemaining: _turnsRemainingForQueue(
            state,
            city,
            queue,
            mapTiles,
            ruleset: ruleset,
            paceBalance: paceBalance,
          ),
          delay: Duration(milliseconds: 120 + effects.length * 140),
        ),
      );
    }
    return effects;
  }

  static int? _turnsRemainingForQueue(
    _ClientState state,
    GameCity city,
    CityProductionQueue queue,
    MapTileLookup mapTiles, {
    GameRuleset ruleset = GameRuleset.defaults,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (queue.target is ProjectProductionTarget) return null;
    final targetCost = CityProductionRules.targetCost(
      queue.target,
      ruleset: ruleset.city,
      wonderRuleset: ruleset.wonders,
      paceBalance: paceBalance,
    );
    return CityProductionRules.estimatedTurnsRemaining(
      productionCost: targetCost,
      investedProduction: queue.investedProduction,
      productionPerTurn: _productionPerTurnForQueue(
        state,
        city,
        queue,
        mapTiles,
        ruleset: ruleset,
        paceBalance: paceBalance,
      ),
    );
  }

  static int _productionPerTurnForQueue(
    _ClientState state,
    GameCity city,
    CityProductionQueue queue,
    MapTileLookup mapTiles, {
    GameRuleset ruleset = GameRuleset.defaults,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: state.research,
      ruleset: ruleset.technology,
    );
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapTiles,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: ruleset.city,
    );
    final cityEconomy = CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapTiles: mapTiles,
      ruleset: ruleset.city,
      technologyEffects: technologyEffects,
      cities: state.cities,
      wonderRegistry: state.wonderRegistry,
      wonderRuleset: ruleset.wonders,
      stabilityModifier: StabilityPolicy.modifierForNet(
        state.playerStabilityNet[city.ownerPlayerId] ?? 0,
        ruleset: ruleset.stability,
      ),
      paceBalance: paceBalance,
    );
    var productionPerTurn = CityProductionRules.productionPerTurn(
      cityEconomy.netYield.production,
    );
    if (queue.target is UnitProductionTarget) {
      productionPerTurn = CityTechnologyEffectRules.unitProductionPerTurn(
        productionPerTurn,
        effects: technologyEffects,
      );
    }
    return CitySpecializationRules.productionPerTurnForTarget(
      productionPerTurn: productionPerTurn,
      target: queue.target,
      specialization: city.specialization,
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

  static GameStateTransition _focusUnitAction(
    _ClientState state,
    GameUnit unit,
    MapTileLookup mapTiles,
  ) {
    final tile = mapTiles.tileAt(unit.col, unit.row);
    final newState = state.copyWithInteraction(
      moveCommandActive: state.canControlUnit(unit) && !unit.isMerchant,
      movePreview: null,
      cityFoundingDraft: null,
      pendingAction: null,
      selection: GameSelection.unit(unit, tile: tile),
    );

    return GameStateTransition(
      state: newState,
      uiEffects: [JumpCameraEffect(col: unit.col, row: unit.row)],
    );
  }

  static GameStateTransition _focusPendingTurnAction(
    _ClientState state,
    String playerId,
    _PendingTurnAction action,
    MapTileLookup mapTiles, {
    GameRuleset ruleset = GameRuleset.defaults,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return switch (action) {
      _PendingUnitAction(:final unit) => _focusUnitAction(
        state,
        unit,
        mapTiles,
      ),
      _PendingCityProductionAction(:final city) => _focusCityProductionAction(
        state,
        city,
        mapTiles,
        ruleset: ruleset,
        paceBalance: paceBalance,
      ),
      _PendingResearchAction() => _focusResearchAction(state, playerId),
    };
  }

  static GameStateTransition _focusCityProductionAction(
    _ClientState state,
    GameCity city,
    MapTileLookup mapTiles, {
    GameRuleset ruleset = GameRuleset.defaults,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final newState = state.copyWithInteraction(
      moveCommandActive: false,
      movePreview: null,
      cityFoundingDraft: null,
      pendingAction: null,
      selection: CitySelectionProjector.project(
        state: state,
        city: city,
        mapTiles: mapTiles,
        ruleset: ruleset,
        paceBalance: paceBalance,
      ),
    );

    return GameStateTransition(
      state: newState,
      uiEffects: [JumpCameraEffect(col: city.center.col, row: city.center.row)],
    );
  }

  static GameStateTransition _focusResearchAction(
    _ClientState state,
    String playerId,
  ) => GameStateTransition(
    state: state.copyWithInteraction(
      moveCommandActive: false,
      movePreview: null,
      cityFoundingDraft: null,
      pendingAction: PendingResearchSelection(ownerPlayerId: playerId),
    ),
  );

  static List<_PendingTurnAction> _pendingTurnActions(
    _ClientState state,
    String playerId,
    MapTileLookup mapTiles,
    TechnologyRuleset technologyRuleset,
  ) {
    final actions = <_PendingTurnAction>[];
    final unitCandidates = <_PendingUnitCandidate>[];
    for (var index = 0; index < state.units.length; index++) {
      final unit = state.units[index];
      if (!_needsManualUnitAction(unit, playerId)) continue;
      unitCandidates.add(
        _PendingUnitCandidate(
          unit: unit,
          originalIndex: index,
          category: _unitActionCategory(unit),
          seesEnemy: UnitFortificationRules.hasVisibleEnemy(
            unit: unit,
            mapData: mapTiles,
            units: state.units,
          ),
        ),
      );
    }
    unitCandidates.sort();
    actions.addAll(
      unitCandidates.map((candidate) => _PendingUnitAction(candidate.unit)),
    );

    for (final city in state.cities) {
      if (city.ownerPlayerId != playerId) continue;
      if (city.productionQueue != null) continue;
      actions.add(_PendingCityProductionAction(city));
    }

    if (_needsResearchSelection(state, playerId, technologyRuleset)) {
      actions.add(const _PendingResearchAction());
    }

    return actions;
  }

  static int _currentTurnActionIndex(
    _ClientState state,
    String playerId,
    List<_PendingTurnAction> actions,
  ) {
    if (_researchSelectionIsCurrent(state, playerId)) {
      final index = actions.indexWhere(
        (action) => action is _PendingResearchAction,
      );
      if (index != -1) return index;
    }

    final unitId = _currentTurnActionUnitId(state, playerId);
    if (unitId != null) {
      final index = actions.indexWhere(
        (action) => action is _PendingUnitAction && action.unit.id == unitId,
      );
      if (index != -1) return index;
    }

    final cityId = _currentTurnActionCityId(state, playerId);
    if (cityId != null) {
      final index = actions.indexWhere(
        (action) =>
            action is _PendingCityProductionAction && action.city.id == cityId,
      );
      if (index != -1) return index;
    }

    return -1;
  }

  static int _preferredTurnActionIndex(
    List<_PendingTurnAction> actions,
    GameObjectiveAdvice? preferredObjectiveAdvice,
  ) {
    if (preferredObjectiveAdvice == null) return -1;
    return actions.indexWhere(
      (action) => _turnActionMatchesAdvice(action, preferredObjectiveAdvice),
    );
  }

  static bool _turnActionMatchesAdvice(
    _PendingTurnAction action,
    GameObjectiveAdvice? preferredObjectiveAdvice,
  ) {
    if (preferredObjectiveAdvice == null) return false;
    return switch (action) {
      _PendingUnitAction(:final unit) => _unitActionMatchesAdvice(
        unit,
        preferredObjectiveAdvice,
      ),
      _PendingCityProductionAction() => _cityActionMatchesAdvice(
        preferredObjectiveAdvice,
      ),
      _PendingResearchAction() => _researchActionMatchesAdvice(
        preferredObjectiveAdvice,
      ),
    };
  }

  static bool _unitActionMatchesAdvice(
    GameUnit unit,
    GameObjectiveAdvice preferredObjectiveAdvice,
  ) {
    return switch (preferredObjectiveAdvice) {
      GameObjectiveAdvice.improveField => unit.type == GameUnitType.worker,
      GameObjectiveAdvice.foundCity ||
      GameObjectiveAdvice.claimTerritory => unit.type == GameUnitType.settler,
      GameObjectiveAdvice.trainUnit || GameObjectiveAdvice.protectLead =>
        UnitCombatStats.derive(unit).attack > 0,
      _ => false,
    };
  }

  static bool _cityActionMatchesAdvice(
    GameObjectiveAdvice preferredObjectiveAdvice,
  ) {
    return switch (preferredObjectiveAdvice) {
      GameObjectiveAdvice.constructBuilding ||
      GameObjectiveAdvice.trainUnit ||
      GameObjectiveAdvice.foundCity ||
      GameObjectiveAdvice.growPopulation ||
      GameObjectiveAdvice.improveField ||
      GameObjectiveAdvice.claimTerritory ||
      GameObjectiveAdvice.collectGold ||
      GameObjectiveAdvice.protectLead => true,
      GameObjectiveAdvice.unlockTechnology => false,
    };
  }

  static bool _researchActionMatchesAdvice(
    GameObjectiveAdvice preferredObjectiveAdvice,
  ) {
    return switch (preferredObjectiveAdvice) {
      GameObjectiveAdvice.unlockTechnology ||
      GameObjectiveAdvice.protectLead => true,
      _ => false,
    };
  }

  static bool _researchSelectionIsCurrent(_ClientState state, String playerId) {
    return switch (state.pendingAction) {
      PendingResearchSelection(ownerPlayerId: final ownerPlayerId)
          when ownerPlayerId == playerId =>
        true,
      _ => false,
    };
  }

  static String? _currentTurnActionUnitId(_ClientState state, String playerId) {
    switch (state.pendingAction) {
      case PendingAttackTargeting(
            ownerPlayerId: final ownerPlayerId,
            attackerUnitId: final attackerUnitId,
          )
          when ownerPlayerId == playerId:
        return attackerUnitId;
      case PendingWorkerActionSelection(
            ownerPlayerId: final ownerPlayerId,
            unitId: final unitId,
          )
          when ownerPlayerId == playerId:
        return unitId;
      default:
    }

    final cityFoundingDraft = state.cityFoundingDraft;
    if (cityFoundingDraft != null &&
        cityFoundingDraft.ownerPlayerId == playerId) {
      return cityFoundingDraft.unitId;
    }

    final selectedUnit = state.selection?.unit;
    if (selectedUnit != null && selectedUnit.ownerPlayerId == playerId) {
      return selectedUnit.id;
    }
    return null;
  }

  static String? _currentTurnActionCityId(_ClientState state, String playerId) {
    switch (state.pendingAction) {
      case PendingCityWorkedHexSelection(
            ownerPlayerId: final ownerPlayerId,
            cityId: final cityId,
          )
          when ownerPlayerId == playerId:
        return cityId;
      case PendingCityExpansionSelection(
            ownerPlayerId: final ownerPlayerId,
            cityId: final cityId,
          )
          when ownerPlayerId == playerId:
        return cityId;
      default:
    }

    final selectedCity = state.selection?.city;
    if (selectedCity != null && selectedCity.ownerPlayerId == playerId) {
      return selectedCity.id;
    }
    return null;
  }

  static bool _needsResearchSelection(
    _ClientState state,
    String playerId,
    TechnologyRuleset ruleset,
  ) {
    final playerResearch = state.research.forPlayer(playerId);
    if (playerResearch.activeTechnologyId != null) return false;

    for (final technologyId in ruleset.technologies.keys) {
      final availability = TechnologyAvailabilityService.availabilityFor(
        technologyId: technologyId,
        playerResearch: playerResearch,
        ruleset: ruleset,
      );
      if (availability == TechnologyAvailability.available) return true;
    }
    return false;
  }
}

sealed class _PendingTurnAction {
  const _PendingTurnAction();
}

final class _PendingUnitAction extends _PendingTurnAction {
  const _PendingUnitAction(this.unit);

  final GameUnit unit;
}

final class _PendingCityProductionAction extends _PendingTurnAction {
  const _PendingCityProductionAction(this.city);

  final GameCity city;
}

final class _PendingResearchAction extends _PendingTurnAction {
  const _PendingResearchAction();
}

enum _UnitActionCategory {
  combat(0),
  worker(1),
  other(2);

  const _UnitActionCategory(this.order);

  final int order;
}

class _PendingUnitCandidate implements Comparable<_PendingUnitCandidate> {
  const _PendingUnitCandidate({
    required this.unit,
    required this.originalIndex,
    required this.category,
    required this.seesEnemy,
  });

  final GameUnit unit;
  final int originalIndex;
  final _UnitActionCategory category;
  final bool seesEnemy;

  @override
  int compareTo(_PendingUnitCandidate other) {
    final categoryOrder = category.order.compareTo(other.category.order);
    if (categoryOrder != 0) return categoryOrder;
    final enemySightOrder = (seesEnemy ? 0 : 1).compareTo(
      other.seesEnemy ? 0 : 1,
    );
    if (enemySightOrder != 0) return enemySightOrder;
    return originalIndex.compareTo(other.originalIndex);
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
