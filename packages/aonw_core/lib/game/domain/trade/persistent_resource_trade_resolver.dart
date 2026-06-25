import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/trade/resource_trade_agreement.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class PersistentResourceTradeResult {
  const PersistentResourceTradeResult({
    required this.accepted,
    required this.state,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final String? reason;
}

class PersistentResourceTradeResolver {
  const PersistentResourceTradeResolver();

  PersistentResourceTradeResult openGoldForResourceTrade({
    required PersistentGameState state,
    required String importerPlayerId,
    required String exporterPlayerId,
    required ResourceType resource,
    required int goldPerTurn,
    required int durationTurns,
    required MapData mapData,
    String? agreementId,
  }) {
    if (importerPlayerId.isEmpty || exporterPlayerId.isEmpty) {
      return _reject(state, 'invalid_resource_trade_player');
    }
    if (importerPlayerId == exporterPlayerId) {
      return _reject(state, 'invalid_resource_trade_target');
    }
    if (goldPerTurn < 0 || durationTurns <= 0) {
      return _reject(state, 'invalid_resource_trade_terms');
    }
    final relation = state.runtimeState.diplomacy.statusBetween(
      importerPlayerId,
      exporterPlayerId,
    );
    if (relation == DiplomaticRelationStatus.war) {
      return _reject(state, 'resource_trade_blocked_by_war');
    }
    if ((state.playerGold[importerPlayerId] ?? 0) < goldPerTurn) {
      return _reject(state, 'resource_trade_gold_unavailable');
    }
    if (_hasActiveDuplicate(
      state.runtimeState.resourceTradeAgreements,
      importerPlayerId: importerPlayerId,
      exporterPlayerId: exporterPlayerId,
      resource: resource,
    )) {
      return _reject(state, 'resource_trade_already_active');
    }

    final exporterInventory = CityResourceInventoryRules.forPlayer(
      playerId: exporterPlayerId,
      cities: state.cities,
      mapData: mapData,
      research: state.research,
    );
    final availableExports =
        exporterInventory.countFor(resource) -
        _activeExportCount(
          state.runtimeState.resourceTradeAgreements,
          exporterPlayerId: exporterPlayerId,
          resource: resource,
        );
    if (availableExports <= 0) {
      return _reject(state, 'resource_trade_export_unavailable');
    }

    final agreement = ResourceTradeAgreement(
      id:
          agreementId ??
          _agreementId(
            importerPlayerId: importerPlayerId,
            exporterPlayerId: exporterPlayerId,
            resource: resource,
            count: state.runtimeState.resourceTradeAgreements.length,
          ),
      exporterPlayerId: exporterPlayerId,
      importerPlayerId: importerPlayerId,
      resource: resource,
      goldPerTurn: goldPerTurn,
      remainingTurns: durationTurns,
    );
    return PersistentResourceTradeResult(
      accepted: true,
      state: state.copyWith(
        runtimeState: state.runtimeState.copyWith(
          resourceTradeAgreements: List.unmodifiable([
            ...state.runtimeState.resourceTradeAgreements,
            agreement,
          ]),
        ),
      ),
    );
  }

  PersistentResourceTradeResult openResourceForResourceTrade({
    required PersistentGameState state,
    required String playerId,
    required String targetPlayerId,
    required ResourceType offeredResource,
    required ResourceType requestedResource,
    required int durationTurns,
    required MapData mapData,
    String? agreementId,
  }) {
    if (playerId.isEmpty || targetPlayerId.isEmpty) {
      return _reject(state, 'invalid_resource_trade_player');
    }
    if (playerId == targetPlayerId) {
      return _reject(state, 'invalid_resource_trade_target');
    }
    if (offeredResource == requestedResource || durationTurns <= 0) {
      return _reject(state, 'invalid_resource_trade_terms');
    }
    final relation = state.runtimeState.diplomacy.statusBetween(
      playerId,
      targetPlayerId,
    );
    if (relation == DiplomaticRelationStatus.war) {
      return _reject(state, 'resource_trade_blocked_by_war');
    }
    if (_hasActiveDuplicate(
      state.runtimeState.resourceTradeAgreements,
      importerPlayerId: playerId,
      exporterPlayerId: targetPlayerId,
      resource: requestedResource,
    )) {
      return _reject(state, 'resource_trade_already_active');
    }
    if (_hasActiveDuplicate(
      state.runtimeState.resourceTradeAgreements,
      importerPlayerId: targetPlayerId,
      exporterPlayerId: playerId,
      resource: offeredResource,
    )) {
      return _reject(state, 'resource_trade_already_active');
    }

    if (_availableExports(
          state: state,
          exporterPlayerId: playerId,
          resource: offeredResource,
          mapData: mapData,
        ) <=
        0) {
      return _reject(state, 'resource_trade_offer_unavailable');
    }
    if (_availableExports(
          state: state,
          exporterPlayerId: targetPlayerId,
          resource: requestedResource,
          mapData: mapData,
        ) <=
        0) {
      return _reject(state, 'resource_trade_request_unavailable');
    }

    final baseId =
        agreementId ??
        _exchangeAgreementId(
          playerId: playerId,
          targetPlayerId: targetPlayerId,
          offeredResource: offeredResource,
          requestedResource: requestedResource,
          count: state.runtimeState.resourceTradeAgreements.length,
        );
    final requestedAgreement = ResourceTradeAgreement(
      id: '${baseId}_requested',
      exporterPlayerId: targetPlayerId,
      importerPlayerId: playerId,
      resource: requestedResource,
      goldPerTurn: 0,
      remainingTurns: durationTurns,
    );
    final offeredAgreement = ResourceTradeAgreement(
      id: '${baseId}_offered',
      exporterPlayerId: playerId,
      importerPlayerId: targetPlayerId,
      resource: offeredResource,
      goldPerTurn: 0,
      remainingTurns: durationTurns,
    );
    return PersistentResourceTradeResult(
      accepted: true,
      state: state.copyWith(
        runtimeState: state.runtimeState.copyWith(
          resourceTradeAgreements: List.unmodifiable([
            ...state.runtimeState.resourceTradeAgreements,
            requestedAgreement,
            offeredAgreement,
          ]),
        ),
      ),
    );
  }

  PersistentResourceTradeResult _reject(
    PersistentGameState state,
    String reason,
  ) {
    return PersistentResourceTradeResult(
      accepted: false,
      state: state,
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

  static int _activeExportCount(
    Iterable<ResourceTradeAgreement> agreements, {
    required String exporterPlayerId,
    required ResourceType resource,
  }) {
    var count = 0;
    for (final agreement in agreements) {
      if (agreement.exporterPlayerId == exporterPlayerId &&
          agreement.resource == resource &&
          agreement.isActive) {
        count += 1;
      }
    }
    return count;
  }

  static int _availableExports({
    required PersistentGameState state,
    required String exporterPlayerId,
    required ResourceType resource,
    required MapData mapData,
  }) {
    final inventory = CityResourceInventoryRules.forPlayer(
      playerId: exporterPlayerId,
      cities: state.cities,
      mapData: mapData,
      research: state.research,
    );
    return inventory.countFor(resource) -
        _activeExportCount(
          state.runtimeState.resourceTradeAgreements,
          exporterPlayerId: exporterPlayerId,
          resource: resource,
        );
  }

  static String _agreementId({
    required String importerPlayerId,
    required String exporterPlayerId,
    required ResourceType resource,
    required int count,
  }) {
    return 'resource_trade_${importerPlayerId}_${exporterPlayerId}_${resource.name}_$count';
  }

  static String _exchangeAgreementId({
    required String playerId,
    required String targetPlayerId,
    required ResourceType offeredResource,
    required ResourceType requestedResource,
    required int count,
  }) {
    return 'resource_exchange_${playerId}_${targetPlayerId}_${offeredResource.name}_${requestedResource.name}_$count';
  }
}
