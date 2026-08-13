part of 'strategic_resource_economy_dialog.dart';

class _ResourceCards extends StatelessWidget {
  const _ResourceCards({required this.summary, required this.l10n});

  final HudStrategicResourceSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => _EconomySection(
    key: const Key('strategicResourceEconomy.resources'),
    title: l10n.diplomacyStrategicResourcesTitle,
    contentPadding: const EdgeInsets.all(10),
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final twoColumns = constraints.maxWidth >= 650;
          final width = twoColumns
              ? (constraints.maxWidth - spacing) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final row in summary.rows)
                SizedBox(
                  width: width,
                  child: _StrategicResourceCard(row: row, l10n: l10n),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _StrategicResourceCard extends StatelessWidget {
  const _StrategicResourceCard({required this.row, required this.l10n});

  final HudStrategicResourceRow row;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final accent = row.shortage
        ? GameUiTheme.danger
        : row.available == 0
        ? GameUiTheme.warning
        : GameUiTheme.resourcesAccent;
    return Semantics(
      container: true,
      label: GameDisplayNames.resource(l10n, row.resource),
      child: Container(
        key: Key('strategicResourceEconomy.resource.${row.resource.name}'),
        padding: const EdgeInsets.all(12),
        decoration: SurfaceElevation.flat.decoration(
          accent: accent,
          border: row.shortage ? BorderEmphasis.strong : BorderEmphasis.regular,
          includeShadow: false,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ResourceCardHeader(l10n: l10n, row: row, accent: accent),
            const SizedBox(height: 10),
            _ResourceCardMetrics(l10n: l10n, row: row),
          ],
        ),
      ),
    );
  }
}

class _ResourceCardHeader extends StatelessWidget {
  const _ResourceCardHeader({
    required this.l10n,
    required this.row,
    required this.accent,
  });

  final AppLocalizations l10n;
  final HudStrategicResourceRow row;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      GameIcon(GameIcons.resources, size: GameIconSize.regular, color: accent),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          GameDisplayNames.resource(l10n, row.resource),
          style: GameUiTheme.cardTitle,
        ),
      ),
      if (row.shortage)
        const GameIcon(
          GameIcons.warning,
          size: GameIconSize.small,
          color: GameUiTheme.danger,
        ),
    ],
  );
}

class _ResourceCardMetrics extends StatelessWidget {
  const _ResourceCardMetrics({required this.l10n, required this.row});

  final AppLocalizations l10n;
  final HudStrategicResourceRow row;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (row.stockpiled) ...[
        _Metric(
          label: l10n.resourceBreakdownStored,
          value: '${row.storedTotal}',
        ),
        _Metric(
          label: l10n.resourceBreakdownAllocated,
          value: '${row.allocated}',
        ),
      ] else
        _Metric(
          label: l10n.resourceBreakdownControlledDeposits,
          value: '${row.controlledDeposits}',
        ),
      _Metric(
        label: l10n.commonAvailable,
        value: '${row.available}',
        valueColor: row.available == 0
            ? GameUiTheme.warning
            : GameUiTheme.success,
      ),
      if (row.stockpiled)
        _Metric(
          label: l10n.resourceBreakdownDomesticProduction,
          value: _signed(row.domesticProduction),
        ),
      _Metric(
        label: l10n.resourceBreakdownImports,
        value: _signed(row.imports),
      ),
      _Metric(
        label: l10n.resourceBreakdownExports,
        value: row.exports == 0 ? '0' : '-${row.exports}',
      ),
      _Metric(
        label: l10n.resourceBreakdownNetPerTurn,
        value: _signed(row.netPerTurn),
        valueColor: row.netPerTurn < 0
            ? GameUiTheme.danger
            : row.netPerTurn > 0
            ? GameUiTheme.success
            : null,
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 92),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: SurfaceElevation.flat.decoration(
      background: GameUiTheme.bg,
      backgroundAlpha: 105,
      border: BorderEmphasis.subtle,
      includeShadow: false,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GameUiTheme.cardMeta),
        const SizedBox(height: 2),
        Text(
          value,
          style: GameUiTheme.bodyStrong.copyWith(
            color: valueColor ?? GameUiTheme.textBright,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}
