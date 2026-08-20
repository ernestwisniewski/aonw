import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/selection_info/contents/building_detail_entry.dart';
import 'package:aonw/game/presentation/widgets/theme/building_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class BuildingDetailTile extends StatelessWidget {
  const BuildingDetailTile({
    required this.entry,
    required this.compact,
    required this.onDetails,
    super.key,
  });

  final BuildingDetailEntry entry;
  final bool compact;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(7);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onDetails,
          child: Container(
            padding: EdgeInsets.all(compact ? 8 : 10),
            decoration: SurfaceElevation.flat.decoration(
              background: GameUiTheme.bg,
              backgroundAlpha: 150,
              borderRadius: radius,
              border: BorderEmphasis.regular,
              includeShadow: false,
            ),
            child: _BuildingTileRow(
              entry: entry,
              compact: compact,
              onDetails: onDetails,
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildingTileRow extends StatelessWidget {
  const _BuildingTileRow({
    required this.entry,
    required this.compact,
    required this.onDetails,
  });

  final BuildingDetailEntry entry;
  final bool compact;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _BuildingLeading(item: entry.item, compact: compact),
        SizedBox(width: compact ? 9 : 12),
        Expanded(
          child: _BuildingTileContent(entry: entry, compact: compact),
        ),
        if (onDetails != null) ...[
          SizedBox(width: compact ? 8 : 10),
          _BuildingDetailsButton(
            label: l10n.buildingDetailsTooltip,
            compact: compact,
            onPressed: onDetails!,
          ),
        ],
      ],
    );
  }
}

class _BuildingTileContent extends StatelessWidget {
  const _BuildingTileContent({required this.entry, required this.compact});

  final BuildingDetailEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          entry.item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.body.copyWith(
            color: GameUiTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 5 : 7),
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: 5,
          children: [
            _BuildingMetaPill(
              label: l10n.cityProductionBuiltLabel,
              compact: compact,
              highlighted: true,
            ),
            if (entry.productionCost > 0)
              _BuildingMetaPill(
                label: l10n.cityProductionCostShort(entry.productionCost),
                compact: compact,
              ),
            for (final chip in entry.effectChips)
              _BuildingEffectPill(chip: chip, compact: compact),
          ],
        ),
      ],
    );
  }
}

class _BuildingDetailsButton extends StatelessWidget {
  const _BuildingDetailsButton({
    required this.label,
    required this.compact,
    required this.onPressed,
  });

  final String label;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 16,
        child: Container(
          width: compact ? 30 : 34,
          height: compact ? 30 : 34,
          decoration: SurfaceElevation.flat.decoration(
            background: Colors.white,
            backgroundAlpha: 14,
            border: BorderEmphasis.regular,
            borderRadius: BorderRadius.circular(5),
            includeShadow: false,
          ),
          child: const Center(
            child: GameIcon(
              GameIcons.help,
              size: GameIconSize.small,
              color: GameUiTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildingLeading extends StatelessWidget {
  const _BuildingLeading({required this.item, required this.compact});

  final SelectionCityBuildingItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final type = item.type;
    return Container(
      width: compact ? 42 : 52,
      height: compact ? 42 : 52,
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 255,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(6),
        includeShadow: false,
      ),
      child: Center(
        child: type == null
            ? const GameIcon(
                GameIcons.city,
                size: GameIconSize.regular,
                color: GameUiTheme.goldLight,
              )
            : BuildingSpriteIcon(type: type, size: compact ? 38 : 46),
      ),
    );
  }
}

class _BuildingMetaPill extends StatelessWidget {
  const _BuildingMetaPill({
    required this.label,
    required this.compact,
    this.highlighted = false,
  });

  final String label;
  final bool compact;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: SurfaceElevation.flat.decoration(
        background: highlighted ? GameUiTheme.gold : Colors.white,
        backgroundAlpha: highlighted ? 28 : 10,
        borderColor: highlighted ? GameUiTheme.gold : Colors.white,
        borderAlpha: highlighted ? 100 : 28,
        borderRadius: BorderRadius.circular(4),
        includeShadow: false,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GameUiTheme.bodySmall.copyWith(
          color: highlighted ? GameUiTheme.goldLight : GameUiTheme.textMuted,
          fontSize: compact ? 10 : null,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BuildingEffectPill extends StatelessWidget {
  const _BuildingEffectPill({required this.chip, required this.compact});

  final BuildingEffectChip chip;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: SurfaceElevation.flat.decoration(
        background: chip.color,
        backgroundAlpha: 20,
        borderColor: chip.color,
        borderAlpha: 78,
        borderRadius: BorderRadius.circular(4),
        includeShadow: false,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(chip.icon, size: GameIconSize.small, color: chip.color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 150 : 220),
            child: Text(
              chip.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontSize: compact ? 10 : null,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
