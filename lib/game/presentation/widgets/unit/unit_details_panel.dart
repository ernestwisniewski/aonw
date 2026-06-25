import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/visual/game_insight_widgets.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_content_scroll_view.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_layout.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

GameIconData gameIconForUnitType(GameUnitType type) => switch (type) {
  GameUnitType.warrior => GameIcons.warrior,
  GameUnitType.archer => GameIcons.archer,
  GameUnitType.settler => GameIcons.settler,
  GameUnitType.worker => GameIcons.production,
  GameUnitType.merchant => GameIcons.commerce,
  GameUnitType.commander => GameIcons.army,
  GameUnitType.scout => GameIcons.visibility,
  GameUnitType.spearman => GameIcons.attack,
  GameUnitType.cavalry => GameIcons.move,
  GameUnitType.catapult => GameIcons.production,
  GameUnitType.heavyInfantry => GameIcons.defense,
  GameUnitType.fieldCannon => GameIcons.attack,
  GameUnitType.rifleman => GameIcons.archer,
  GameUnitType.tank => GameIcons.defense,
  GameUnitType.scoutShip => GameIcons.visibility,
  GameUnitType.warship => GameIcons.attack,
  GameUnitType.reconPlane => GameIcons.visibility,
};

class UnitDetailsPanel extends StatelessWidget {
  final GameUnitType unitType;
  final TechnologyDefinition? unlockingTechnology;
  final AppLocalizations l10n;
  final String title;
  final GameIconData icon;
  final String statusLabel;
  final String? costLabel;
  final String? progressLabel;
  final String? paceLabel;
  final double maxWidth;
  final double? maxHeight;
  final VoidCallback onClose;

  const UnitDetailsPanel({
    required this.unitType,
    required this.unlockingTechnology,
    required this.l10n,
    required this.title,
    required this.icon,
    required this.statusLabel,
    this.costLabel,
    this.progressLabel,
    this.paceLabel,
    this.maxWidth = 560,
    this.maxHeight,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final movement = UnitMovementBalance.maxMovementPointsForType(unitType);
    final combatStats = CombatRuleset.standard.baseStatsFor(unitType);
    final effectiveMaxHeight = GameModalLayout.detailsMaxHeight(maxHeight);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: effectiveMaxHeight,
      ),
      child: GameModalScaffold(
        surfaceKey: const Key('unitDetailsPanel.surface'),
        showCornerDiamonds: false,
        contentPadding: EdgeInsets.zero,
        centerInAvailableSpace: false,
        scrollable: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UnitDetailsHeader(
              unitType: unitType,
              title: title,
              icon: icon,
              l10n: l10n,
              onClose: onClose,
            ),
            Flexible(
              child: GameModalContentScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  Text(
                    GameDisplayNames.unitDescription(l10n, unitType),
                    style: GameUiTheme.body.copyWith(
                      color: GameUiTheme.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _UnitDetailChip(
                        label: l10n.technologyDetailsStatus,
                        value: statusLabel,
                      ),
                      if (costLabel != null)
                        _UnitDetailChip(
                          label: l10n.technologyDetailsCost,
                          value: costLabel!,
                        ),
                      _UnitDetailChip(
                        label: l10n.unitDetailsMovement,
                        value: l10n.unitDetailsMovementPerTurn(movement),
                      ),
                      if (progressLabel != null)
                        _UnitDetailChip(
                          label: l10n.technologyDetailsProgress,
                          value: progressLabel!,
                        ),
                      if (paceLabel != null)
                        _UnitDetailChip(
                          label: l10n.unitDetailsPace,
                          value: paceLabel!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GameStatBarGroup(
                    title: l10n.unitDetailsCombat,
                    accent: GameUiTheme.gold,
                    items: [
                      GameStatBarItem(
                        icon: GameIcons.attack,
                        label: l10n.eventCombatStatAttack,
                        value: combatStats.attack,
                        color: GameUiTheme.danger,
                      ),
                      GameStatBarItem(
                        icon: GameIcons.defense,
                        label: l10n.eventCombatStatDefense,
                        value: combatStats.defense,
                        color: GameUiTheme.info,
                      ),
                      GameStatBarItem(
                        icon: GameIcons.checkCircle,
                        label: l10n.eventCombatStatHp,
                        value: combatStats.hp,
                        color: GameUiTheme.success,
                      ),
                      GameStatBarItem(
                        icon: GameIcons.visibility,
                        label: l10n.eventCombatStatRange,
                        value: combatStats.range,
                        color: GameUiTheme.scienceAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _UnitDetailsSection(
                    title: l10n.technologyDetailsPrerequisites,
                    lines: _requirementLines(l10n),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _requirementLines(AppLocalizations l10n) {
    if (unlockingTechnology == null) {
      return [l10n.buildingDetailsNoRequirements];
    }
    return [
      l10n.unitDetailsRequirementTechnology(
        GameDisplayNames.technology(l10n, unlockingTechnology!.id),
      ),
    ];
  }
}

class _UnitDetailsHeader extends StatelessWidget {
  final GameUnitType unitType;
  final String title;
  final GameIconData icon;
  final AppLocalizations l10n;
  final VoidCallback onClose;

  const _UnitDetailsHeader({
    required this.unitType,
    required this.title,
    required this.icon,
    required this.l10n,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
      decoration: SurfaceElevation.raised.bandDecoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 225,
        border: BorderEmphasis.regular,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: SurfaceElevation.flat.decoration(
              background: GameUiTheme.gold,
              backgroundAlpha: 24,
              border: BorderEmphasis.regular,
              borderRadius: BorderRadius.circular(6),
              includeShadow: false,
            ),
            child: Center(
              child: UnitSpriteIcon(
                type: unitType,
                size: 30,
                fallback: GameIcon(
                  icon,
                  size: GameIconSize.regular,
                  color: GameUiTheme.goldLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GameUiEpicHeader(
                  label: title,
                  alignment: Alignment.centerLeft,
                  compact: false,
                  textKey: const Key('unitDetailsHeader.title'),
                ),
                const SizedBox(height: 2),
                Text(
                  GameText.uppercase(l10n.productionCategoryUnit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.closeAction,
            onPressed: onClose,
            icon: const GameIcon(
              GameIcons.close,
              size: GameIconSize.regular,
              color: GameUiTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitDetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _UnitDetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.bg,
        backgroundAlpha: 120,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              GameText.uppercase(label),
              style: GameUiTheme.toolbarLabel.copyWith(
                color: GameUiTheme.textMuted,
                fontSize: 8.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitDetailsSection extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _UnitDetailsSection({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GameText.uppercase(title),
            style: GameUiTheme.toolbarLabel.copyWith(
              color: GameUiTheme.scienceAccent,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $line',
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textPrimary,
                  height: 1.25,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
