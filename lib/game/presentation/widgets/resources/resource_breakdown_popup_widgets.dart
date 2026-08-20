part of 'resource_breakdown_popup.dart';

class _ResourceBreakdownContent extends StatelessWidget {
  const _ResourceBreakdownContent({
    required this.title,
    required this.accent,
    required this.icon,
    required this.closeTooltip,
    required this.showDragHandle,
    required this.showEconomyAction,
    required this.economyActionLabel,
    required this.onClose,
    required this.onOpenEconomy,
    required this.sections,
  });

  final String title;
  final Color accent;
  final GameIconData icon;
  final String closeTooltip;
  final bool showDragHandle;
  final bool showEconomyAction;
  final String economyActionLabel;
  final VoidCallback onClose;
  final VoidCallback? onOpenEconomy;
  final List<_BreakdownSectionModel> sections;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ResourceBreakdownHeader(
        title: title,
        accent: accent,
        icon: icon,
        closeTooltip: closeTooltip,
        showDragHandle: showDragHandle,
        showEconomyAction: showEconomyAction,
        economyActionLabel: economyActionLabel,
        onClose: onClose,
        onOpenEconomy: onOpenEconomy,
      ),
      for (var index = 0; index < sections.length; index++) ...[
        if (index > 0)
          SizedBox(height: sections[index].separatedBefore ? 18 : 10),
        _BreakdownSection(
          section: sections[index],
          accent: sections[index].accent ?? accent,
        ),
      ],
    ],
  );
}

class _ResourceBreakdownHeader extends StatelessWidget {
  const _ResourceBreakdownHeader({
    required this.title,
    required this.accent,
    required this.icon,
    required this.closeTooltip,
    required this.showDragHandle,
    required this.showEconomyAction,
    required this.economyActionLabel,
    required this.onClose,
    required this.onOpenEconomy,
  });

  final String title;
  final Color accent;
  final GameIconData icon;
  final String closeTooltip;
  final bool showDragHandle;
  final bool showEconomyAction;
  final String economyActionLabel;
  final VoidCallback onClose;
  final VoidCallback? onOpenEconomy;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showDragHandle) ...[
        const _ResourceBreakdownDragHandle(),
        const SizedBox(height: 10),
      ],
      GameUiEpicHeader(
        label: title,
        accent: accent,
        alignment: Alignment.centerLeft,
        leading: GameIcon(icon, size: GameIconSize.regular, color: accent),
        trailing: _PopupIconButton(
          icon: GameIcons.close,
          tooltip: closeTooltip,
          onTap: onClose,
        ),
      ),
      const SizedBox(height: 8),
      if (showEconomyAction) ...[
        EpicButton.primary(
          key: const Key('resourceBreakdown.openStrategicEconomy'),
          label: economyActionLabel,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          iconBuilder: (foreground) => GameIcon(
            GameIcons.resources,
            size: GameIconSize.small,
            color: foreground,
          ),
          onPressed: onOpenEconomy,
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _ResourceBreakdownDragHandle extends StatelessWidget {
  const _ResourceBreakdownDragHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 42,
      height: 4,
      decoration: ShapeDecoration(
        color: SurfaceElevation.flat.fill(
          background: GameUiTheme.copper,
          alpha: 120,
        ),
        shape: const StadiumBorder(),
      ),
    ),
  );
}

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
      key: section.key,
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
            if (section.rows[i].groupLabel case final groupLabel?) ...[
              if (i > 0) ...[
                const SizedBox(height: 7),
                Divider(height: 1, color: accent.withAlpha(52)),
                const SizedBox(height: 7),
              ],
              Text(
                groupLabel,
                style: GameUiTheme.sectionHeader.copyWith(
                  color: accent.withAlpha(190),
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 5),
            ] else if (i > 0)
              const SizedBox(height: 5),
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
    final content = _BreakdownRowContent(row: row, maxMagnitude: maxMagnitude);
    final onTap = row.onTap;
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: '${row.label}, ${row.value}',
      child: InkWell(
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: content,
        ),
      ),
    );
  }
}

class _BreakdownRowContent extends StatelessWidget {
  const _BreakdownRowContent({required this.row, required this.maxMagnitude});

  final _BreakdownRowModel row;
  final int maxMagnitude;

  @override
  Widget build(BuildContext context) {
    final valueColor = row.negative
        ? GameUiTheme.danger
        : row.positive
        ? GameUiTheme.goldLight
        : row.muted
        ? GameUiTheme.textMuted
        : GameUiTheme.textPrimary;
    final magnitude = _rowMagnitude(row);
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
                style: GameUiTheme.bodySmall.copyWith(
                  color: row.muted
                      ? GameUiTheme.textMuted
                      : GameUiTheme.textSecondary,
                  fontStyle: row.muted ? FontStyle.italic : null,
                ),
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
        if (magnitude != null && maxMagnitude > 0) ...[
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
        color: SurfaceElevation.flat.fill(
          background: GameUiTheme.surfaceDeep,
          alpha: 160,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: SurfaceElevation.flat.fill(
                  background: color,
                  alpha: 210,
                ),
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
