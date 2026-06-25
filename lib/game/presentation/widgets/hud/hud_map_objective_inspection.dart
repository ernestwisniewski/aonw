part of 'hud_map_inspection_menu.dart';

class _MapObjectiveInspectionSection extends StatelessWidget {
  const _MapObjectiveInspectionSection({required this.progress});

  final MapObjectiveProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final definition = progress.definition;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _Section(
        icon: GameIcons.victory,
        title: l10n.mapInspectionObjectiveTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              GameDisplayNames.mapObjective(l10n, definition.type),
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              GameDisplayNames.mapObjectiveDescription(l10n, definition.type),
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textSecondary,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                _MapObjectivePill(
                  icon: GameIcons.checkCircle,
                  label: _statusLabel(l10n),
                  color: _statusColor,
                ),
                if (definition.victoryPoints > 0)
                  _MapObjectivePill(
                    icon: GameIcons.victory,
                    label: l10n.mapObjectiveRewardVictoryPoints(
                      definition.victoryPoints,
                    ),
                    color: GameUiTheme.success,
                  ),
                if (definition.goldPerTurn > 0)
                  _MapObjectivePill(
                    icon: GameIcons.gold,
                    label: l10n.mapObjectiveRewardGoldPerTurn(
                      definition.goldPerTurn,
                    ),
                    color: GameUiTheme.gold,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    if (progress.contested) return GameUiTheme.warning;
    if (progress.completed) return GameUiTheme.success;
    if (progress.controlled) return GameUiTheme.gold;
    return GameUiTheme.textMuted;
  }

  String _statusLabel(AppLocalizations l10n) {
    if (progress.contested) return l10n.mapObjectiveStatusContested;
    if (progress.completed) {
      return l10n.mapObjectiveStatusCompleted(
        progress.holdTurns,
        progress.definition.requiredHoldTurns,
      );
    }
    if (progress.controlled) {
      return l10n.mapObjectiveStatusHolding(
        progress.holdTurns,
        progress.definition.requiredHoldTurns,
      );
    }
    return l10n.mapObjectiveStatusNeutral(
      progress.definition.requiredHoldTurns,
    );
  }
}

class _MapObjectivePill extends StatelessWidget {
  const _MapObjectivePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final GameIconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: ShapeDecoration(
        color: SurfaceElevation.flat.fill(background: color, alpha: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(
            color: SurfaceElevation.flat.strokeColor(color: color, alpha: 104),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GameUiTheme.toolbarLabel.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
