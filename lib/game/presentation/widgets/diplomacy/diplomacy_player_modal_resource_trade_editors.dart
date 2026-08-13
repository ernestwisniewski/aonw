part of 'diplomacy_player_modal_resource_trade.dart';

class _GoldResourceTradeEditor extends StatelessWidget {
  const _GoldResourceTradeEditor({
    required this.l10n,
    required this.gameState,
    required this.activePlayerId,
    required this.targetPlayerId,
    required this.offers,
    required this.selectedResource,
    required this.enabled,
    required this.onSelected,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final GameClientState gameState;
  final String activePlayerId;
  final String targetPlayerId;
  final List<_ResourceTradeOffer> offers;
  final ResourceType? selectedResource;
  final bool enabled;
  final ValueChanged<ResourceType> onSelected;
  final ValueChanged<DomainCommand> onSubmit;

  @override
  Widget build(BuildContext context) {
    final resources = [for (final offer in offers) offer.resource];
    final selected = resources.contains(selectedResource)
        ? selectedResource!
        : resources.first;
    final hasGold =
        (gameState.playerGold[activePlayerId] ?? 0) >=
        _resourceTradeGoldPerTurn;
    final resourceName = GameDisplayNames.resource(l10n, selected);
    return _ResourceTradeEditorCard(
      children: [
        _ResourceTradeSelector(
          key: const Key('diplomacy.resourceTrade.importResource'),
          label: l10n.diplomacyResourceTradeReceiveLabel,
          value: selected,
          values: resources,
          l10n: l10n,
          enabled: enabled,
          onChanged: onSelected,
        ),
        const SizedBox(height: 8),
        _ResourceTradeTerm(
          label: l10n.diplomacyResourceTradeGiveLabel,
          value: l10n.diplomacyResourceTradeGoldPerTurnPrice(
            _resourceTradeGoldPerTurn,
          ),
          icon: GameIcons.gold,
        ),
        const SizedBox(height: 10),
        _ResourceTradeForecast(
          text: l10n.diplomacyResourceTradeGoldForecast(
            resourceName,
            _resourceTradeGoldPerTurn,
            _resourceTradeDurationTurns,
          ),
          hint: hasGold
              ? l10n.diplomacyResourceTradePrivateSupplyHint
              : l10n.diplomacyResourceTradeGoldUnavailable(
                  _resourceTradeGoldPerTurn,
                ),
          warning: !hasGold,
        ),
        const SizedBox(height: 10),
        _ResourceTradeSubmitButton(
          label: l10n.diplomacyResourceTradeImportAction(resourceName),
          icon: GameIcons.route,
          enabled: enabled && hasGold,
          onPressed: () => onSubmit(
            OpenResourceTradeCommand(
              playerId: activePlayerId,
              targetPlayerId: targetPlayerId,
              resource: selected,
              goldPerTurn: _resourceTradeGoldPerTurn,
              durationTurns: _resourceTradeDurationTurns,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExchangeResourceTradeEditor extends StatelessWidget {
  const _ExchangeResourceTradeEditor({
    required this.l10n,
    required this.activePlayerId,
    required this.targetPlayerId,
    required this.offers,
    required this.selectedOfferedResource,
    required this.selectedRequestedResource,
    required this.enabled,
    required this.onOfferedSelected,
    required this.onRequestedSelected,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final String activePlayerId;
  final String targetPlayerId;
  final List<_ResourceExchangeOffer> offers;
  final ResourceType? selectedOfferedResource;
  final ResourceType? selectedRequestedResource;
  final bool enabled;
  final ValueChanged<ResourceType> onOfferedSelected;
  final ValueChanged<ResourceType> onRequestedSelected;
  final ValueChanged<DomainCommand> onSubmit;

  @override
  Widget build(BuildContext context) {
    final offeredResources = {
      for (final offer in offers) offer.offeredResource,
    }.toList(growable: false);
    final offered = offeredResources.contains(selectedOfferedResource)
        ? selectedOfferedResource!
        : offeredResources.first;
    final requestedResources = {
      for (final offer in offers)
        if (offer.offeredResource == offered) offer.requestedResource,
    }.toList(growable: false);
    final requested = requestedResources.contains(selectedRequestedResource)
        ? selectedRequestedResource!
        : requestedResources.first;
    final offeredName = GameDisplayNames.resource(l10n, offered);
    final requestedName = GameDisplayNames.resource(l10n, requested);
    return _ResourceTradeEditorCard(
      children: [
        _ResourceTradeSelector(
          key: const Key('diplomacy.resourceTrade.requestedResource'),
          label: l10n.diplomacyResourceTradeReceiveLabel,
          value: requested,
          values: requestedResources,
          l10n: l10n,
          enabled: enabled,
          onChanged: onRequestedSelected,
        ),
        const SizedBox(height: 8),
        _ResourceTradeSelector(
          key: const Key('diplomacy.resourceTrade.offeredResource'),
          label: l10n.diplomacyResourceTradeGiveLabel,
          value: offered,
          values: offeredResources,
          l10n: l10n,
          enabled: enabled,
          onChanged: onOfferedSelected,
        ),
        const SizedBox(height: 10),
        _ResourceTradeForecast(
          text: l10n.diplomacyResourceTradeExchangeForecast(
            requestedName,
            offeredName,
            _resourceTradeDurationTurns,
          ),
          hint: l10n.diplomacyResourceTradePrivateSupplyHint,
        ),
        const SizedBox(height: 10),
        _ResourceTradeSubmitButton(
          label: l10n.diplomacyResourceTradeExchangeAction(
            offeredName,
            requestedName,
          ),
          icon: GameIcons.split,
          enabled: enabled,
          onPressed: () => onSubmit(
            OpenResourceExchangeCommand(
              playerId: activePlayerId,
              targetPlayerId: targetPlayerId,
              offeredResource: offered,
              requestedResource: requested,
              durationTurns: _resourceTradeDurationTurns,
            ),
          ),
        ),
      ],
    );
  }
}
