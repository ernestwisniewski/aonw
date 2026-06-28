import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/technology_tree_labels.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_sprite_icon.dart';
import 'package:aonw/game/presentation/widgets/theme/unit_type_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class TechnologyUnlocksSection extends StatelessWidget {
  const TechnologyUnlocksSection({
    required this.title,
    required this.unlocks,
    required this.l10n,
    required this.onBuildingDetails,
    required this.onUnitDetails,
    super.key,
  });

  final String title;
  final List<TechnologyUnlock> unlocks;
  final AppLocalizations l10n;
  final ValueChanged<CityBuildingType> onBuildingDetails;
  final ValueChanged<GameUnitType> onUnitDetails;

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
          DecoratedBox(
            decoration: SurfaceElevation.flat.decoration(
              accent: GameUiTheme.scienceAccent,
              background: GameUiTheme.bg,
              backgroundAlpha: 116,
              border: BorderEmphasis.subtle,
              borderRadius: BorderRadius.circular(6),
              includeShadow: false,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: unlocks.isEmpty
                  ? Text(
                      l10n.technologyUnlocksNone,
                      style: GameUiTheme.bodySmall.copyWith(
                        color: GameUiTheme.textPrimary,
                        height: 1.25,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < unlocks.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 10,
                              color: SurfaceElevation.flat.strokeColor(
                                alpha: 95,
                              ),
                            ),
                          TechnologyUnlockRow(
                            unlock: unlocks[i],
                            l10n: l10n,
                            onBuildingDetails: onBuildingDetails,
                            onUnitDetails: onUnitDetails,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class TechnologyUnlockRow extends StatelessWidget {
  const TechnologyUnlockRow({
    required this.unlock,
    required this.l10n,
    required this.onBuildingDetails,
    required this.onUnitDetails,
    super.key,
  });

  final TechnologyUnlock unlock;
  final AppLocalizations l10n;
  final ValueChanged<CityBuildingType> onBuildingDetails;
  final ValueChanged<GameUnitType> onUnitDetails;

  @override
  Widget build(BuildContext context) {
    final buildingType = _buildingTypeFor(unlock);
    final unitType = _unitTypeFor(unlock);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (buildingType != null) ...[
          BuildingSpriteIcon(type: buildingType, size: 38),
          const SizedBox(width: 10),
        ] else if (unitType != null) ...[
          UnitSpriteIcon(
            type: unitType,
            size: 38,
            fallback: GameIcon(
              gameIconForUnitType(unitType),
              size: GameIconSize.regular,
              color: GameUiTheme.goldLight,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                GameDisplayNames.technologyUnlock(l10n, unlock),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodySmall.copyWith(
                  color: GameUiTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                TechnologyTreeLabels.unlockCategoryLabel(l10n, unlock),
                style: GameUiTheme.toolbarLabel.copyWith(
                  color: GameUiTheme.textMuted,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ),
        if (buildingType != null) ...[
          const SizedBox(width: 8),
          UnlockHelpButton(
            tooltip: l10n.buildingDetailsTooltip,
            onPressed: () => onBuildingDetails(buildingType),
          ),
        ] else if (unitType != null) ...[
          const SizedBox(width: 8),
          UnlockHelpButton(
            tooltip: l10n.unitDetailsTooltip,
            onPressed: () => onUnitDetails(unitType),
          ),
        ],
      ],
    );
  }

  CityBuildingType? _buildingTypeFor(TechnologyUnlock unlock) {
    return switch (unlock) {
      UnlockCityBuilding(:final buildingId) =>
        TechnologyUnlockQuery.buildingTypeForUnlock(buildingId),
      UnlockFieldImprovement() || UnlockUnitType() => null,
    };
  }

  GameUnitType? _unitTypeFor(TechnologyUnlock unlock) {
    return switch (unlock) {
      UnlockUnitType(:final unitType) => unitType,
      UnlockCityBuilding() || UnlockFieldImprovement() => null,
    };
  }
}

class UnlockHelpButton extends StatelessWidget {
  const UnlockHelpButton({
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 16,
        child: Container(
          width: 22,
          height: 22,
          decoration: SurfaceElevation.flat.decoration(
            background: Colors.white,
            backgroundAlpha: 14,
            border: BorderEmphasis.regular,
            borderRadius: BorderRadius.circular(11),
            includeShadow: false,
          ),
          child: const Center(
            child: GameIcon(
              GameIcons.info,
              size: GameIconSize.small,
              color: GameUiTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
