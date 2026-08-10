part of 'assets_editor_screen.dart';

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final bool active;
  final bool enabled;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? GameUiTheme.goldLight : GameUiTheme.textPrimary;
    return TextButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 34),
        foregroundColor: foreground,
        disabledForegroundColor: GameUiTheme.textTertiary,
        backgroundColor: active
            ? GameUiTheme.gold.withAlpha(36)
            : GameUiTheme.surface.withAlpha(190),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: GameUiTheme.actionLabel.copyWith(fontSize: 10),
        shape: RoundedRectangleBorder(
          borderRadius: GameUiTheme.borderRadius,
          side: BorderSide(
            color: active ? GameUiTheme.gold : GameUiTheme.gold.withAlpha(74),
          ),
        ),
      ),
    );
  }
}

class _ActionFilterButton extends StatelessWidget {
  const _ActionFilterButton({
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minWidth: 56, minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? GameUiTheme.gold.withAlpha(38)
                : GameUiTheme.surface.withAlpha(190),
            borderRadius: GameUiTheme.borderRadius,
            border: Border.all(
              color: selected
                  ? GameUiTheme.gold
                  : GameUiTheme.gold.withAlpha(74),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.actionLabel.copyWith(
              color: selected ? GameUiTheme.goldLight : GameUiTheme.textPrimary,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        isSelected: active,
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: active
              ? GameUiTheme.gold.withAlpha(36)
              : GameUiTheme.surface.withAlpha(190),
          foregroundColor: active ? GameUiTheme.goldLight : GameUiTheme.gold,
          side: BorderSide(
            color: active ? GameUiTheme.gold : GameUiTheme.gold.withAlpha(74),
          ),
          shape: RoundedRectangleBorder(borderRadius: GameUiTheme.borderRadius),
        ),
        icon: Icon(icon, size: 19),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.gold.withAlpha(28),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: GameUiTheme.gold.withAlpha(116)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: GameUiTheme.toolbarLabel.copyWith(
            color: GameUiTheme.goldLight,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

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
