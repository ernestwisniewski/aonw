import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_export_availability.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

/// Persistence-neutral result of opening a resource trade.
final class ResourceTradeCommandResult {
  const ResourceTradeCommandResult._accepted({
    required this.resourceTradeAgreements,
  }) : accepted = true,
       reason = null;

  const ResourceTradeCommandResult._rejected({
    required this.resourceTradeAgreements,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<ResourceTradeAgreement> resourceTradeAgreements;
}

/// Applies resource-trade rules without depending on a state container.
abstract final class ResourceTradeCommandResolver {
  static ResourceTradeCommandResult openGoldForResourceTrade({
    required Map<String, int> playerGold,
    required List<GameCity> cities,
    required ResearchState research,
    required DiplomacyState diplomacy,
    required List<ResourceTradeAgreement> resourceTradeAgreements,
    required OpenResourceTradeCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    Iterable<FieldImprovement> fieldImprovements = const [],
    StrategicResourceEconomyProfile strategicResourceEconomy =
        StrategicResourceEconomyProfile.legacyPresenceV0,
  }) {
    final requestReason = _goldRequestRejectionReason(command, actorPlayerId);
    if (requestReason != null) {
      return _reject(resourceTradeAgreements, requestReason);
    }
    final permissionReason = _goldPermissionRejectionReason(
      command: command,
      playerGold: playerGold,
      diplomacy: diplomacy,
      resourceTradeAgreements: resourceTradeAgreements,
    );
    if (permissionReason != null) {
      return _reject(resourceTradeAgreements, permissionReason);
    }
    if (ResourceTradeExportAvailability.available(
          cities: cities,
          research: research,
          agreements: resourceTradeAgreements,
          exporterPlayerId: command.targetPlayerId,
          resource: command.resource,
          mapTiles: mapTiles,
          fieldImprovements: fieldImprovements,
          strategicResourceEconomy: strategicResourceEconomy,
        ) <=
        0) {
      return _reject(
        resourceTradeAgreements,
        'resource_trade_export_unavailable',
      );
    }

    return ResourceTradeCommandResult._accepted(
      resourceTradeAgreements: List.unmodifiable([
        ...resourceTradeAgreements,
        _goldAgreement(command, resourceTradeAgreements.length),
      ]),
    );
  }

  static ResourceTradeCommandResult openResourceForResourceTrade({
    required List<GameCity> cities,
    required ResearchState research,
    required DiplomacyState diplomacy,
    required List<ResourceTradeAgreement> resourceTradeAgreements,
    required OpenResourceExchangeCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    Iterable<FieldImprovement> fieldImprovements = const [],
    StrategicResourceEconomyProfile strategicResourceEconomy =
        StrategicResourceEconomyProfile.legacyPresenceV0,
  }) {
    final requestReason = _exchangeRequestRejectionReason(
      command,
      actorPlayerId,
    );
    if (requestReason != null) {
      return _reject(resourceTradeAgreements, requestReason);
    }
    final permissionReason = _exchangePermissionRejectionReason(
      command: command,
      diplomacy: diplomacy,
      resourceTradeAgreements: resourceTradeAgreements,
    );
    if (permissionReason != null) {
      return _reject(resourceTradeAgreements, permissionReason);
    }
    final availabilityReason = _exchangeAvailabilityRejectionReason(
      cities: cities,
      research: research,
      resourceTradeAgreements: resourceTradeAgreements,
      command: command,
      mapTiles: mapTiles,
      fieldImprovements: fieldImprovements,
      strategicResourceEconomy: strategicResourceEconomy,
    );
    if (availabilityReason != null) {
      return _reject(resourceTradeAgreements, availabilityReason);
    }
    return ResourceTradeCommandResult._accepted(
      resourceTradeAgreements: _exchangeAgreements(
        resourceTradeAgreements,
        command,
      ),
    );
  }

  static String? _goldRequestRejectionReason(
    OpenResourceTradeCommand command,
    String actorPlayerId,
  ) {
    if (command.playerId != actorPlayerId) {
      return 'resource_trade_player_not_controlled';
    }
    if (command.playerId.isEmpty || command.targetPlayerId.isEmpty) {
      return 'invalid_resource_trade_player';
    }
    if (command.playerId == command.targetPlayerId) {
      return 'invalid_resource_trade_target';
    }
    if (command.goldPerTurn < 0 || command.durationTurns <= 0) {
      return 'invalid_resource_trade_terms';
    }
    return null;
  }

  static String? _goldPermissionRejectionReason({
    required OpenResourceTradeCommand command,
    required Map<String, int> playerGold,
    required DiplomacyState diplomacy,
    required List<ResourceTradeAgreement> resourceTradeAgreements,
  }) {
    if (_atWar(diplomacy, command.playerId, command.targetPlayerId)) {
      return 'resource_trade_blocked_by_war';
    }
    if ((playerGold[command.playerId] ?? 0) < command.goldPerTurn) {
      return 'resource_trade_gold_unavailable';
    }
    if (_hasActiveDuplicate(
      resourceTradeAgreements,
      importerPlayerId: command.playerId,
      exporterPlayerId: command.targetPlayerId,
      resource: command.resource,
    )) {
      return 'resource_trade_already_active';
    }
    return null;
  }

  static String? _exchangeRequestRejectionReason(
    OpenResourceExchangeCommand command,
    String actorPlayerId,
  ) {
    if (command.playerId != actorPlayerId) {
      return 'resource_trade_player_not_controlled';
    }
    if (command.playerId.isEmpty || command.targetPlayerId.isEmpty) {
      return 'invalid_resource_trade_player';
    }
    if (command.playerId == command.targetPlayerId) {
      return 'invalid_resource_trade_target';
    }
    if (command.offeredResource == command.requestedResource ||
        command.durationTurns <= 0) {
      return 'invalid_resource_trade_terms';
    }
    return null;
  }

  static String? _exchangePermissionRejectionReason({
    required OpenResourceExchangeCommand command,
    required DiplomacyState diplomacy,
    required List<ResourceTradeAgreement> resourceTradeAgreements,
  }) {
    if (_atWar(diplomacy, command.playerId, command.targetPlayerId)) {
      return 'resource_trade_blocked_by_war';
    }
    if (_hasActiveDuplicate(
      resourceTradeAgreements,
      importerPlayerId: command.playerId,
      exporterPlayerId: command.targetPlayerId,
      resource: command.requestedResource,
    )) {
      return 'resource_trade_already_active';
    }
    if (_hasActiveDuplicate(
      resourceTradeAgreements,
      importerPlayerId: command.targetPlayerId,
      exporterPlayerId: command.playerId,
      resource: command.offeredResource,
    )) {
      return 'resource_trade_already_active';
    }
    return null;
  }

  static String? _exchangeAvailabilityRejectionReason({
    required List<GameCity> cities,
    required ResearchState research,
    required List<ResourceTradeAgreement> resourceTradeAgreements,
    required OpenResourceExchangeCommand command,
    required MapTileLookup mapTiles,
    required Iterable<FieldImprovement> fieldImprovements,
    required StrategicResourceEconomyProfile strategicResourceEconomy,
  }) {
    if (ResourceTradeExportAvailability.available(
          cities: cities,
          research: research,
          agreements: resourceTradeAgreements,
          exporterPlayerId: command.playerId,
          resource: command.offeredResource,
          mapTiles: mapTiles,
          fieldImprovements: fieldImprovements,
          strategicResourceEconomy: strategicResourceEconomy,
        ) <=
        0) {
      return 'resource_trade_offer_unavailable';
    }
    if (ResourceTradeExportAvailability.available(
          cities: cities,
          research: research,
          agreements: resourceTradeAgreements,
          exporterPlayerId: command.targetPlayerId,
          resource: command.requestedResource,
          mapTiles: mapTiles,
          fieldImprovements: fieldImprovements,
          strategicResourceEconomy: strategicResourceEconomy,
        ) <=
        0) {
      return 'resource_trade_request_unavailable';
    }
    return null;
  }

  static ResourceTradeAgreement _goldAgreement(
    OpenResourceTradeCommand command,
    int agreementCount,
  ) {
    return ResourceTradeAgreement(
      id:
          command.agreementId ??
          _agreementId(
            importerPlayerId: command.playerId,
            exporterPlayerId: command.targetPlayerId,
            resource: command.resource,
            count: agreementCount,
          ),
      exporterPlayerId: command.targetPlayerId,
      importerPlayerId: command.playerId,
      resource: command.resource,
      goldPerTurn: command.goldPerTurn,
      remainingTurns: command.durationTurns,
    );
  }

  static List<ResourceTradeAgreement> _exchangeAgreements(
    List<ResourceTradeAgreement> resourceTradeAgreements,
    OpenResourceExchangeCommand command,
  ) {
    final baseId =
        command.agreementId ??
        _exchangeAgreementId(
          playerId: command.playerId,
          targetPlayerId: command.targetPlayerId,
          offeredResource: command.offeredResource,
          requestedResource: command.requestedResource,
          count: resourceTradeAgreements.length,
        );
    return List.unmodifiable([
      ...resourceTradeAgreements,
      ResourceTradeAgreement(
        id: '${baseId}_requested',
        exporterPlayerId: command.targetPlayerId,
        importerPlayerId: command.playerId,
        resource: command.requestedResource,
        goldPerTurn: 0,
        remainingTurns: command.durationTurns,
        exchangeGroupId: baseId,
      ),
      ResourceTradeAgreement(
        id: '${baseId}_offered',
        exporterPlayerId: command.playerId,
        importerPlayerId: command.targetPlayerId,
        resource: command.offeredResource,
        goldPerTurn: 0,
        remainingTurns: command.durationTurns,
        exchangeGroupId: baseId,
      ),
    ]);
  }

  static bool _atWar(
    DiplomacyState diplomacy,
    String playerId,
    String targetPlayerId,
  ) {
    return diplomacy.statusBetween(playerId, targetPlayerId) ==
        DiplomaticRelationStatus.war;
  }

  static ResourceTradeCommandResult _reject(
    List<ResourceTradeAgreement> resourceTradeAgreements,
    String reason,
  ) {
    return ResourceTradeCommandResult._rejected(
      resourceTradeAgreements: resourceTradeAgreements,
      reason: reason,
    );
  }

  static bool _hasActiveDuplicate(
    Iterable<ResourceTradeAgreement> agreements, {
    required String importerPlayerId,
    required String exporterPlayerId,
    required ResourceType resource,
  }) {
    for (final agreement in agreements) {
      if (agreement.importerPlayerId == importerPlayerId &&
          agreement.exporterPlayerId == exporterPlayerId &&
          agreement.resource == resource &&
          agreement.isActive) {
        return true;
      }
    }
    return false;
  }
}

String _agreementId({
  required String importerPlayerId,
  required String exporterPlayerId,
  required ResourceType resource,
  required int count,
}) {
  return 'resource_trade_${importerPlayerId}_${exporterPlayerId}_${resource.name}_$count';
}

String _exchangeAgreementId({
  required String playerId,
  required String targetPlayerId,
  required ResourceType offeredResource,
  required ResourceType requestedResource,
  required int count,
}) {
  return 'resource_exchange_${playerId}_${targetPlayerId}_${offeredResource.name}_${requestedResource.name}_$count';
}
