import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_action_spec.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_road_action_spec.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/widgets.dart';

List<HudSelectionActionSpec> workerActionGroup({
  required GameUnit unit,
  required GameClientState? gameState,
  required WorldMap mapData,
  required WorkerActionPanelViewModel? workerAction,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onStartWorkerActionSelection,
  required VoidCallback onCancelWorkerActionSelection,
  required VoidCallback onCancelWorkerJob,
  required VoidCallback onBuildRoad,
  required VoidCallback onAutomateSelectedWorker,
}) => [
  _workerBuildAction(
    unit,
    gameState,
    workerAction,
    lockedReason,
    l10n,
    onStartWorkerActionSelection,
    onCancelWorkerActionSelection,
    onCancelWorkerJob,
  ),
  workerRoadActionFor(
    unit,
    gameState,
    mapData,
    lockedReason,
    l10n,
    onBuildRoad,
  ),
  workerAutoAction(unit, lockedReason, l10n, onAutomateSelectedWorker),
];

HudSelectionActionSpec _workerBuildAction(
  GameUnit unit,
  GameClientState? gameState,
  WorkerActionPanelViewModel? workerAction,
  String? lockedReason,
  AppLocalizations l10n,
  VoidCallback onStartWorkerActionSelection,
  VoidCallback onCancelWorkerActionSelection,
  VoidCallback onCancelWorkerJob,
) {
  final state = _workerBuildState(unit, gameState, workerAction);
  final needsGuidance = _workerBuildNeedsGuidance(state, lockedReason);

  return HudSelectionActionSpec(
    icon: GameIcons.production,
    actionId: 'improve',
    label: l10n.selectionActionImprove,
    color: GameUiTheme.success,
    active: state.active,
    enabled: _workerBuildEnabled(state, lockedReason),
    dangerOutlined: state.active,
    prominent: needsGuidance,
    pulseBorder: needsGuidance,
    disabledReason: _workerBuildDisabledReason(
      state: state,
      unit: unit,
      workerAction: workerAction,
      lockedReason: lockedReason,
      l10n: l10n,
    ),
    onTap: _workerBuildCallback(
      state,
      onStartWorkerActionSelection,
      onCancelWorkerActionSelection,
      onCancelWorkerJob,
    ),
  );
}

typedef _WorkerBuildState = ({
  bool active,
  bool canStart,
  bool jobActive,
  bool selectionActive,
});

_WorkerBuildState _workerBuildState(
  GameUnit unit,
  GameClientState? gameState,
  WorkerActionPanelViewModel? workerAction,
) {
  final pending = gameState?.pendingAction;
  final selectionActive =
      pending is PendingWorkerActionSelection && pending.unitId == unit.id;
  final jobActive = workerAction?.hasActiveJob ?? unit.workerJob != null;
  return (
    active: selectionActive || jobActive,
    canStart: _canStartWorkerBuild(unit, workerAction),
    jobActive: jobActive,
    selectionActive: selectionActive,
  );
}

bool _canStartWorkerBuild(
  GameUnit unit,
  WorkerActionPanelViewModel? workerAction,
) =>
    unit.movementPoints > 0 &&
    !unit.isWorking &&
    !unit.isFortified &&
    unit.queuedPath == null &&
    (workerAction?.canStartSelection ?? true);

bool _workerBuildNeedsGuidance(_WorkerBuildState state, String? lockedReason) =>
    !state.active && state.canStart && lockedReason == null;

bool _workerBuildEnabled(_WorkerBuildState state, String? lockedReason) =>
    (state.active || state.canStart) && lockedReason == null;

String? _workerBuildDisabledReason({
  required _WorkerBuildState state,
  required GameUnit unit,
  required WorkerActionPanelViewModel? workerAction,
  required String? lockedReason,
  required AppLocalizations l10n,
}) {
  if (lockedReason != null || state.active) return lockedReason;
  if (unit.queuedPath != null) {
    return l10n.selectionActionCancelCurrentMoveFirst;
  }
  return _workerTurnBlockedReason(l10n, unit) ??
      workerAction?.buildBlockedReason ??
      l10n.selectionActionNoBuildAvailable;
}

VoidCallback _workerBuildCallback(
  _WorkerBuildState state,
  VoidCallback onStart,
  VoidCallback onCancelSelection,
  VoidCallback onCancelJob,
) {
  if (state.jobActive) return onCancelJob;
  return state.selectionActive ? onCancelSelection : onStart;
}

HudSelectionActionSpec workerAutoAction(
  GameUnit unit,
  String? lockedReason,
  AppLocalizations l10n,
  VoidCallback onTap,
) {
  final available = unit.isReadyToAct && !unit.isFortified;
  return HudSelectionActionSpec(
    icon: gameAutoWorkIcon,
    actionId: 'autoWork',
    label: l10n.selectionActionAutoWork,
    color: GameUiTheme.info,
    enabled: available && lockedReason == null,
    disabledReason:
        lockedReason ??
        (unit.queuedPath != null
            ? l10n.selectionActionCancelCurrentMoveFirst
            : _workerTurnBlockedReason(l10n, unit)),
    onTap: onTap,
  );
}

String? _workerTurnBlockedReason(AppLocalizations l10n, GameUnit unit) {
  if (unit.isWorking) return l10n.selectionActionUnitWorking;
  if (unit.isFortified) {
    return UnitFortificationRules.canHeal(unit)
        ? l10n.selectionActionUnitHealing
        : l10n.selectionActionUnitFortified;
  }
  return unit.movementPoints <= 0 ? l10n.selectionActionNoMovement : null;
}

HudSelectionActionSpec? activeWorkerModeActionSpec({
  required GameUnit unit,
  required WorkerActionPanelViewModel? workerAction,
  required String? lockedReason,
  required AppLocalizations l10n,
  required VoidCallback onCancelWorkerJob,
  required VoidCallback onCancelWorkerAssignment,
  required VoidCallback onCancelUnitAction,
}) {
  if (!unit.isWorker) return null;
  late final String label;
  late final VoidCallback onTap;
  if (unit.isAutoWorking) {
    label = l10n.selectionActionCancelAutoWork;
    onTap = onCancelUnitAction;
  } else if (workerAction?.hasActiveJob ?? unit.workerJob != null) {
    label = l10n.selectionActionCancelWorkerBuild;
    onTap = onCancelWorkerJob;
  } else if (unit.workerAssignment != null) {
    label = l10n.selectionActionEndWorkerAssignment;
    onTap = onCancelWorkerAssignment;
  } else {
    return null;
  }
  return HudSelectionActionSpec(
    icon: GameIcons.close,
    actionId: 'cancel',
    label: label,
    color: GameUiTheme.danger,
    active: true,
    showLabel: true,
    dangerOutlined: true,
    enabled: lockedReason == null,
    disabledReason: lockedReason,
    onTap: onTap,
  );
}
