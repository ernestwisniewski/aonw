part of 'resource_breakdown_popup.dart';

class _BreakdownSection extends StatelessWidget {
  final _BreakdownSectionModel section;
  final Color accent;

  const _BreakdownSection({required this.section, required this.accent});

  @override
  Widget build(BuildContext context) {
    final maxMagnitude = section.rows.fold<int>(
      0,
      (maxValue, row) => math.max(maxValue, _rowMagnitude(row) ?? 0),
    );
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: SurfaceElevation.flat.decoration(
        accent: accent,
        background: GameUiTheme.bg,
        backgroundAlpha: 132,
        borderAlpha: 70,
        shape: SurfaceShape.card,
        includeShadow: false,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            section.title,
            style: GameUiTheme.sectionHeader.copyWith(color: accent),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < section.rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 5),
            _BreakdownRow(row: section.rows[i], maxMagnitude: maxMagnitude),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final _BreakdownRowModel row;
  final int maxMagnitude;

  const _BreakdownRow({required this.row, required this.maxMagnitude});

  @override
  Widget build(BuildContext context) {
    final valueColor = row.negative
        ? GameUiTheme.danger
        : row.positive
        ? GameUiTheme.goldLight
        : GameUiTheme.textPrimary;
    final magnitude = _rowMagnitude(row);
    final showBar = magnitude != null && maxMagnitude > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  row.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GameUiTheme.bodyStrong.copyWith(color: valueColor),
                ),
              ),
            ),
          ],
        ),
        if (showBar) ...[
          const SizedBox(height: 4),
          _BreakdownMagnitudeBar(
            factor: magnitude / maxMagnitude,
            color: valueColor,
          ),
        ],
      ],
    );
  }
}

class _BreakdownMagnitudeBar extends StatelessWidget {
  const _BreakdownMagnitudeBar({required this.factor, required this.color});

  final double factor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = factor.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: ColoredBox(
        color: GameUiTheme.surfaceDeep.withAlpha(160),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: color.withAlpha(210),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

int? _rowMagnitude(_BreakdownRowModel row) {
  if (!row.positive && !row.negative && !row.value.startsWith('x')) {
    return null;
  }
  final match = RegExp(r'\d+').firstMatch(row.value);
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}

class _PopupIconButton extends StatelessWidget {
  final GameIconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PopupIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: SurfaceElevation.flat.fill(
            background: GameUiTheme.chipSurface,
            alpha: 190,
          ),
          borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
          child: InkWell(
            borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
            onTap: onTap,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Center(
                child: GameIcon(
                  icon,
                  size: GameIconSize.small,
                  color: GameUiTheme.goldLight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
