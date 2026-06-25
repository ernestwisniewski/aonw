part of 'game_event.dart';

enum StrategicResourceDiscoveryPressure {
  securedSupply,
  expansionRace,
  contestedSupply,
  rivalMonopoly;

  static StrategicResourceDiscoveryPressure fromCounts({
    required int controlledCount,
    required int rivalControlledCount,
    required int unclaimedCount,
  }) {
    if (controlledCount == 0 &&
        rivalControlledCount > 0 &&
        unclaimedCount == 0) {
      return StrategicResourceDiscoveryPressure.rivalMonopoly;
    }
    if (unclaimedCount > 0) {
      return StrategicResourceDiscoveryPressure.expansionRace;
    }
    if (rivalControlledCount > 0) {
      return StrategicResourceDiscoveryPressure.contestedSupply;
    }
    return StrategicResourceDiscoveryPressure.securedSupply;
  }
}

final class StrategicResourceDiscoveredEvent extends GameEvent {
  const StrategicResourceDiscoveredEvent({
    required this.playerId,
    required this.resourceType,
    required this.controlledCount,
    required this.rivalControlledCount,
    required this.unclaimedCount,
    required this.pressure,
    this.nearestUnclaimedCol,
    this.nearestUnclaimedRow,
  });

  final String playerId;
  final ResourceType resourceType;
  final int controlledCount;
  final int rivalControlledCount;
  final int unclaimedCount;
  final StrategicResourceDiscoveryPressure pressure;
  final int? nearestUnclaimedCol;
  final int? nearestUnclaimedRow;
}
