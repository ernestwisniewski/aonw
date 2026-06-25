import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_models.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class WorkerImprovementOptionsViewModelFactory {
  static List<WorkerImprovementOptionViewModel> from({
    required GameUnit unit,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapData mapData,
    required ResearchState research,
    required bool selectionActive,
    required FieldImprovementType? selectedImprovementType,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required AppLocalizations l10n,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final tile = mapData.tileAt(unit.col, unit.row);

    final raw =
        <
          ({
            FieldImprovementType type,
            WorkerImprovementLegality actionLegality,
            WorkerImprovementLegality displayLegality,
            int score,
          })
        >[];

    for (final type in FieldImprovementType.values) {
      final tileLegality = WorkerImprovementRules.evaluate(
        unit: unit,
        improvementType: type,
        cities: cities,
        fieldImprovements: fieldImprovements,
        mapData: mapData,
        research: research,
        requireReadyWorker: false,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
      );
      if (!_shouldShowOption(tileLegality)) continue;

      final actionLegality = WorkerImprovementRules.evaluate(
        unit: unit,
        improvementType: type,
        cities: cities,
        fieldImprovements: fieldImprovements,
        mapData: mapData,
        research: research,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
      );
      raw.add((
        type: type,
        actionLegality: actionLegality,
        displayLegality: _displayLegalityFor(
          tileLegality: tileLegality,
          actionLegality: actionLegality,
        ),
        score: WorkerImprovementScoring.scoreFor(
          type: type,
          tile: tile,
          ruleset: cityRuleset,
        ),
      ));
    }

    final recommendedType =
        raw.where((entry) => entry.actionLegality.allowed).toList()
          ..sort((a, b) {
            final score = b.score.compareTo(a.score);
            if (score != 0) return score;
            return a.type.index.compareTo(b.type.index);
          });

    return [
      for (final entry in raw)
        WorkerImprovementOptionViewModel(
          improvementType: entry.type,
          title: GameDisplayNames.fieldImprovement(l10n, entry.type),
          yield: FieldImprovementRules.yieldFor(
            entry.type,
            ruleset: cityRuleset,
          ),
          buildTurns: FieldImprovementRules.buildTurnsFor(
            entry.type,
            ruleset: cityRuleset,
            paceBalance: paceBalance,
          ),
          state: _stateFor(
            type: entry.type,
            legality: entry.displayLegality,
            selectedImprovementType: selectedImprovementType,
            recommendedType: recommendedType.firstOrNull?.type,
          ),
          reason: _reasonFor(
            type: entry.type,
            legality: entry.displayLegality,
            cityRuleset: cityRuleset,
            l10n: l10n,
          ),
          canSelect:
              selectionActive &&
              entry.actionLegality.allowed &&
              !unit.isWorking,
          score: entry.score,
        ),
    ]..sort((a, b) {
      final state = _statePriority(a.state).compareTo(_statePriority(b.state));
      if (state != 0) return state;
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.improvementType.index.compareTo(b.improvementType.index);
    });
  }

  static bool _shouldShowOption(WorkerImprovementLegality tileLegality) {
    return tileLegality.allowed ||
        tileLegality.blocker == WorkerImprovementBlocker.technologyLocked;
  }

  static WorkerImprovementLegality _displayLegalityFor({
    required WorkerImprovementLegality tileLegality,
    required WorkerImprovementLegality actionLegality,
  }) {
    if (tileLegality.blocker == WorkerImprovementBlocker.technologyLocked) {
      return tileLegality;
    }
    return actionLegality;
  }

  static WorkerImprovementOptionState _stateFor({
    required FieldImprovementType type,
    required WorkerImprovementLegality legality,
    required FieldImprovementType? selectedImprovementType,
    required FieldImprovementType? recommendedType,
  }) {
    if (!legality.allowed) return WorkerImprovementOptionState.blocked;
    if (selectedImprovementType == type) {
      return WorkerImprovementOptionState.selected;
    }
    if (recommendedType == type) {
      return WorkerImprovementOptionState.recommended;
    }
    return WorkerImprovementOptionState.available;
  }

  static String _reasonFor({
    required FieldImprovementType type,
    required WorkerImprovementLegality legality,
    required CityRuleset cityRuleset,
    required AppLocalizations l10n,
  }) {
    if (legality.allowed) {
      final yield = FieldImprovementRules.yieldFor(type, ruleset: cityRuleset);
      final parts = <String>[];
      if (yield.food > 0) {
        parts.add(l10n.workerImprovementYieldFood(yield.food));
      }
      if (yield.production > 0) {
        parts.add(l10n.workerImprovementYieldProduction(yield.production));
      }
      if (yield.gold > 0) {
        parts.add(l10n.workerImprovementYieldGold(yield.gold));
      }
      if (yield.defense > 0) {
        parts.add(l10n.workerImprovementYieldDefense(yield.defense));
      }
      if (parts.isEmpty) return l10n.workerImprovementNoBonus;
      return parts.join(' • ');
    }

    return switch (legality.blocker) {
      WorkerImprovementBlocker.notWorker => l10n.workerImprovementOnlyWorker,
      WorkerImprovementBlocker.workerBusy => l10n.workerImprovementWorkerBusy,
      WorkerImprovementBlocker.noMovementPoints =>
        l10n.selectionActionNoMovement,
      WorkerImprovementBlocker.queuedPathActive =>
        l10n.workerImprovementStopQueuedMove,
      WorkerImprovementBlocker.missingTile => l10n.workerImprovementMissingTile,
      WorkerImprovementBlocker.cityCenter =>
        l10n.selectionActionCannotImproveCityCenter,
      WorkerImprovementBlocker.outsideOwnedTerritory =>
        l10n.selectionActionTileMustBelongToCity,
      WorkerImprovementBlocker.existingImprovement =>
        l10n.selectionActionTileAlreadyImproved,
      WorkerImprovementBlocker.technologyLocked =>
        legality.requiredTechnology == null
            ? l10n.requirementTechnology
            : l10n.requirementTechnologyName(
                GameDisplayNames.technology(
                  l10n,
                  legality.requiredTechnology!.id,
                ),
              ),
      WorkerImprovementBlocker.missingResource =>
        l10n.workerImprovementMissingResource,
      WorkerImprovementBlocker.invalidTerrain =>
        l10n.workerImprovementInvalidTerrain,
      WorkerImprovementBlocker.missingRiver =>
        l10n.workerImprovementMissingRiver,
      null => l10n.workerImprovementBlocked,
    };
  }

  static int _statePriority(WorkerImprovementOptionState state) =>
      switch (state) {
        WorkerImprovementOptionState.selected => 0,
        WorkerImprovementOptionState.recommended => 1,
        WorkerImprovementOptionState.available => 2,
        WorkerImprovementOptionState.blocked => 3,
      };
}
