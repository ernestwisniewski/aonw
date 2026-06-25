part of 'assets_editor_screen.dart';

class _AssetsEditorToolbar extends StatelessWidget {
  const _AssetsEditorToolbar({
    required this.availableFilters,
    required this.editMode,
    required this.filterId,
    required this.onFilterChanged,
    required this.onBack,
    required this.onEditModeChanged,
    required this.onPauseChanged,
    required this.onSaveAdjustments,
    required this.onSpeedChanged,
    required this.paused,
    required this.previewCount,
    required this.saving,
    required this.speed,
    required this.totalCount,
  });

  final List<_AssetFilter> availableFilters;
  final bool editMode;
  final String? filterId;
  final ValueChanged<String?> onFilterChanged;
  final VoidCallback onBack;
  final ValueChanged<bool> onEditModeChanged;
  final ValueChanged<bool> onPauseChanged;
  final VoidCallback onSaveAdjustments;
  final ValueChanged<double> onSpeedChanged;
  final bool paused;
  final int previewCount;
  final bool saving;
  final double speed;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(242),
        border: Border(
          bottom: BorderSide(color: GameUiTheme.gold.withAlpha(82)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    foregroundColor: GameUiTheme.goldLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: GameUiTheme.borderRadius,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ASSETS EDITOR',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameUiTheme.brandSubtitle.copyWith(
                      color: GameUiTheme.goldLight,
                      fontSize: 16,
                    ),
                  ),
                ),
                _CountPill(label: '$previewCount / $totalCount'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ActionFilterButton(
                  label: 'ALL',
                  selected: filterId == null,
                  onTap: () => onFilterChanged(null),
                ),
                for (final filter in availableFilters)
                  _ActionFilterButton(
                    label: filter.label.toUpperCase(),
                    selected: filterId == filter.id,
                    onTap: () => onFilterChanged(filter.id),
                  ),
                const SizedBox(width: 8),
                _ModeButton(
                  active: editMode,
                  icon: Icons.tune,
                  label: 'EDIT',
                  onTap: () => onEditModeChanged(!editMode),
                ),
                if (editMode) ...[
                  _ModeButton(
                    active: true,
                    enabled: !saving,
                    icon: Icons.save_outlined,
                    label: saving ? 'SAVING' : 'SAVE',
                    onTap: onSaveAdjustments,
                  ),
                ],
                const SizedBox(width: 8),
                _IconToggle(
                  active: paused,
                  icon: paused ? Icons.play_arrow : Icons.pause,
                  label: paused ? 'Play' : 'Pause',
                  onTap: () => onPauseChanged(!paused),
                ),
                SizedBox(
                  width: 190,
                  child: Row(
                    children: [
                      Text(
                        '${speed.toStringAsFixed(1)}x',
                        style: GameUiTheme.toolbarLabel.copyWith(
                          color: GameUiTheme.goldLight,
                          fontSize: 10,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: GameUiTheme.gold,
                            inactiveTrackColor: GameUiTheme.gold.withAlpha(62),
                            thumbColor: GameUiTheme.goldLight,
                            overlayColor: GameUiTheme.gold.withAlpha(30),
                            trackHeight: 2,
                          ),
                          child: Slider(
                            min: 0.25,
                            max: 2,
                            divisions: 7,
                            value: speed,
                            onChanged: onSpeedChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
