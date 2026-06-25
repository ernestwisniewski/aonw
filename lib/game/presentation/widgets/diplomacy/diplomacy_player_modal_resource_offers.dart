part of 'diplomacy_player_modal.dart';

class _ResourceTradeOffer {
  const _ResourceTradeOffer({required this.resource});

  final ResourceType resource;
}

class _ResourceExchangeOffer {
  const _ResourceExchangeOffer({
    required this.offeredResource,
    required this.requestedResource,
  });

  final ResourceType offeredResource;
  final ResourceType requestedResource;
}

List<_ResourceTradeOffer> _resourceTradeOffers({
  required GameState gameState,
  required MapData mapData,
  required String activePlayerId,
  required String targetPlayerId,
}) {
  final activeInventory = CityResourceInventoryRules.forPlayer(
    playerId: activePlayerId,
    cities: gameState.cities,
    mapData: mapData,
    research: gameState.research,
  );
  final targetInventory = CityResourceInventoryRules.forPlayer(
    playerId: targetPlayerId,
    cities: gameState.cities,
    mapData: mapData,
    research: gameState.research,
  );

  final offers = <_ResourceTradeOffer>[];
  for (final resource in _strategicTradeResources) {
    if (activeInventory.countFor(resource) > 0) continue;
    if (_activeImportCount(
          gameState.resourceTradeAgreements,
          importerPlayerId: activePlayerId,
          exporterPlayerId: targetPlayerId,
          resource: resource,
        ) >
        0) {
      continue;
    }
    final availableExports =
        targetInventory.countFor(resource) -
        _activeExportCount(
          gameState.resourceTradeAgreements,
          exporterPlayerId: targetPlayerId,
          resource: resource,
        );
    if (availableExports > 0) {
      offers.add(_ResourceTradeOffer(resource: resource));
    }
  }
  return List.unmodifiable(offers);
}

List<_ResourceExchangeOffer> _resourceExchangeOffers({
  required GameState gameState,
  required MapData mapData,
  required String activePlayerId,
  required String targetPlayerId,
}) {
  final activeInventory = CityResourceInventoryRules.forPlayer(
    playerId: activePlayerId,
    cities: gameState.cities,
    mapData: mapData,
    research: gameState.research,
  );
  final targetInventory = CityResourceInventoryRules.forPlayer(
    playerId: targetPlayerId,
    cities: gameState.cities,
    mapData: mapData,
    research: gameState.research,
  );

  final offers = <_ResourceExchangeOffer>[];
  for (final offeredResource in _strategicTradeResources) {
    final availableOffer =
        activeInventory.countFor(offeredResource) -
        _activeExportCount(
          gameState.resourceTradeAgreements,
          exporterPlayerId: activePlayerId,
          resource: offeredResource,
        );
    if (availableOffer <= 0) continue;

    for (final requestedResource in _strategicTradeResources) {
      if (requestedResource == offeredResource) continue;
      if (activeInventory.countFor(requestedResource) > 0) continue;
      if (_activeImportCount(
            gameState.resourceTradeAgreements,
            importerPlayerId: activePlayerId,
            exporterPlayerId: targetPlayerId,
            resource: requestedResource,
          ) >
          0) {
        continue;
      }
      if (_activeImportCount(
            gameState.resourceTradeAgreements,
            importerPlayerId: targetPlayerId,
            exporterPlayerId: activePlayerId,
            resource: offeredResource,
          ) >
          0) {
        continue;
      }

      final availableRequest =
          targetInventory.countFor(requestedResource) -
          _activeExportCount(
            gameState.resourceTradeAgreements,
            exporterPlayerId: targetPlayerId,
            resource: requestedResource,
          );
      if (availableRequest > 0) {
        offers.add(
          _ResourceExchangeOffer(
            offeredResource: offeredResource,
            requestedResource: requestedResource,
          ),
        );
      }
    }
  }
  return List.unmodifiable(offers);
}

const _strategicTradeResources = [
  ResourceType.horses,
  ResourceType.iron,
  ResourceType.coal,
  ResourceType.oil,
  ResourceType.aluminium,
  ResourceType.uranium,
];

int _activeImportCount(
  Iterable<ResourceTradeAgreement> agreements, {
  required String importerPlayerId,
  required String exporterPlayerId,
  required ResourceType resource,
}) {
  var count = 0;
  for (final agreement in agreements) {
    if (agreement.isActive &&
        agreement.importerPlayerId == importerPlayerId &&
        agreement.exporterPlayerId == exporterPlayerId &&
        agreement.resource == resource) {
      count += 1;
    }
  }
  return count;
}

int _activeExportCount(
  Iterable<ResourceTradeAgreement> agreements, {
  required String exporterPlayerId,
  required ResourceType resource,
}) {
  var count = 0;
  for (final agreement in agreements) {
    if (agreement.isActive &&
        agreement.exporterPlayerId == exporterPlayerId &&
        agreement.resource == resource) {
      count += 1;
    }
  }
  return count;
}
