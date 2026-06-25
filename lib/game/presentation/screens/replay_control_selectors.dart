part of 'replay_screen.dart';

class _ReplaySpeedSelector extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ReplaySpeedSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 7,
      runSpacing: 6,
      children: [
        Text(
          l10n.replaySpeedLabel,
          style: GameUiTheme.cardMeta.copyWith(color: GameUiTheme.textTertiary),
        ),
        for (final speed in const [0.5, 1.0, 2.0, 3.0, 10.0, 20.0])
          _ReplayChipButton(
            selected: value == speed,
            label: '${speed.g}x',
            onPressed: () => onChanged(speed),
          ),
      ],
    );
  }
}

class _ReplayPerspectiveSelector extends StatelessWidget {
  final ReplayTimeline timeline;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _ReplayPerspectiveSelector({
    required this.timeline,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final players = {
      for (final player in timeline.save.players) player.id: player,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.replayPerspectiveLabel,
          style: GameUiTheme.cardMeta.copyWith(color: GameUiTheme.textTertiary),
        ),
        const SizedBox(width: 7),
        DecoratedBox(
          decoration: BoxDecoration(
            color: GameUiTheme.surface.withAlpha(210),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GameUiTheme.gold.withAlpha(90)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              dropdownColor: GameUiTheme.surface,
              iconEnabledColor: GameUiTheme.goldLight,
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.replayAllPlayers),
                ),
                for (final playerId in timeline.playerIds)
                  DropdownMenuItem<String?>(
                    value: playerId,
                    child: Text(
                      players[playerId] == null
                          ? playerId
                          : GameDisplayNames.player(l10n, players[playerId]!),
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplayTurnMarkerToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReplayTurnMarkerToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              key: const Key('replay.showTurnMarkersCheckbox'),
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
              checkColor: GameUiTheme.bg,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return GameUiTheme.goldLight;
                }
                return GameUiTheme.surface.withAlpha(210);
              }),
              side: BorderSide(color: GameUiTheme.gold.withAlpha(95)),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              l10n.replayShowTurnsLabel,
              style: GameUiTheme.cardMeta.copyWith(
                color: GameUiTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplayFreeCameraToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReplayFreeCameraToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              key: const Key('replay.freeCameraCheckbox'),
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
              checkColor: GameUiTheme.bg,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return GameUiTheme.goldLight;
                }
                return GameUiTheme.surface.withAlpha(210);
              }),
              side: BorderSide(color: GameUiTheme.gold.withAlpha(95)),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              l10n.replayFreeCameraLabel,
              style: GameUiTheme.cardMeta.copyWith(
                color: GameUiTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
