part of 'strategic_resource_economy_dialog.dart';

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.agreement,
    required this.activePlayerId,
    required this.partner,
    required this.l10n,
  });

  final ResourceTradeAgreement agreement;
  final String activePlayerId;
  final Player? partner;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final importing = agreement.importerPlayerId == activePlayerId;
    return Container(
      key: Key('strategicResourceEconomy.agreement.${agreement.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          GameIcon(
            GameIcons.diplomacy,
            size: GameIconSize.regular,
            color: importing ? GameUiTheme.success : GameUiTheme.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_partnerLabel(), style: GameUiTheme.bodyStrong),
                const SizedBox(height: 2),
                Text(_flowLabel(importing), style: GameUiTheme.cardMeta),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _partnerLabel() => partner == null
      ? _partnerId(agreement, activePlayerId)
      : '${GameDisplayNames.player(l10n, partner!)} · ${GameDisplayNames.playerCountry(l10n, partner!.country)}';

  String _flowLabel(bool importing) {
    final direction = importing
        ? l10n.diplomacyResourceTradeImportDirection
        : l10n.diplomacyResourceTradeExportDirection;
    final price = agreement.exchangeGroupId == null
        ? l10n.diplomacyResourceTradeGoldPerTurnPrice(agreement.goldPerTurn)
        : l10n.diplomacyResourceTradeBarterPrice;
    return l10n.diplomacyResourceTradeAgreementFlowLabel(
      direction,
      agreement.amountPerTurn,
      GameDisplayNames.resource(l10n, agreement.resource),
      price,
      agreement.remainingTurns,
    );
  }
}

class _TradePartnerRow extends StatelessWidget {
  const _TradePartnerRow({
    required this.player,
    required this.l10n,
    required this.onPressed,
  });

  final Player player;
  final AppLocalizations l10n;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    key: Key('strategicResourceEconomy.partner.${player.id}'),
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 34,
          decoration: ShapeDecoration(
            color: Color(player.colorValue),
            shape: RoundedRectangleBorder(
              borderRadius: GameUiTheme.pillBorderRadius,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameDisplayNames.player(l10n, player),
                style: GameUiTheme.bodyStrong,
              ),
              Text(
                GameDisplayNames.playerCountry(l10n, player.country),
                style: GameUiTheme.cardMeta,
              ),
            ],
          ),
        ),
        EpicButton.outlined(
          key: Key('strategicResourceEconomy.openTrade.${player.id}'),
          label: l10n.resourceEconomyOpenTradeAction,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          iconBuilder: (foreground) => GameIcon(
            GameIcons.diplomacy,
            size: GameIconSize.small,
            color: foreground,
          ),
          onPressed: onPressed,
        ),
      ],
    ),
  );
}
