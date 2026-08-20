part of 'strategic_resource_economy_dialog.dart';

class _EconomySection extends StatelessWidget {
  const _EconomySection({
    required this.title,
    required this.children,
    this.accent = GameUiTheme.gold,
    this.contentPadding = const EdgeInsets.fromLTRB(10, 4, 10, 10),
    super.key,
  });

  final String title;
  final List<Widget> children;
  final Color accent;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: SurfaceElevation.flat.decoration(
      accent: accent,
      border: BorderEmphasis.regular,
      includeShadow: false,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 7),
          child: Text(
            title,
            style: GameUiTheme.sectionHeader.copyWith(color: accent),
          ),
        ),
        Divider(
          height: 1,
          color: SurfaceElevation.flat.strokeColor(color: accent, alpha: 52),
        ),
        Padding(
          padding: contentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _separated(children),
          ),
        ),
      ],
    ),
  );
}

class _AlertRow extends StatelessWidget {
  const _AlertRow(this.alert);

  final _EconomyAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = alert.danger ? GameUiTheme.danger : GameUiTheme.warning;
    return Semantics(
      key: Key('strategicResourceEconomy.alert.${alert.key}'),
      container: true,
      label: '${alert.title}. ${alert.detail}',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: SurfaceElevation.flat.decoration(
          accent: color,
          background: color,
          backgroundAlpha: 20,
          border: BorderEmphasis.regular,
          includeShadow: false,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GameIcon(GameIcons.warning, size: GameIconSize.small, color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: GameUiTheme.bodyStrong),
                  const SizedBox(height: 2),
                  Text(alert.detail, style: GameUiTheme.cardMeta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    super.key,
  });

  final GameIconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $subtitle. $actionLabel',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: GameUiTheme.cardBorderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              GameIcon(
                icon,
                size: GameIconSize.regular,
                color: GameUiTheme.resourcesAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GameUiTheme.bodyStrong),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GameUiTheme.cardMeta),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(actionLabel, style: GameUiTheme.labelSmall),
              const SizedBox(width: 3),
              const GameIcon(
                GameIcons.arrowRight,
                size: GameIconSize.regular,
                color: GameUiTheme.gold,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    child: Text(message, style: GameUiTheme.bodySmall),
  );
}

class _EconomyAlert {
  const _EconomyAlert({
    required this.key,
    required this.title,
    required this.detail,
    this.danger = false,
  });

  final String key;
  final String title;
  final String detail;
  final bool danger;
}

List<Widget> _separated(List<Widget> children) {
  if (children.length < 2) return children;
  return [
    for (var i = 0; i < children.length; i++) ...[
      if (i > 0)
        Divider(
          height: 1,
          color: SurfaceElevation.flat.strokeColor(
            color: GameUiTheme.gold,
            alpha: 34,
          ),
          indent: 4,
          endIndent: 4,
        ),
      children[i],
    ],
  ];
}

String _allocationTitle(
  AppLocalizations l10n,
  HudStrategicResourceAllocation allocation,
) {
  final cityName = GameDisplayNames.city(l10n, allocation.city);
  final targetName = switch (allocation.city.productionQueue?.target) {
    UnitProductionTarget(:final unitType) => GameDisplayNames.unitType(
      l10n,
      unitType,
    ),
    _ => null,
  };
  return targetName == null ? cityName : '$targetName · $cityName';
}

String _bundleLabel(AppLocalizations l10n, StrategicResourceBundle bundle) =>
    bundle.amounts.entries
        .map(
          (entry) =>
              '${entry.value} ${GameDisplayNames.resource(l10n, entry.key)}',
        )
        .join(' · ');

String _partnerId(ResourceTradeAgreement agreement, String activePlayerId) =>
    agreement.importerPlayerId == activePlayerId
    ? agreement.exporterPlayerId
    : agreement.importerPlayerId;

Player? _playerById(Iterable<Player> players, String playerId) {
  for (final player in players) {
    if (player.id == playerId) return player;
  }
  return null;
}

String _signed(int value) => value > 0 ? '+$value' : '$value';

String _sourceTitle(AppLocalizations l10n, HudStrategicResourceSource source) {
  final resource = GameDisplayNames.resource(l10n, source.resource);
  final improvement = source.improvement;
  return improvement == null
      ? resource
      : '$resource · ${GameDisplayNames.fieldImprovement(l10n, improvement)}';
}

String _sourceSubtitle(
  AppLocalizations l10n,
  HudStrategicResourceSource source,
) {
  final city = GameDisplayNames.city(l10n, source.city);
  final amount = source.amountPerTurn;
  return amount == null
      ? city
      : '$city · ${_signed(amount)}/${l10n.commonTurn}';
}
