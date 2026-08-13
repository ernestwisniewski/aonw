part of 'diplomacy_player_modal_resource_trade.dart';

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
  required GameClientState gameState,
  required WorldMap mapData,
  required String activePlayerId,
  required String targetPlayerId,
}) {
  final activeInventory = CityResourceInventoryRules.forPlayer(
    playerId: activePlayerId,
    cities: gameState.cities,
    mapTiles: mapData,
    research: gameState.research,
  );
  final offers = <_ResourceTradeOffer>[];
  for (final resource in _strategicTradeResources) {
    if (_alreadyControlsPresenceResource(activeInventory, resource)) {
      continue;
    }
    if (_activeImportCount(
          gameState.resourceTradeAgreements,
          importerPlayerId: activePlayerId,
          exporterPlayerId: targetPlayerId,
          resource: resource,
        ) >
        0) {
      continue;
    }
    final availableExports = ResourceTradeExportAvailability.available(
      cities: gameState.cities,
      research: gameState.research,
      agreements: gameState.resourceTradeAgreements,
      exporterPlayerId: targetPlayerId,
      resource: resource,
      mapTiles: mapData,
      fieldImprovements: gameState.fieldImprovements,
    );
    if (availableExports > 0) {
      offers.add(_ResourceTradeOffer(resource: resource));
    }
  }
  return List.unmodifiable(offers);
}

List<_ResourceExchangeOffer> _resourceExchangeOffers({
  required GameClientState gameState,
  required WorldMap mapData,
  required String activePlayerId,
  required String targetPlayerId,
}) {
  final activeInventory = CityResourceInventoryRules.forPlayer(
    playerId: activePlayerId,
    cities: gameState.cities,
    mapTiles: mapData,
    research: gameState.research,
  );
  final offers = <_ResourceExchangeOffer>[];
  for (final offeredResource in _strategicTradeResources) {
    final availableOffer = ResourceTradeExportAvailability.available(
      cities: gameState.cities,
      research: gameState.research,
      agreements: gameState.resourceTradeAgreements,
      exporterPlayerId: activePlayerId,
      resource: offeredResource,
      mapTiles: mapData,
      fieldImprovements: gameState.fieldImprovements,
    );
    if (availableOffer <= 0) continue;
    for (final requestedResource in _strategicTradeResources) {
      if (requestedResource == offeredResource) continue;
      if (_alreadyControlsPresenceResource(
        activeInventory,
        requestedResource,
      )) {
        continue;
      }
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
      final availableRequest = ResourceTradeExportAvailability.available(
        cities: gameState.cities,
        research: gameState.research,
        agreements: gameState.resourceTradeAgreements,
        exporterPlayerId: targetPlayerId,
        resource: requestedResource,
        mapTiles: mapData,
        fieldImprovements: gameState.fieldImprovements,
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

Iterable<ResourceType> get _strategicTradeResources =>
    ResourceCatalog.strategicResources;

bool _alreadyControlsPresenceResource(
  CityResourceInventory inventory,
  ResourceType resource,
) => !ResourceCatalog.isStockpiled(resource) && inventory.controls(resource);

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
