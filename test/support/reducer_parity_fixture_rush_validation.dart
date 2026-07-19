part of 'reducer_parity_fixture.dart';

const _requiredRushFixtureIds = {
  'city-production-rush-not-found-rejected',
  'city-production-rush-wrong-actor-rejected',
  'city-production-rush-wrong-actor-compound-rejected',
  'city-production-rush-empty-queue-rejected',
  'city-production-rush-project-rejected',
  'city-production-rush-insufficient-gold-rejected',
  'city-production-rush-complete-queue-rejected',
  'city-production-rush-unrest-accepted',
  'city-production-rush-building-completed-accepted',
  'city-production-rush-unit-completed-accepted',
  'city-production-rush-unit-spawn-blocked-accepted',
  'city-production-rush-wonder-completed-accepted',
  'city-production-rush-wonder-precompleted-refund-accepted',
};

const _requiredRushRejectionReasons = {
  'city_not_found',
  'city_not_controlled',
  'production_queue_empty',
  'project_cannot_be_rushed',
  'rush_production_unavailable',
};

enum _RushUnavailableCause { insufficientGold, queueAlreadyComplete }

enum _RushAcceptanceMode {
  partial,
  buildingCompletion,
  unitCompletion,
  blockedUnitCompletion,
  wonderCompletion,
  completedWonderRefund,
}

final class _RushCorpusSummary {
  final fixtureIds = <String>{};
  final rejectionReasons = <String>{};
  final unavailableCauses = <String>{};
  final acceptanceModes = <String>{};

  void record(ReducerParityFixture fixture) {
    if (fixture.command is! RushProductionCommand) return;
    fixtureIds.add(fixture.id);
    if (fixture.expectedAccepted) {
      acceptanceModes.add(_rushAcceptanceMode(fixture).name);
      return;
    }
    rejectionReasons.add(fixture.expectedReason!);
    final cause = _rushUnavailableCause(fixture);
    if (cause != null) unavailableCauses.add(cause.name);
  }
}

void _requireRushCorpusCoverage(_RushCorpusSummary summary, String family) {
  if (summary.fixtureIds.length != _requiredRushFixtureIds.length ||
      !summary.fixtureIds.containsAll(_requiredRushFixtureIds)) {
    throw StateError(
      '$family RushProduction fixture ids must be exactly: '
      '${_requiredRushFixtureIds.toList()..sort()}.',
    );
  }
  if (summary.rejectionReasons.length != _requiredRushRejectionReasons.length ||
      !summary.rejectionReasons.containsAll(_requiredRushRejectionReasons)) {
    throw StateError(
      '$family RushProduction rejection reasons must be exactly: '
      '${_requiredRushRejectionReasons.toList()..sort()}.',
    );
  }
  final requiredCauses = _RushUnavailableCause.values
      .map((cause) => cause.name)
      .toSet();
  if (summary.unavailableCauses.length != requiredCauses.length ||
      !summary.unavailableCauses.containsAll(requiredCauses)) {
    throw StateError(
      '$family RushProduction unavailable causes must be exactly: '
      '${requiredCauses.toList()..sort()}.',
    );
  }
  final requiredModes = _RushAcceptanceMode.values
      .map((mode) => mode.name)
      .toSet();
  if (summary.acceptanceModes.length != requiredModes.length ||
      !summary.acceptanceModes.containsAll(requiredModes)) {
    throw StateError(
      '$family RushProduction acceptance modes must be exactly: '
      '${requiredModes.toList()..sort()}.',
    );
  }
}

void _validateRushCharacterizationFixture(ReducerParityFixture fixture) {
  final command = fixture.command;
  if (command is! RushProductionCommand) return;
  _requireReviewedRushFixtureShape(fixture);

  final city = fixture.state.cities.byId(command.cityId);
  if (fixture.id == 'city-production-rush-not-found-rejected') {
    _validateRushNotFound(fixture, city);
    return;
  }
  if (city == null) {
    ReducerParityCorpus._fail(fixture, 'must target one existing rush city');
  }
  _validateExistingRushCharacterization(fixture, city);
}

void _validateRushNotFound(ReducerParityFixture fixture, GameCity? city) {
  if (city != null ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'city_not_found') {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize city_not_found before every later rush check',
    );
  }
}

void _validateExistingRushCharacterization(
  ReducerParityFixture fixture,
  GameCity city,
) {
  if (_isWrongActorRushFixture(fixture)) {
    _validateRushWrongActor(fixture, city);
    return;
  }
  if (city.ownerPlayerId != fixture.actorPlayerId) {
    ReducerParityCorpus._fail(
      fixture,
      'must target an actor-controlled rush city',
    );
  }

  final validator = _ownedRushFixtureValidators[fixture.id];
  (validator ?? _validateAcceptedRushMode)(fixture, city);
}

bool _isWrongActorRushFixture(ReducerParityFixture fixture) =>
    fixture.id == 'city-production-rush-wrong-actor-rejected' ||
    fixture.id == 'city-production-rush-wrong-actor-compound-rejected';

final _ownedRushFixtureValidators =
    <String, void Function(ReducerParityFixture, GameCity)>{
      'city-production-rush-empty-queue-rejected': _validateRushEmptyQueue,
      'city-production-rush-project-rejected': _validateRushProject,
      'city-production-rush-insufficient-gold-rejected':
          _validateRushUnavailable,
      'city-production-rush-complete-queue-rejected': _validateRushUnavailable,
    };

void _validateRushEmptyQueue(ReducerParityFixture fixture, GameCity city) {
  if (city.productionQueue != null ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'production_queue_empty') {
    ReducerParityCorpus._fail(
      fixture,
      'must isolate production_queue_empty before target checks',
    );
  }
}

void _validateRushProject(ReducerParityFixture fixture, GameCity city) {
  if (city.productionQueue?.target is! ProjectProductionTarget ||
      (fixture.state.playerGold[city.ownerPlayerId] ?? 0) != 0 ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'project_cannot_be_rushed') {
    ReducerParityCorpus._fail(
      fixture,
      'must isolate project_cannot_be_rushed before a zero-gold treasury',
    );
  }
}

void _requireReviewedRushFixtureShape(ReducerParityFixture fixture) {
  if (!_requiredRushFixtureIds.contains(fixture.id)) {
    ReducerParityCorpus._fail(
      fixture,
      'uses an unreviewed RushProduction characterization id',
    );
  }
  final state = fixture.state;
  if (state.cities.length < 2 ||
      state.cities.first.id != 'city_sentinel' ||
      state.units.isEmpty ||
      state.artifacts.isEmpty ||
      state.fieldImprovements.isEmpty ||
      state.research.players.isEmpty ||
      state.wonderRegistry.toJson().isEmpty ||
      state.runtimeState.turnStartedAt == null ||
      state.runtimeState.submittedPlayerIds.isEmpty ||
      state.runtimeState.resourceTradeAgreements.isEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve city, unit, artifact, improvement, research, registry, '
      'trade, and runtime sentinels',
    );
  }
}

void _validateRushWrongActor(ReducerParityFixture fixture, GameCity city) {
  if (city.ownerPlayerId == fixture.actorPlayerId ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'city_not_controlled') {
    ReducerParityCorpus._fail(
      fixture,
      'must characterize city_not_controlled before queue and gold checks',
    );
  }
  if (fixture.id == 'city-production-rush-wrong-actor-compound-rejected') {
    if (city.productionQueue != null ||
        (fixture.state.playerGold[city.ownerPlayerId] ?? 0) != 0) {
      ReducerParityCorpus._fail(
        fixture,
        'must keep the reviewed foreign empty queue and zero-gold compound mode',
      );
    }
    return;
  }

  final queue = city.productionQueue;
  if (queue == null || !CityProductionRules.canRush(queue.target)) {
    ReducerParityCorpus._fail(
      fixture,
      'must keep an otherwise rushable wrong-actor queue',
    );
  }
  final economics = _reviewedRushEconomics(fixture, city, queue);
  if (!economics.available) {
    ReducerParityCorpus._fail(
      fixture,
      'must keep sufficient progress and gold after the wrong-actor check',
    );
  }
}

void _validateRushUnavailable(ReducerParityFixture fixture, GameCity city) {
  final queue = city.productionQueue;
  if (queue == null || !CityProductionRules.canRush(queue.target)) {
    ReducerParityCorpus._fail(
      fixture,
      'must reach rush_production_unavailable with a rushable queue',
    );
  }
  final economics = _reviewedRushEconomics(fixture, city, queue);
  final cause = _rushUnavailableCause(fixture);
  final valid = switch (cause) {
    _RushUnavailableCause.insufficientGold =>
      economics.rushedProduction > 0 &&
          economics.rushCost > 0 &&
          economics.currentGold < economics.rushCost,
    _RushUnavailableCause.queueAlreadyComplete =>
      economics.rushedProduction == 0 && economics.rushCost == 0,
    null => false,
  };
  if (!valid ||
      fixture.expectedAccepted ||
      fixture.expectedReason != 'rush_production_unavailable') {
    ReducerParityCorpus._fail(
      fixture,
      'does not isolate its reviewed rush_production_unavailable cause',
    );
  }
}

void _validateAcceptedRushMode(ReducerParityFixture fixture, GameCity city) {
  if (!fixture.expectedAccepted || fixture.expectedReason != null) {
    ReducerParityCorpus._fail(fixture, 'must be an accepted rush fixture');
  }
  final queue = city.productionQueue;
  if (queue == null || !CityProductionRules.canRush(queue.target)) {
    ReducerParityCorpus._fail(fixture, 'must start with a rushable queue');
  }
  final economics = _reviewedRushEconomics(fixture, city, queue);
  if (!economics.available) {
    ReducerParityCorpus._fail(
      fixture,
      'must have positive progress and enough gold for the reviewed accept',
    );
  }
  final advanced = queue.advancedBy(economics.rushedProduction);
  final complete = advanced.isCompleteFor(
    CityRulesets.standard,
    wonderRuleset: WonderRuleset.standard,
    paceBalance: fixture.save.matchRules.paceBalance,
  );
  final mode = _rushAcceptanceMode(fixture);
  final valid = _rushAcceptanceValidators[mode]!(
    fixture,
    city,
    queue,
    complete,
  );
  if (!valid) {
    ReducerParityCorpus._fail(
      fixture,
      'does not isolate its reviewed RushProduction acceptance mode',
    );
  }
}

({int rushedProduction, int rushCost, int currentGold, bool available})
_reviewedRushEconomics(
  ReducerParityFixture fixture,
  GameCity city,
  CityProductionQueue queue,
) {
  final paceBalance = fixture.save.matchRules.paceBalance;
  final targetCost = CityProductionRules.targetCost(
    queue.target,
    ruleset: CityRulesets.standard,
    wonderRuleset: WonderRuleset.standard,
    paceBalance: paceBalance,
  );
  final productionPerTurn = reviewedRushProductionPerTurn(
    state: fixture.state,
    city: city,
    target: queue.target,
    mapTiles: fixture.mapData,
    paceBalance: paceBalance,
  );
  final rushedProduction = CityProductionRules.rushProductionAmount(
    productionCost: targetCost,
    investedProduction: queue.investedProduction,
    productionPerTurn: productionPerTurn,
  );
  final rushCost = CityProductionRules.rushGoldCost(
    productionCost: targetCost,
    investedProduction: queue.investedProduction,
    productionPerTurn: productionPerTurn,
  );
  final currentGold = fixture.state.playerGold[city.ownerPlayerId] ?? 0;
  return (
    rushedProduction: rushedProduction,
    rushCost: rushCost,
    currentGold: currentGold,
    available: rushedProduction > 0 && rushCost > 0 && currentGold >= rushCost,
  );
}

GameUnit? _reviewedRushProducedUnit(
  ReducerParityFixture fixture,
  GameCity city,
  CityProductionQueue queue,
) {
  final target = queue.target;
  if (target is! UnitProductionTarget) return null;
  return CityUnitProductionRules.produce(
    city: city,
    unitType: target.unitType,
    units: fixture.state.units,
    mapTiles: fixture.mapData,
  );
}

bool _hasReviewedGreatLibraryTechnology(
  ReducerParityFixture fixture,
  GameCity city,
) {
  final research = fixture.state.research.forPlayer(city.ownerPlayerId);
  return research.activeTechnologyId == TechnologyId.agriculture &&
      !research.hasUnlocked(TechnologyId.agriculture);
}

bool _hasReviewedGreatLibraryCompetitor(
  ReducerParityFixture fixture,
  GameCity city,
  CityProductionQueue queue,
) {
  final competitor = fixture.state.cities.byId('city_peer');
  return competitor != null &&
      competitor.id != city.id &&
      competitor.ownerPlayerId == city.ownerPlayerId &&
      competitor.productionQueue?.target == queue.target &&
      (competitor.productionQueue?.investedProduction ?? 0) > 0;
}

_RushUnavailableCause? _rushUnavailableCause(ReducerParityFixture fixture) {
  if (fixture.expectedReason != 'rush_production_unavailable') return null;
  return switch (fixture.id) {
    'city-production-rush-insufficient-gold-rejected' =>
      _RushUnavailableCause.insufficientGold,
    'city-production-rush-complete-queue-rejected' =>
      _RushUnavailableCause.queueAlreadyComplete,
    _ => throw StateError(
      '${fixture.id} uses rush_production_unavailable without a reviewed cause.',
    ),
  };
}

_RushAcceptanceMode _rushAcceptanceMode(ReducerParityFixture fixture) {
  return switch (fixture.id) {
    'city-production-rush-unrest-accepted' => _RushAcceptanceMode.partial,
    'city-production-rush-building-completed-accepted' =>
      _RushAcceptanceMode.buildingCompletion,
    'city-production-rush-unit-completed-accepted' =>
      _RushAcceptanceMode.unitCompletion,
    'city-production-rush-unit-spawn-blocked-accepted' =>
      _RushAcceptanceMode.blockedUnitCompletion,
    'city-production-rush-wonder-completed-accepted' =>
      _RushAcceptanceMode.wonderCompletion,
    'city-production-rush-wonder-precompleted-refund-accepted' =>
      _RushAcceptanceMode.completedWonderRefund,
    _ => throw StateError(
      '${fixture.id} uses an unreviewed accepted RushProduction mode.',
    ),
  };
}
