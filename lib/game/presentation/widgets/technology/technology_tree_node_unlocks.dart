part of 'technology_tree_node.dart';

class _TechnologyUnlockSummary extends StatelessWidget {
  const _TechnologyUnlockSummary({
    required this.card,
    required this.l10n,
    required this.unlocksLabel,
    required this.showDetails,
    required this.onBuildingDetails,
    required this.onUnitDetails,
  });

  final TechnologyCardViewModel card;
  final AppLocalizations l10n;
  final String unlocksLabel;
  final bool showDetails;
  final ValueChanged<CityBuildingType> onBuildingDetails;
  final ValueChanged<GameUnitType> onUnitDetails;

  @override
  Widget build(BuildContext context) {
    final inspectableUnlocks = [
      for (final unlock in card.unlocks)
        if (_buildingTypeForUnlock(unlock) != null ||
            _unitTypeForUnlock(unlock) != null)
          unlock,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            unlocksLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.bodySmall.copyWith(
              color: GameUiTheme.textPrimary,
              fontSize: 10,
            ),
          ),
        ),
        if (showDetails && inspectableUnlocks.isNotEmpty) ...[
          const SizedBox(width: 5),
          Wrap(
            spacing: 3,
            runSpacing: 3,
            children: [
              for (final unlock in inspectableUnlocks)
                _TreeUnlockHelpButton(
                  tooltip: _tooltipForUnlock(l10n, unlock),
                  onPressed: () => _showDetailsForUnlock(unlock),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _tooltipForUnlock(AppLocalizations l10n, TechnologyUnlock unlock) {
    return _buildingTypeForUnlock(unlock) != null
        ? l10n.buildingDetailsTooltip
        : l10n.unitDetailsTooltip;
  }

  void _showDetailsForUnlock(TechnologyUnlock unlock) {
    final buildingType = _buildingTypeForUnlock(unlock);
    if (buildingType != null) {
      onBuildingDetails(buildingType);
      return;
    }

    final unitType = _unitTypeForUnlock(unlock);
    if (unitType != null) {
      onUnitDetails(unitType);
    }
  }
}

class _TreeUnlockHelpButton extends StatelessWidget {
  const _TreeUnlockHelpButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 14,
        child: Container(
          width: 20,
          height: 20,
          decoration: SurfaceElevation.flat.decoration(
            background: Colors.white,
            backgroundAlpha: 14,
            border: BorderEmphasis.regular,
            borderRadius: BorderRadius.circular(10),
            includeShadow: false,
          ),
          child: const Center(
            child: GameIcon(
              GameIcons.info,
              size: GameIconSize.tiny,
              color: GameUiTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

CityBuildingType? _buildingTypeForUnlock(TechnologyUnlock unlock) {
  return switch (unlock) {
    UnlockCityBuilding(:final buildingId) =>
      TechnologyUnlockQuery.buildingTypeForUnlock(buildingId),
    UnlockFieldImprovement() || UnlockUnitType() => null,
  };
}

GameUnitType? _unitTypeForUnlock(TechnologyUnlock unlock) {
  return switch (unlock) {
    UnlockUnitType(:final unitType) => unitType,
    UnlockCityBuilding() || UnlockFieldImprovement() => null,
  };
}
