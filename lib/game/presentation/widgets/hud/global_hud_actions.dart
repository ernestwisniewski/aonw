import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/game/presentation/widgets/onboarding/first_turn_coachmark_targets.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';

List<Widget> buildMainGlobalHudActions({
  required AppLocalizations l10n,
  required bool technologyActive,
  String? activeTechnologyName,
  int? activeTechnologyTurnsRemaining,
  int? activeTechnologyCompletionTurn,
  bool researchAvailable = false,
  required bool objectivesAvailable,
  required bool objectivesActive,
  required bool empireActive,
  required VoidCallback onToggleTechnology,
  required VoidCallback onToggleObjectives,
  required VoidCallback onToggleEmpire,
}) {
  return [
    GlobalHudActionButton(
      actionId: 'deck.research',
      keyLabel: l10n.commonResearch,
      icon: GameIcons.science,
      active: technologyActive,
      tooltip: researchGlobalHudActionTooltip(
        technologyActive: technologyActive,
        activeTechnologyName: activeTechnologyName,
        activeTechnologyTurnsRemaining: activeTechnologyTurnsRemaining,
        activeTechnologyCompletionTurn: activeTechnologyCompletionTurn,
        researchAvailable: researchAvailable,
        l10n: l10n,
      ),
      coachmarkKey: FirstTurnCoachmarkTargets.research,
      onPressed: onToggleTechnology,
    ),
    if (objectivesAvailable)
      GlobalHudActionButton(
        actionId: 'objectives',
        keyLabel: l10n.objectivesPanelTitle,
        icon: GameIcons.checkCircle,
        active: objectivesActive,
        tooltip: objectivesActive
            ? l10n.objectivesCloseTooltip
            : l10n.objectivesPanelTitle,
        onPressed: onToggleObjectives,
      ),
    GlobalHudActionButton(
      actionId: 'deck.empire',
      keyLabel: l10n.commonEmpire,
      icon: GameIcons.cityFilled,
      active: empireActive,
      tooltip: l10n.commonEmpire,
      onPressed: onToggleEmpire,
    ),
  ];
}

List<Widget> buildDeckGlobalHudActions({
  required AppLocalizations l10n,
  required bool useBottomGlobalActions,
  required bool canShowGlobalActions,
  required bool technologyActive,
  required String? activeTechnologyName,
  required int? activeTechnologyTurnsRemaining,
  int? activeTechnologyCompletionTurn,
  required bool researchAvailable,
  required bool objectivesAvailable,
  required bool objectivesActive,
  required bool empireActive,
  required bool activityLogAvailable,
  required bool activityLogActive,
  required VoidCallback onToggleTechnology,
  required VoidCallback onToggleObjectives,
  required VoidCallback onToggleEmpire,
  required VoidCallback onToggleActivityLog,
}) {
  if (!useBottomGlobalActions) return const <Widget>[];
  if (!canShowGlobalActions) return const <Widget>[];

  return [
    GlobalHudActionButton(
      actionId: 'research',
      keyLabel: l10n.commonResearch,
      icon: GameIcons.science,
      active: technologyActive,
      tooltip: researchGlobalHudActionTooltip(
        technologyActive: technologyActive,
        activeTechnologyName: activeTechnologyName,
        activeTechnologyTurnsRemaining: activeTechnologyTurnsRemaining,
        activeTechnologyCompletionTurn: activeTechnologyCompletionTurn,
        researchAvailable: researchAvailable,
        l10n: l10n,
      ),
      coachmarkKey: FirstTurnCoachmarkTargets.research,
      onPressed: onToggleTechnology,
    ),
    GlobalHudActionButton(
      actionId: 'empire',
      keyLabel: l10n.commonEmpire,
      icon: GameIcons.cityFilled,
      active: empireActive,
      tooltip: l10n.commonEmpire,
      onPressed: onToggleEmpire,
    ),
  ];
}

String researchGlobalHudActionTooltip({
  required AppLocalizations l10n,
  required bool technologyActive,
  required String? activeTechnologyName,
  required int? activeTechnologyTurnsRemaining,
  required int? activeTechnologyCompletionTurn,
  required bool researchAvailable,
}) {
  if (technologyActive) return l10n.globalHudCloseResearch;
  if (activeTechnologyName != null) {
    if (activeTechnologyTurnsRemaining != null) {
      final eta = TurnEtaFormatter.fromTurns(
        turnsRemaining: activeTechnologyTurnsRemaining,
        completionTurn: activeTechnologyCompletionTurn,
      );
      return l10n.globalHudResearchActiveWithEta(
        activeTechnologyName,
        eta.detailLabel(l10n),
      );
    }
    return l10n.globalHudResearchActive(activeTechnologyName);
  }
  if (researchAvailable) return l10n.globalHudChooseResearch;
  return l10n.commonResearch;
}

class GlobalHudActionRail extends StatelessWidget {
  const GlobalHudActionRail({
    required this.children,
    this.axis = Axis.horizontal,
    this.dense = false,
    super.key,
  });

  final List<Widget> children;
  final Axis axis;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final vertical = axis == Axis.vertical;

    return ConstrainedBox(
      constraints: vertical
          ? const BoxConstraints(maxHeight: 260)
          : const BoxConstraints(maxWidth: 360),
      child: SingleChildScrollView(
        scrollDirection: axis,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 0),
          child: Flex(
            direction: axis,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  SizedBox(
                    width: vertical ? 0 : (dense ? 4 : 8),
                    height: vertical ? (dense ? 4 : 8) : 0,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GlobalHudActionButton extends StatelessWidget {
  const GlobalHudActionButton({
    required this.actionId,
    required this.keyLabel,
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onPressed,
    this.actionKey,
    this.coachmarkKey,
    super.key,
  });

  final String actionId;
  final String keyLabel;
  final GameIconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onPressed;
  final Key? actionKey;
  final Key? coachmarkKey;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? GameUiTheme.bg : GameUiTheme.goldLight;
    final surface = active ? SurfaceElevation.modal : SurfaceElevation.flat;
    final iconTile = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: surface.decoration(
        accent: GameUiTheme.gold,
        background: active ? GameUiTheme.gold : null,
        borderColor: active ? GameUiTheme.goldLight : null,
        border: active ? BorderEmphasis.active : BorderEmphasis.regular,
        borderWidth: active ? 1.6 : 1,
        shape: SurfaceShape.button,
      ),
      child: GameIcon(icon, size: GameIconSize.regular, color: foreground),
    );

    final button = Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: active,
        label: keyLabel,
        child: Material(
          key: actionKey ?? Key('globalHud.action.$actionId'),
          color: Colors.transparent,
          borderRadius: GameUiTheme.buttonBorderRadius,
          child: InkWell(
            borderRadius: GameUiTheme.buttonBorderRadius,
            onTap: onPressed,
            child: iconTile,
          ),
        ),
      ),
    );
    if (coachmarkKey == null) return button;
    return KeyedSubtree(key: coachmarkKey, child: button);
  }
}
