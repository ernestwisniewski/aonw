part of 'diplomacy_player_modal.dart';

const int _resourceTradeGoldPerTurn = 2;
const int _resourceTradeDurationTurns = 8;

class _ResourceTradeSection extends StatelessWidget {
  const _ResourceTradeSection({
    required this.l10n,
    required this.gameState,
    required this.mapData,
    required this.relation,
    required this.activePlayerId,
    required this.targetPlayerId,
    required this.onCommand,
  });

  final AppLocalizations l10n;
  final GameState gameState;
  final MapData mapData;
  final DiplomaticRelation relation;
  final String activePlayerId;
  final String targetPlayerId;
  final Future<void> Function(GameCommand command) onCommand;

  @override
  Widget build(BuildContext context) {
    final offers = _resourceTradeOffers(
      gameState: gameState,
      mapData: mapData,
      activePlayerId: activePlayerId,
      targetPlayerId: targetPlayerId,
    );
    final exchangeOffers = _resourceExchangeOffers(
      gameState: gameState,
      mapData: mapData,
      activePlayerId: activePlayerId,
      targetPlayerId: targetPlayerId,
    );
    final blockedByWar = relation.status == DiplomaticRelationStatus.war;
    return _Section(
      title: l10n.diplomacyStrategicResourcesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offers.isEmpty && exchangeOffers.isEmpty)
            Text(
              blockedByWar
                  ? l10n.diplomacyResourceTradeBlockedByWar
                  : l10n.diplomacyResourceTradeNoAvailableResources,
              style: GameUiTheme.bodySmall,
            )
          else if (offers.isNotEmpty) ...[
            Text(
              l10n.diplomacyResourceTradeImportOffer(
                _resourceTradeGoldPerTurn,
                _resourceTradeDurationTurns,
              ),
              style: GameUiTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final offer in offers)
                  EpicButton.outlined(
                    key: Key('diplomacy.resourceTrade.${offer.resource.name}'),
                    label: l10n.diplomacyResourceTradeImportAction(
                      GameDisplayNames.resource(l10n, offer.resource),
                    ),
                    iconBuilder: (color) =>
                        GameIcon(GameIcons.route, size: 16, color: color),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    onPressed: blockedByWar
                        ? null
                        : () => unawaited(
                            onCommand(
                              OpenResourceTradeCommand(
                                playerId: activePlayerId,
                                targetPlayerId: targetPlayerId,
                                resource: offer.resource,
                                goldPerTurn: _resourceTradeGoldPerTurn,
                                durationTurns: _resourceTradeDurationTurns,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ],
          if (offers.isNotEmpty && exchangeOffers.isNotEmpty)
            const SizedBox(height: 12),
          if (exchangeOffers.isNotEmpty) ...[
            Text(
              l10n.diplomacyResourceTradeExchangeOffer(
                _resourceTradeDurationTurns,
              ),
              style: GameUiTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final offer in exchangeOffers)
                  EpicButton.outlined(
                    key: Key(
                      'diplomacy.resourceExchange.${offer.offeredResource.name}.${offer.requestedResource.name}',
                    ),
                    label: l10n.diplomacyResourceTradeExchangeAction(
                      GameDisplayNames.resource(l10n, offer.offeredResource),
                      GameDisplayNames.resource(l10n, offer.requestedResource),
                    ),
                    iconBuilder: (color) =>
                        GameIcon(GameIcons.split, size: 16, color: color),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    onPressed: blockedByWar
                        ? null
                        : () => unawaited(
                            onCommand(
                              OpenResourceExchangeCommand(
                                playerId: activePlayerId,
                                targetPlayerId: targetPlayerId,
                                offeredResource: offer.offeredResource,
                                requestedResource: offer.requestedResource,
                                durationTurns: _resourceTradeDurationTurns,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _ResourceTradeSummary(
            l10n: l10n,
            gameState: gameState,
            activePlayerId: activePlayerId,
            targetPlayerId: targetPlayerId,
          ),
        ],
      ),
    );
  }
}

class _ResourceTradeSummary extends StatelessWidget {
  const _ResourceTradeSummary({
    required this.l10n,
    required this.gameState,
    required this.activePlayerId,
    required this.targetPlayerId,
  });

  final AppLocalizations l10n;
  final GameState gameState;
  final String activePlayerId;
  final String targetPlayerId;

  @override
  Widget build(BuildContext context) {
    final agreements = [
      for (final agreement in gameState.resourceTradeAgreements)
        if (agreement.isActive &&
            ((agreement.importerPlayerId == activePlayerId &&
                    agreement.exporterPlayerId == targetPlayerId) ||
                (agreement.importerPlayerId == targetPlayerId &&
                    agreement.exporterPlayerId == activePlayerId)))
          agreement,
    ];
    if (agreements.isEmpty) {
      return Text(
        l10n.diplomacyResourceTradeNoActiveAgreements,
        style: GameUiTheme.bodySmall.copyWith(color: GameUiTheme.textTertiary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final agreement in agreements)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              _agreementLabel(agreement),
              style: GameUiTheme.bodySmall.copyWith(
                color: GameUiTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  String _agreementLabel(ResourceTradeAgreement agreement) {
    final resourceName = GameDisplayNames.resource(l10n, agreement.resource);
    final direction = agreement.importerPlayerId == activePlayerId
        ? l10n.diplomacyResourceTradeImportDirection
        : l10n.diplomacyResourceTradeExportDirection;
    final price = agreement.goldPerTurn == 0
        ? l10n.diplomacyResourceTradeBarterPrice
        : l10n.diplomacyResourceTradeGoldPerTurnPrice(agreement.goldPerTurn);
    return l10n.diplomacyResourceTradeAgreementLabel(
      direction,
      resourceName,
      price,
      agreement.remainingTurns,
    );
  }
}
