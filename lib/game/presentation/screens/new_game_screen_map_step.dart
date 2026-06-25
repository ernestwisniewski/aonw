part of 'new_game_screen.dart';

class _MapStep extends StatelessWidget {
  const _MapStep({
    required this.official,
    required this.yours,
    required this.onMapSelected,
    super.key,
  });

  final List<MapSelection> official;
  final List<MapSelection> yours;
  final ValueChanged<MapSelection> onMapSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maps = [...official, ...yours];
    return MenuRouteSection(
      icon: Icons.map_outlined,
      title: l10n.newGameMapTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.newGameMapSubtitle, style: GameUiTheme.bodySmall),
          const SizedBox(height: 14),
          if (official.isNotEmpty) ...[
            GameUiSectionHeader(
              label: GameText.sectionLabel(l10n.officialMapsSection),
            ),
            const SizedBox(height: 8),
            _MapTileGrid(maps: official, onMapSelected: onMapSelected),
          ],
          if (yours.isNotEmpty) ...[
            if (official.isNotEmpty) const SizedBox(height: 16),
            GameUiSectionHeader(
              label: GameText.sectionLabel(l10n.yourMapsSection),
            ),
            const SizedBox(height: 8),
            _MapTileGrid(maps: yours, onMapSelected: onMapSelected),
          ],
          if (maps.isEmpty)
            GameUiEmptyState(
              icon: Icons.map_outlined,
              title: l10n.noMapsTitle,
              message: l10n.noMapsMessage,
            ),
        ],
      ),
    );
  }
}

class _MapTileGrid extends StatelessWidget {
  const _MapTileGrid({required this.maps, required this.onMapSelected});

  final List<MapSelection> maps;
  final ValueChanged<MapSelection> onMapSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820 ? 2 : 1;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final map in maps)
              SizedBox(
                width: itemWidth,
                child: MapSelectionTile(
                  map: map,
                  actionLabel: GameText.actionLabel(l10n.continueAction),
                  onTap: () => onMapSelected(map),
                ),
              ),
          ],
        );
      },
    );
  }
}
