part of 'strategy_aware_economy_ranker.dart';

final class _ProductionInventory {
  const _ProductionInventory();

  bool hasActiveOrQueuedSettler(GameView view) {
    return view.ownUnits.any(CityFoundingRules.canFoundCityWith) ||
        view.ownCities.any(_cityQueuesSettler);
  }

  bool hasQueuedRecon(GameView view) {
    return view.ownCities.any(_cityQueuesRecon);
  }

  int workerCountWithQueues(GameView view) {
    return view.ownUnits.where((unit) => unit.isWorker).length +
        view.ownCities.where(_cityQueuesWorker).length;
  }

  bool _cityQueuesSettler(GameCity city) {
    return _queuedUnitType(city) == GameUnitType.settler;
  }

  bool _cityQueuesWorker(GameCity city) {
    return _queuedUnitType(city) == GameUnitType.worker;
  }

  bool _cityQueuesRecon(GameCity city) {
    final unitType = _queuedUnitType(city);
    return unitType != null && isReconType(unitType);
  }

  GameUnitType? _queuedUnitType(GameCity city) {
    final target = city.productionQueue?.target;
    return target is UnitProductionTarget ? target.unitType : null;
  }
}
