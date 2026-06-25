part of 'strategy_aware_economy_ranker.dart';

final class _EconomyUnitProductionRanker {
  const _EconomyUnitProductionRanker()
    : _inventory = const _ProductionInventory(),
      _settlerEscortPolicy = const _ActiveSettlerEscortProductionPolicy(),
      _settlerPolicy = const _SettlerProductionPolicy(),
      _citySiteScoutPolicy = const _CitySiteScoutProductionPolicy(),
      _militaryRecoveryPolicy = const _MilitaryProductionRecoveryPolicy(),
      _workerRecoveryPolicy = const _WorkerProductionRecoveryPolicy();

  final _ProductionInventory _inventory;
  final _ActiveSettlerEscortProductionPolicy _settlerEscortPolicy;
  final _SettlerProductionPolicy _settlerPolicy;
  final _CitySiteScoutProductionPolicy _citySiteScoutPolicy;
  final _MilitaryProductionRecoveryPolicy _militaryRecoveryPolicy;
  final _WorkerProductionRecoveryPolicy _workerRecoveryPolicy;

  CommandRanking? rank(
    StartUnitProductionCommand command,
    GameView view,
    AiContext context,
    StrategicMode mode,
  ) {
    final unitType = command.unitType;
    final activeSettlerNeedsEscort = _settlerEscortPolicy.needsEscortProduction(
      view,
      context,
    );
    return switch (unitType) {
      _ when _military.isType(unitType, context) && activeSettlerNeedsEscort =>
        CommandRanking(
          CandidatePriority.cityRole,
          735 + context.civProfile.belligerence * 24,
        ),
      GameUnitType.settler => _settlerPolicy.rank(
        command,
        view: view,
        context: context,
        mode: mode,
        activeSettlerNeedsEscort: activeSettlerNeedsEscort,
      ),
      _ when _citySiteScoutPolicy.shouldProduceScout(unitType, view, context) =>
        const CommandRanking(CandidatePriority.cityRole, 720),
      _ => _rankRoutineProduction(command, view, context, mode),
    };
  }

  CommandRanking? _rankRoutineProduction(
    StartUnitProductionCommand command,
    GameView view,
    AiContext context,
    StrategicMode mode,
  ) {
    final unitType = command.unitType;
    return switch (mode) {
      _
          when _military.isType(unitType, context) &&
              _militaryRecoveryPolicy.needsRecovery(view, context) =>
        CommandRanking(
          CandidatePriority.cityRole,
          630 + context.civProfile.belligerence * 36,
        ),
      _
          when unitType == GameUnitType.worker &&
              _workerRecoveryPolicy.needsRecovery(view, _inventory) =>
        const CommandRanking(CandidatePriority.cityRole, 610),
      StrategicMode.expand when unitType == GameUnitType.worker =>
        const CommandRanking(CandidatePriority.cityRole, 570),
      StrategicMode.recover when unitType == GameUnitType.worker =>
        const CommandRanking(CandidatePriority.cityRole, 590),
      StrategicMode.military when _military.isType(unitType, context) =>
        CommandRanking(
          CandidatePriority.cityRole,
          580 + context.civProfile.belligerence * 40,
        ),
      StrategicMode.consolidate when unitType == GameUnitType.worker =>
        const CommandRanking(CandidatePriority.cityRole, 530),
      _ => null,
    };
  }
}

final class _CitySiteScoutProductionPolicy {
  const _CitySiteScoutProductionPolicy()
    : _inventory = const _ProductionInventory();

  final _ProductionInventory _inventory;

  bool shouldProduceScout(
    GameUnitType unitType,
    GameView view,
    AiContext context,
  ) {
    final plan = context.strategicPlan;
    return unitType == GameUnitType.scout &&
        AiFrontierExplorationScorer.needsCitySiteDiscovery(
          view: view,
          plan: plan,
        ) &&
        (plan == null || !hasAvailableReconCitySiteScout(view, plan)) &&
        !_inventory.hasQueuedRecon(view);
  }
}

final class _MilitaryProductionRecoveryPolicy {
  const _MilitaryProductionRecoveryPolicy();

  bool needsRecovery(GameView view, AiContext context) {
    final desired =
        (view.ownCities.length *
                context.effectiveWeights.aggression *
                context.civProfile.belligerence)
            .ceil();
    return view.ownCities.isNotEmpty &&
        _military.countWithQueues(view, context) < desired;
  }
}

final class _WorkerProductionRecoveryPolicy {
  const _WorkerProductionRecoveryPolicy();

  bool needsRecovery(GameView view, _ProductionInventory inventory) {
    return view.ownCities.isNotEmpty &&
        inventory.workerCountWithQueues(view) < view.ownCities.length;
  }
}
