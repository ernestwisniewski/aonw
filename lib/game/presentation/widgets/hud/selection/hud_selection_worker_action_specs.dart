import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models/worker_action_panel_view_model.dart';
import 'package:aonw/game/presentation/widgets/hud/selection/hud_selection_action_spec.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/widgets.dart';

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
