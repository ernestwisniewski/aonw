part of 'city_building_details_dialog.dart';

class _BuildingDetailsHeader extends StatelessWidget {
  final CityBuildingType buildingType;
  final String title;
  final String? emoji;
  final AppLocalizations l10n;
  final VoidCallback onClose;

  const _BuildingDetailsHeader({
    required this.buildingType,
    required this.title,
    required this.emoji,
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
            width: 56,
            height: 56,
            decoration: SurfaceElevation.flat.decoration(
              background: GameUiTheme.gold,
              backgroundAlpha: 24,
              border: BorderEmphasis.regular,
              borderRadius: BorderRadius.circular(6),
              includeShadow: false,
            ),
            child: Center(
              child: BuildingSpriteIcon(
                type: buildingType,
                size: 50,
                fallback: Text(
                  emoji ?? '',
                  style: const TextStyle(fontSize: 28),
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
                  textKey: const Key('cityBuildingDetailsHeader.title'),
                ),
                const SizedBox(height: 2),
                Text(
                  GameText.uppercase(l10n.productionCategoryBuilding),
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

class _BuildingDetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _BuildingDetailChip({required this.label, required this.value});

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

class _BuildingDetailsSection extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _BuildingDetailsSection({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GameText.uppercase(title),
            style: GameUiTheme.toolbarLabel.copyWith(color: GameUiTheme.gold),
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
