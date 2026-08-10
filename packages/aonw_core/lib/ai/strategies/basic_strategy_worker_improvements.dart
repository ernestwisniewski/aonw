part of 'basic_strategy_worker_planner.dart';

extension _BasicStrategyWorkerImprovements on BasicStrategyWorkerPlanner {
  bool _canBuildWorkerImprovementAt({
    required GameUnit worker,
    required GameView view,
    required FieldImprovementType improvementType,
    required CityHex targetHex,
    bool requireReadyWorker = true,
    ResearchState? research,
  }) {
    return WorkerImprovementRules.evaluate(
      unit: worker,
      improvementType: improvementType,
      cities: view.ownCities,
      fieldImprovements: view.ownImprovements,
      mapTiles: view.mapData,
      research: research ?? _researchFor(view),
      targetHex: targetHex,
      requireReadyWorker: requireReadyWorker,
      cityRuleset: view.ruleset.city,
      technologyRuleset: view.ruleset.technology,
    ).allowed;
  }

  bool _canAssignWorker(GameUnit worker, GameView view) {
    return _canAssignWorkerAt(
      worker,
      view,
      CityHex(col: worker.col, row: worker.row),
    );
  }

  bool _canAssignWorkerAt(
    GameUnit worker,
    GameView view,
    CityHex targetHex, {
    bool requireReadyWorker = true,
  }) {
    return WorkerAssignmentRules.evaluate(
      unit: worker,
      cities: view.ownCities,
      fieldImprovements: view.ownImprovements,
      units: view.ownUnits,
      mapTiles: view.mapData,
      targetHex: targetHex,
      requireReadyWorker: requireReadyWorker,
    ).allowed;
  }

  DomainCommand? _currentWorkerImprovement({
    required GameUnit worker,
    required GameView view,
  }) {
    final improvement = _bestImprovementFor(
      worker: worker,
      hex: CityHex(col: worker.col, row: worker.row),
      view: view,
    );
    return improvement == null
        ? null
        : SelectWorkerImprovementCommand(worker.id, improvement.type);
  }

  _WorkerImprovementOption? _bestImprovementFor({
    required GameUnit worker,
    required CityHex hex,
    required GameView view,
  }) {
    final tile = view.mapData.tileAt(hex.col, hex.row);
    if (tile == null) return null;

    final research = _researchFor(view);
    final options =
        view.ruleset.city.improvements.keys
            .map(
              (type) => _improvementOptionFor(
                worker: worker,
                view: view,
                tile: tile,
                hex: hex,
                type: type,
                research: research,
              ),
            )
            .whereType<_WorkerImprovementOption>()
            .toList()
          ..sort(_compareWorkerImprovementOptions);

    return options.isEmpty ? null : options.first;
  }

  _WorkerImprovementOption? _improvementOptionFor({
    required GameUnit worker,
    required GameView view,
    required MapTileView tile,
    required CityHex hex,
    required FieldImprovementType type,
    required ResearchState research,
  }) {
    if (!_canBuildWorkerImprovementAt(
      worker: worker,
      view: view,
      improvementType: type,
      targetHex: hex,
      research: research,
    )) {
      return null;
    }

    return _WorkerImprovementOption(
      type: type,
      score: WorkerImprovementScoring.scoreFor(
        type: type,
        tile: tile,
        ruleset: view.ruleset.city,
      ).toDouble(),
      buildTurns: FieldImprovementRules.buildTurnsFor(
        type,
        ruleset: view.ruleset.city,
        paceBalance: view.ruleset.paceBalance,
      ),
    );
  }

  int _compareWorkerImprovementOptions(
    _WorkerImprovementOption a,
    _WorkerImprovementOption b,
  ) {
    return _firstNonZero([
      b.score.compareTo(a.score),
      a.buildTurns.compareTo(b.buildTurns),
      a.type.name.compareTo(b.type.name),
    ]);
  }

  int _firstNonZero(Iterable<int> comparisons) {
    for (final comparison in comparisons) {
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  ResearchState _researchFor(GameView view) {
    return ResearchState(players: {view.forPlayerId: view.ownResearch});
  }
}

final class _WorkerImprovementOption {
  const _WorkerImprovementOption({
    required this.type,
    required this.score,
    required this.buildTurns,
  });

  final FieldImprovementType type;
  final double score;
  final int buildTurns;
}
