part of 'strategy_aware_economy_ranker.dart';

final class _SettlerProductionPolicy {
  const _SettlerProductionPolicy()
    : _inventory = const _ProductionInventory(),
      _openingSecondCityPolicy = const _OpeningSecondCitySettlerPolicy(),
      _stableThirdCityPolicy = const _StableThirdCitySettlerPolicy(),
      _deferralPolicy = const _SettlerProductionDeferralPolicy(),
      _militaryModePolicy = const _MilitaryModeSettlerProductionPolicy();

  final _ProductionInventory _inventory;
  final _OpeningSecondCitySettlerPolicy _openingSecondCityPolicy;
  final _StableThirdCitySettlerPolicy _stableThirdCityPolicy;
  final _SettlerProductionDeferralPolicy _deferralPolicy;
  final _MilitaryModeSettlerProductionPolicy _militaryModePolicy;

  CommandRanking? rank(
    StartUnitProductionCommand command, {
    required GameView view,
    required AiContext context,
    required StrategicMode mode,
    required bool activeSettlerNeedsEscort,
  }) {
    if (activeSettlerNeedsEscort) return null;

    final openingSecondCitySprint = _openingSecondCityPolicy.shouldSprint(
      view,
      context,
      _inventory,
    );
    if (openingSecondCitySprint) {
      return const CommandRanking(CandidatePriority.settler, 790);
    }

    final stableThirdCityPush = _stableThirdCityPolicy.shouldPush(
      view,
      context,
      _inventory,
    );
    if (stableThirdCityPush) {
      return const CommandRanking(CandidatePriority.settler, 775);
    }

    final productionDeferred = _deferralPolicy.shouldDefer(
      view,
      context,
      inventory: _inventory,
      hasImmediateExpansionPush: openingSecondCitySprint || stableThirdCityPush,
    );
    if (productionDeferred) return null;

    return switch (mode) {
      StrategicMode.expand => const CommandRanking(
        CandidatePriority.settler,
        780,
      ),
      StrategicMode.military
          when _militaryModePolicy.canSpareSecondCitySettler(
            view,
            command,
            context,
            _inventory,
            productionDeferred: productionDeferred,
          ) =>
        const CommandRanking(CandidatePriority.cityRole, 660),
      _ => null,
    };
  }
}

final class _OpeningSecondCitySettlerPolicy {
  const _OpeningSecondCitySettlerPolicy()
    : _defensePressurePolicy = const _CityDefenseProductionPressurePolicy(),
      _enemyProximityPolicy = const _SettlerEnemyProximityPolicy();

  final _CityDefenseProductionPressurePolicy _defensePressurePolicy;
  final _SettlerEnemyProximityPolicy _enemyProximityPolicy;

  bool shouldSprint(
    GameView view,
    AiContext context,
    _ProductionInventory inventory,
  ) {
    if (view.ownCities.length != 1) return false;
    if (inventory.hasActiveOrQueuedSettler(view)) return false;
    if (inventory.workerCountWithQueues(view) > 0) return false;

    final militaryCount = _military.countWithQueues(view, context);
    if (militaryCount < 2) return false;
    if (_defensePressurePolicy.cityNeedsProduction(
      context.strategicPlan?.defenses[view.ownCities.first.id],
      militaryCount: militaryCount,
      minimumMilitaryCount: 2,
    )) {
      return false;
    }
    if (_enemyProximityPolicy.hasUnsafeEnemyNearCore(
      view,
      context,
      militaryCount,
    )) {
      return false;
    }

    final assessment = AiEmpireAssessment.fromView(view, context);
    final weights = context.effectiveWeights;
    final expansionDeficit =
        assessment.desiredCityCount -
        assessment.cityCount -
        assessment.settlerCount;
    return expansionDeficit >= 2 &&
        weights.aggression > weights.expansion &&
        assessment.netGoldPerTurn >= 0;
  }
}

final class _StableThirdCitySettlerPolicy {
  const _StableThirdCitySettlerPolicy()
    : _enemyProximityPolicy = const _SettlerEnemyProximityPolicy();

  final _SettlerEnemyProximityPolicy _enemyProximityPolicy;

  bool shouldPush(
    GameView view,
    AiContext context,
    _ProductionInventory inventory,
  ) {
    if (view.ownCities.length != 2) return false;
    if (inventory.hasActiveOrQueuedSettler(view)) return false;

    final militaryCount = _military.countWithQueues(view, context);
    if (militaryCount < view.ownCities.length) return false;

    final escortedUnderPressure = militaryCount >= view.ownCities.length + 1;
    if (!_defensesAllowExpansion(
      context.strategicPlan?.defenses.values ??
          const <StrategicDefenseAssignment>[],
      militaryCount: militaryCount,
      cityCount: view.ownCities.length,
      escortedUnderPressure: escortedUnderPressure,
    )) {
      return false;
    }
    if (_enemyProximityPolicy.hasUnsafeEnemyNearCore(
      view,
      context,
      militaryCount,
      blockWithoutEscort: true,
      escortedUnderPressure: escortedUnderPressure,
    )) {
      return false;
    }

    final assessment = AiEmpireAssessment.fromView(view, context);
    if (!assessment.wantsExpansion || assessment.netGoldPerTurn < 0) {
      return false;
    }
    return assessment.desiredCityCount - assessment.cityCount >= 1;
  }

  bool _defensesAllowExpansion(
    Iterable<StrategicDefenseAssignment> defenses, {
    required int militaryCount,
    required int cityCount,
    required bool escortedUnderPressure,
  }) {
    for (final defense in defenses) {
      if (defense.threatLevel > 0 && !escortedUnderPressure) return false;
      if (!defense.hasAssignedGarrison && militaryCount < cityCount) {
        return false;
      }
    }
    return true;
  }
}

final class _SettlerProductionDeferralPolicy {
  const _SettlerProductionDeferralPolicy()
    : _militaryRecoveryPolicy = const _MilitaryProductionRecoveryPolicy();

  final _MilitaryProductionRecoveryPolicy _militaryRecoveryPolicy;

  bool shouldDefer(
    GameView view,
    AiContext context, {
    required _ProductionInventory inventory,
    required bool hasImmediateExpansionPush,
  }) {
    if (view.ownCities.isEmpty) return false;
    if (hasImmediateExpansionPush) return false;
    if (inventory.hasActiveOrQueuedSettler(view) && view.ownCities.length < 2) {
      return true;
    }
    return _militaryRecoveryPolicy.needsRecovery(view, context);
  }
}

final class _MilitaryModeSettlerProductionPolicy {
  const _MilitaryModeSettlerProductionPolicy()
    : _defensePressurePolicy = const _CityDefenseProductionPressurePolicy(),
      _enemyProximityPolicy = const _SettlerEnemyProximityPolicy();

  final _CityDefenseProductionPressurePolicy _defensePressurePolicy;
  final _SettlerEnemyProximityPolicy _enemyProximityPolicy;

  bool canSpareSecondCitySettler(
    GameView view,
    StartUnitProductionCommand command,
    AiContext context,
    _ProductionInventory inventory, {
    required bool productionDeferred,
  }) {
    if (view.ownCities.length != 1) return false;
    if (productionDeferred) return false;
    if (inventory.hasActiveOrQueuedSettler(view)) return false;

    final militaryCount = _military.countWithQueues(view, context);
    if (militaryCount < 2) return false;
    if (_defensePressurePolicy.cityNeedsProduction(
      context.strategicPlan?.defenses[command.cityId],
      militaryCount: militaryCount,
      minimumMilitaryCount: 2,
    )) {
      return false;
    }
    return !_enemyProximityPolicy.hasUnsafeEnemyNearCore(
      view,
      context,
      militaryCount,
    );
  }
}

final class _SettlerEnemyProximityPolicy {
  const _SettlerEnemyProximityPolicy();

  bool hasUnsafeEnemyNearCore(
    GameView view,
    AiContext context,
    int militaryCount, {
    bool blockWithoutEscort = false,
    bool escortedUnderPressure = false,
  }) {
    for (final enemy in view.visibleTargetableEnemyUnits) {
      if (!_military.isUnit(enemy, context)) continue;
      if (isNearOwnCity(view, enemy.col, enemy.row, 2) &&
          (militaryCount < 2 ||
              (blockWithoutEscort && !escortedUnderPressure))) {
        return true;
      }
    }
    return false;
  }
}

final class _CityDefenseProductionPressurePolicy {
  const _CityDefenseProductionPressurePolicy();

  bool cityNeedsProduction(
    StrategicDefenseAssignment? defense, {
    required int militaryCount,
    required int minimumMilitaryCount,
  }) {
    if (defense == null) return false;

    final defenseNeedsProduction =
        defense.threatLevel > 0 || !defense.hasAssignedGarrison;
    return defenseNeedsProduction &&
        (!defense.hasAssignedGarrison || militaryCount < minimumMilitaryCount);
  }
}
