import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class TurnReducer {
  static GameStateTransition submitTurn(GameState state, String playerId) {
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

  /// Runs one city turn for every city owned by [playerId]:
  /// food → growth → pending territory claim → production queue,
  /// then advances research and active worker jobs.
  /// Recomputes fog of war afterwards. Returns [GameStateTransition] with the
  /// updated state, domain events, and UI effects.
  static GameStateTransition advanceCitiesForPlayer(
    GameState state,
    String playerId,
    MapData mapData, {
    FogOfWarService fogOfWarService = const FogOfWarService(),
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final result = TurnPipeline.playerEndTurn(fogOfWarService: fogOfWarService)
        .run(
          TurnContext(
            state: state,
            mapData: mapData,
            ruleset: GameRuleset(
              city: cityRuleset,
              technology: technologyRuleset,
              paceBalance: paceBalance,
            ),
            playerId: playerId,
          ),
        );
    return GameStateTransition(
      state: result.state,
      uiEffects: result.uiEffects,
      events: result.events,
    );
  }

  /// Finds the next turn action needing manual attention and focuses it.
  ///
  /// Repeated calls cycle through available units, cities without production,
  /// and missing research instead of restarting from the first priority.
  static GameStateTransition focusNextPendingAction(
    GameState state,
    String playerId,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
    GameObjectiveAdvice? preferredObjectiveAdvice,
    int? actionIndex,
  }) {
    final actions = _pendingTurnActions(
      state,
      playerId,
      mapData,
      technologyRuleset,
    );
    if (actions.isEmpty) return GameStateTransition(state: state);

    final requestedIndex = actionIndex;
    final nextIndex =
        requestedIndex != null &&
            requestedIndex >= 0 &&
            requestedIndex < actions.length
        ? requestedIndex
        : _nextTurnActionIndex(
            state: state,
            playerId: playerId,
            actions: actions,
            preferredObjectiveAdvice: preferredObjectiveAdvice,
          );

    return _focusPendingTurnAction(
      state,
      playerId,
      actions[nextIndex],
      mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  static int _nextTurnActionIndex({
    required GameState state,
    required String playerId,
    required List<_PendingTurnAction> actions,
    required GameObjectiveAdvice? preferredObjectiveAdvice,
  }) {
    final currentIndex = _currentTurnActionIndex(state, playerId, actions);
    final preferredIndex = _preferredTurnActionIndex(
      actions,
      preferredObjectiveAdvice,
    );
    final currentMatchesPreferred =
        currentIndex != -1 &&
        _turnActionMatchesAdvice(
          actions[currentIndex],
          preferredObjectiveAdvice,
        );
    if (preferredIndex != -1 && !currentMatchesPreferred) return preferredIndex;
    if (currentIndex == -1) return 0;
    return (currentIndex + 1) % actions.length;
  }

  /// Focuses the first turn-start action without cycling from old selection.
  static GameStateTransition focusTurnStartAction(
    GameState state,
    String playerId,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final actions = _pendingTurnActions(
      state,
      playerId,
      mapData,
      technologyRuleset,
    );
    final productionEffects = _turnStartProductionEffects(
      state,
      playerId,
      mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
    if (actions.isEmpty) {
      return GameStateTransition(state: state, uiEffects: productionEffects);
    }

    final focusTransition = _focusPendingTurnAction(
      state,
      playerId,
      actions.first,
      mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
    return GameStateTransition(
      state: focusTransition.state,
      events: focusTransition.events,
      uiEffects: [...focusTransition.uiEffects, ...productionEffects],
    );
  }

  static List<ShowCityProductionBubbleEffect> _turnStartProductionEffects(
    GameState state,
    String playerId,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
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
            mapData,
            cityRuleset: cityRuleset,
            technologyRuleset: technologyRuleset,
            paceBalance: paceBalance,
          ),
          delay: Duration(milliseconds: 120 + effects.length * 140),
        ),
      );
    }
    return effects;
  }

  static int? _turnsRemainingForQueue(
    GameState state,
    GameCity city,
    CityProductionQueue queue,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (queue.target is ProjectProductionTarget) return null;
    final targetCost = CityProductionRules.targetCost(
      queue.target,
      ruleset: cityRuleset,
      paceBalance: paceBalance,
    );
    return CityProductionRules.estimatedTurnsRemaining(
      productionCost: targetCost,
      investedProduction: queue.investedProduction,
      productionPerTurn: _productionPerTurnForQueue(
        state,
        city,
        queue,
        mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      ),
    );
  }

  static int _productionPerTurnForQueue(
    GameState state,
    GameCity city,
    CityProductionQueue queue,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: state.research,
      ruleset: technologyRuleset,
    );
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: cityRuleset,
    );
    final cityEconomy = CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: mapData,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
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
    GameState? state,
    String playerId,
    MapData mapData, {
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    if (state == null || playerId.isEmpty) return 0;
    return _pendingTurnActions(
      state,
      playerId,
      mapData,
      technologyRuleset,
    ).length;
  }

  static List<TurnActionTarget> pendingTurnActionTargets(
    GameState? state,
    String playerId,
    MapData mapData, {
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    if (state == null || playerId.isEmpty) return const [];
    return [
      for (final action in _pendingTurnActions(
        state,
        playerId,
        mapData,
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
    GameState? state,
    String playerId,
    MapData mapData, {
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    if (state == null || playerId.isEmpty) return -1;
    final actions = _pendingTurnActions(
      state,
      playerId,
      mapData,
      technologyRuleset,
    );
    if (actions.isEmpty) return -1;
    return _currentTurnActionIndex(state, playerId, actions);
  }

  static GameStateTransition _focusUnitAction(
    GameState state,
    GameUnit unit,
    MapData mapData,
  ) {
    final tileData = mapData.tileAt(unit.col, unit.row);
    final newState = state.copyWithInteraction(
      moveCommandActive: state.canControlUnit(unit) && !unit.isMerchant,
      movePreview: null,
      cityFoundingDraft: null,
      pendingAction: null,
      selection: GameSelection.unit(unit, tile: tileData),
    );

    return GameStateTransition(
      state: newState,
      uiEffects: [JumpCameraEffect(col: unit.col, row: unit.row)],
    );
  }

  static GameStateTransition _focusPendingTurnAction(
    GameState state,
    String playerId,
    _PendingTurnAction action,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    return switch (action) {
      _PendingUnitAction(:final unit) => _focusUnitAction(state, unit, mapData),
      _PendingCityProductionAction(:final city) => _focusCityProductionAction(
        state,
        city,
        mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      ),
      _PendingResearchAction() => _focusResearchAction(state, playerId),
    };
  }

  static GameStateTransition _focusCityProductionAction(
    GameState state,
    GameCity city,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final newState = state.copyWithInteraction(
      moveCommandActive: false,
      movePreview: null,
      cityFoundingDraft: null,
      pendingAction: null,
      selection: _citySelection(
        state,
        city,
        mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        paceBalance: paceBalance,
      ),
    );

    return GameStateTransition(
      state: newState,
      uiEffects: [JumpCameraEffect(col: city.center.col, row: city.center.row)],
    );
  }

  static GameStateTransition _focusResearchAction(
    GameState state,
    String playerId,
  ) {
    final newState = state.copyWithInteraction(
      moveCommandActive: false,
      movePreview: null,
      cityFoundingDraft: null,
      pendingAction: PendingResearchSelection(ownerPlayerId: playerId),
    );

    return GameStateTransition(state: newState);
  }

  static List<_PendingTurnAction> _pendingTurnActions(
    GameState state,
    String playerId,
    MapData mapData,
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
            mapData: mapData,
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
    GameState state,
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

  static bool _researchSelectionIsCurrent(GameState state, String playerId) {
    return switch (state.pendingAction) {
      PendingResearchSelection(ownerPlayerId: final ownerPlayerId)
          when ownerPlayerId == playerId =>
        true,
      _ => false,
    };
  }

  static String? _currentTurnActionUnitId(GameState state, String playerId) {
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

  static String? _currentTurnActionCityId(GameState state, String playerId) {
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
    GameState state,
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

  static bool _needsManualUnitAction(GameUnit unit, String playerId) {
    return UnitTurnActionRules.needsManualOrder(unit, playerId: playerId);
  }

  static _UnitActionCategory _unitActionCategory(GameUnit unit) {
    if (UnitCombatStats.derive(unit).attack > 0) {
      return _UnitActionCategory.combat;
    }
    if (unit.type == GameUnitType.worker || unit.type == GameUnitType.settler) {
      return _UnitActionCategory.worker;
    }
    return _UnitActionCategory.other;
  }

  static GameSelection _citySelection(
    GameState state,
    GameCity city,
    MapData mapData, {
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      ruleset: cityRuleset,
    );
    final cityEconomy = CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: mapData,
      ruleset: cityRuleset,
      paceBalance: paceBalance,
      technologyEffects: TechnologyEffectSummary.forPlayer(
        playerId: city.ownerPlayerId,
        research: state.research,
        ruleset: technologyRuleset,
      ),
    );
    return GameSelection.city(
      city,
      cityYield: cityYield,
      cityEconomy: cityEconomy,
      playerColor:
          state.colorForPlayer(city.ownerPlayerId) ?? Player.palette.first,
    );
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
