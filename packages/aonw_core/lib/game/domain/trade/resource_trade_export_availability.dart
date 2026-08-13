import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class ResourceTradeExportAvailability {
  static int available({
    required List<GameCity> cities,
    required ResearchState research,
    required Iterable<ResourceTradeAgreement> agreements,
    required String exporterPlayerId,
    required ResourceType resource,
    required MapTileLookup mapTiles,
    required Iterable<FieldImprovement> fieldImprovements,
  }) {
    final committed = _activeExportCount(
      agreements,
      exporterPlayerId: exporterPlayerId,
      resource: resource,
    );
    if (ResourceCatalog.isStockpiled(resource)) {
      final production = StrategicResourceProductionRules.forPlayer(
        playerId: exporterPlayerId,
        cities: cities,
        fieldImprovements: fieldImprovements,
        mapTiles: mapTiles,
        research: research,
      );
      return production.output.amountFor(resource) - committed;
    }
    final inventory = CityResourceInventoryRules.forPlayer(
      playerId: exporterPlayerId,
      cities: cities,
      mapTiles: mapTiles,
      research: research,
    );
    return inventory.countFor(resource) - committed;
  }

  static int _activeExportCount(
    Iterable<ResourceTradeAgreement> agreements, {
    required String exporterPlayerId,
    required ResourceType resource,
  }) => agreements
      .where(
        (agreement) =>
            agreement.exporterPlayerId == exporterPlayerId &&
            agreement.resource == resource &&
            agreement.isActive,
      )
      .fold(0, (total, agreement) => total + agreement.amountPerTurn);
}
