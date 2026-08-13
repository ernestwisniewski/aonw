part of 'strategic_resource_economy_dialog.dart';

class _EconomyOverview extends StatelessWidget {
  const _EconomyOverview({
    required this.l10n,
    required this.summary,
    required this.gameSave,
    required this.activePlayerId,
    required this.alerts,
    required this.agreements,
    required this.partners,
    required this.onCityPressed,
    required this.onTradePartnerPressed,
  });

  final AppLocalizations l10n;
  final HudStrategicResourceSummary summary;
  final GameSave gameSave;
  final String activePlayerId;
  final List<_EconomyAlert> alerts;
  final List<ResourceTradeAgreement> agreements;
  final List<Player> partners;
  final ValueChanged<GameCity> onCityPressed;
  final ValueChanged<String> onTradePartnerPressed;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 900),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (alerts.isNotEmpty) ...[
          _AlertsSection(l10n: l10n, alerts: alerts),
          const SizedBox(height: 14),
        ],
        _ResourceCards(summary: summary, l10n: l10n),
        const SizedBox(height: 14),
        _AllocationsSection(
          l10n: l10n,
          allocations: summary.allocations,
          onCityPressed: onCityPressed,
        ),
        const SizedBox(height: 14),
        _SourcesSection(
          l10n: l10n,
          sources: summary.sources,
          onCityPressed: onCityPressed,
        ),
        const SizedBox(height: 14),
        _AgreementsSection(
          l10n: l10n,
          agreements: agreements,
          activePlayerId: activePlayerId,
          gameSave: gameSave,
        ),
        const SizedBox(height: 14),
        _PartnersSection(
          l10n: l10n,
          partners: partners,
          onPressed: onTradePartnerPressed,
        ),
      ],
    ),
  );
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.l10n, required this.alerts});

  final AppLocalizations l10n;
  final List<_EconomyAlert> alerts;

  @override
  Widget build(BuildContext context) => _EconomySection(
    key: const Key('strategicResourceEconomy.alerts'),
    title: l10n.resourceEconomyAlertsTitle,
    accent: GameUiTheme.warning,
    children: [for (final alert in alerts) _AlertRow(alert)],
  );
}

class _AllocationsSection extends StatelessWidget {
  const _AllocationsSection({
    required this.l10n,
    required this.allocations,
    required this.onCityPressed,
  });

  final AppLocalizations l10n;
  final List<HudStrategicResourceAllocation> allocations;
  final ValueChanged<GameCity> onCityPressed;

  @override
  Widget build(BuildContext context) => _EconomySection(
    key: const Key('strategicResourceEconomy.allocations'),
    title: l10n.resourceBreakdownAllocations,
    children: allocations.isEmpty
        ? [_EmptyState(message: l10n.resourceBreakdownNoAllocations)]
        : [
            for (final allocation in allocations)
              _NavigationRow(
                key: Key(
                  'strategicResourceEconomy.allocation.${allocation.city.id}',
                ),
                icon: GameIcons.production,
                title: _allocationTitle(l10n, allocation),
                subtitle: _bundleLabel(l10n, allocation.bundle),
                actionLabel: l10n.resourceEconomyGoToCityAction,
                onTap: () => onCityPressed(allocation.city),
              ),
          ],
  );
}

class _SourcesSection extends StatelessWidget {
  const _SourcesSection({
    required this.l10n,
    required this.sources,
    required this.onCityPressed,
  });

  final AppLocalizations l10n;
  final List<HudStrategicResourceSource> sources;
  final ValueChanged<GameCity> onCityPressed;

  @override
  Widget build(BuildContext context) => _EconomySection(
    key: const Key('strategicResourceEconomy.sources'),
    title: l10n.resourceBreakdownSourcesSection,
    children: sources.isEmpty
        ? [_EmptyState(message: l10n.resourceEconomyNoSources)]
        : [
            for (final source in sources)
              _NavigationRow(
                key: Key(
                  'strategicResourceEconomy.source.${source.city.id}.${source.hex.col}.${source.hex.row}',
                ),
                icon: GameIcons.improvement,
                title: _sourceTitle(l10n, source),
                subtitle: _sourceSubtitle(l10n, source),
                actionLabel: l10n.resourceEconomyGoToCityAction,
                onTap: () => onCityPressed(source.city),
              ),
          ],
  );
}

class _AgreementsSection extends StatelessWidget {
  const _AgreementsSection({
    required this.l10n,
    required this.agreements,
    required this.activePlayerId,
    required this.gameSave,
  });

  final AppLocalizations l10n;
  final List<ResourceTradeAgreement> agreements;
  final String activePlayerId;
  final GameSave gameSave;

  @override
  Widget build(BuildContext context) => _EconomySection(
    key: const Key('strategicResourceEconomy.agreements'),
    title: l10n.diplomacyResourceTradeActiveTitle,
    children: agreements.isEmpty
        ? [_EmptyState(message: l10n.diplomacyResourceTradeNoActiveAgreements)]
        : [
            for (final agreement in agreements)
              _AgreementRow(
                agreement: agreement,
                activePlayerId: activePlayerId,
                partner: _playerById(
                  gameSave.players,
                  _partnerId(agreement, activePlayerId),
                ),
                l10n: l10n,
              ),
          ],
  );
}

class _PartnersSection extends StatelessWidget {
  const _PartnersSection({
    required this.l10n,
    required this.partners,
    required this.onPressed,
  });

  final AppLocalizations l10n;
  final List<Player> partners;
  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context) => _EconomySection(
    key: const Key('strategicResourceEconomy.partners'),
    title: l10n.resourceEconomyTradePartnersTitle,
    children: partners.isEmpty
        ? [_EmptyState(message: l10n.resourceEconomyNoTradePartners)]
        : [
            for (final partner in partners)
              _TradePartnerRow(
                player: partner,
                l10n: l10n,
                onPressed: () => onPressed(partner.id),
              ),
          ],
  );
}
