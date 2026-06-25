import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/technology_tree_labels.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/technology_sprite_catalog.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

part 'technology_tree_node_chrome.dart';
part 'technology_tree_node_unlocks.dart';

class TechnologyTreeNode extends StatelessWidget {
  const TechnologyTreeNode({
    required this.card,
    required this.l10n,
    required this.selected,
    required this.inSelectedPath,
    required this.onSelected,
    required this.onDetails,
    required this.showUnlockDetails,
    required this.onBuildingDetails,
    required this.onUnitDetails,
    required this.onResearch,
    super.key,
  });

  final TechnologyCardViewModel card;
  final AppLocalizations l10n;
  final bool selected;
  final bool inSelectedPath;
  final VoidCallback onSelected;
  final VoidCallback onDetails;
  final bool showUnlockDetails;
  final ValueChanged<CityBuildingType> onBuildingDetails;
  final ValueChanged<GameUnitType> onUnitDetails;
  final VoidCallback? onResearch;

  @override
  Widget build(BuildContext context) {
    final colors = _TechnologyNodeColors.forState(card.state);
    final name = GameDisplayNames.technology(l10n, card.id);
    final era = GameDisplayNames.technologyEra(l10n, card.era);
    final unlocks = TechnologyTreeLabels.unlocksLabel(l10n, card);
    final borderColor = selected
        ? GameUiTheme.scienceAccent
        : inSelectedPath
        ? GameUiTheme.gold
        : colors.border;
    final borderWidth = selected
        ? 2.2
        : inSelectedPath
        ? 1.7
        : 1.2;

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: SurfaceElevation.flat.decoration(
            borderRadius: BorderRadius.circular(7),
            borderColor: borderColor,
            border: BorderEmphasis.active,
            borderWidth: borderWidth,
            includeShadow: false,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: SurfaceElevation.flat.fill(
                        background: GameUiTheme.scienceAccent,
                        alpha: 102,
                      ),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : inSelectedPath
                ? const [
                    BoxShadow(
                      color: Color(0x33C8A95B),
                      blurRadius: 11,
                      spreadRadius: 1,
                    ),
                  ]
                : card.state == TechnologyCardState.active
                ? [
                    BoxShadow(
                      color: SurfaceElevation.flat.fill(
                        background: GameUiTheme.scienceAccent,
                        alpha: 51,
                      ),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TechnologySpriteIcon(id: card.id, size: 36),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.bodyStrong.copyWith(
                        color: colors.title,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (card.boostActive)
                    const GameIcon(
                      GameIcons.lightning,
                      size: GameIconSize.small,
                      color: GameUiTheme.gold,
                    ),
                  const SizedBox(width: 3),
                  _TechnologyHelpButton(l10n: l10n, onPressed: onDetails),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      GameText.uppercase(era),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.toolbarLabel.copyWith(
                        color: colors.subtitle,
                        fontSize: 8.5,
                      ),
                    ),
                  ),
                  Text(
                    '${card.progress}/${card.totalCost}',
                    style: GameUiTheme.bodySmall.copyWith(
                      color: colors.subtitle,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: card.progressRatio,
                  minHeight: 4,
                  backgroundColor: SurfaceElevation.flat.fill(
                    background: GameUiTheme.bg,
                    alpha: 180,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.progress),
                ),
              ),
              const SizedBox(height: 5),
              _TechnologyUnlockSummary(
                card: card,
                l10n: l10n,
                unlocksLabel: unlocks,
                showDetails: showUnlockDetails,
                onBuildingDetails: onBuildingDetails,
                onUnitDetails: onUnitDetails,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      TechnologyTreeLabels.stateLabel(l10n, card),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: colors.subtitle,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 26,
                    child: TextButton(
                      onPressed: onResearch,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        backgroundColor: onResearch == null
                            ? SurfaceElevation.flat.fill(
                                background: Colors.white,
                                alpha: 12,
                              )
                            : colors.action,
                        foregroundColor: onResearch == null
                            ? GameUiTheme.textTertiary
                            : Colors.white,
                        disabledForegroundColor: GameUiTheme.textTertiary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Text(
                        TechnologyTreeLabels.buttonLabel(l10n, card.state),
                        style: const TextStyle(
                          fontFamily: GameUiTheme.headingFont,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
