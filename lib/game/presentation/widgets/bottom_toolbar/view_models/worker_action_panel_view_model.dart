import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_models.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_improvement_options_view_model_factory.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

export 'worker_action_panel_models.dart';

abstract final class WorkerActionPanelViewModelFactory {
  static WorkerActionPanelViewModel from({
    required GameUnit unit,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapData mapData,
    required ResearchState research,
    required PendingPlayerAction? pendingAction,
    required AppLocalizations l10n,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    final selectionActive =
        pendingAction is PendingWorkerActionSelection &&
        pendingAction.unitId == unit.id;
    final selectedImprovementType = selectionActive
        ? pendingAction.improvementType
        : null;
    final options = WorkerImprovementOptionsViewModelFactory.from(
      unit: unit,
      cities: cities,
      fieldImprovements: fieldImprovements,
      mapData: mapData,
      research: research,
      selectionActive: selectionActive,
      selectedImprovementType: selectedImprovementType,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
      l10n: l10n,
    );

    return WorkerActionPanelViewModel(
      unitId: unit.id,
      unitName: GameDisplayNames.unitType(l10n, unit.type),
      currentHex: CityHex(col: unit.col, row: unit.row),
      movementPoints: unit.movementPoints,
      selectionActive: selectionActive,
      selectedImprovementType: selectedImprovementType,
      activeJob: unit.workerJob == null
          ? null
          : WorkerJobProgressViewModel(
              improvementType: unit.workerJob!.improvementType,
              improvementName: GameDisplayNames.fieldImprovement(
                l10n,
                unit.workerJob!.improvementType,
              ),
              targetHex: unit.workerJob!.targetHex,
              remainingTurns: unit.workerJob!.remainingTurns,
              totalTurns: unit.workerJob!.totalTurns,
            ),
      options: options,
      buildUnavailableReason: l10n.selectionActionNoBuildAvailable,
    );
  }
}
