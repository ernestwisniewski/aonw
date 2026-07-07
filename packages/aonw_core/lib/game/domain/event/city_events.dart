part of 'game_event.dart';

final class CityFoundedEvent extends GameEvent {
  const CityFoundedEvent({required this.cityId, required this.ownerPlayerId});
  final String cityId;
  final String ownerPlayerId;
}

final class CityBuiltBuildingEvent extends GameEvent {
  const CityBuiltBuildingEvent({
    required this.cityId,
    required this.buildingType,
  });
  final String cityId;
  final CityBuildingType buildingType;
}

final class CityBuiltWonderEvent extends GameEvent {
  const CityBuiltWonderEvent({
    required this.cityId,
    required this.ownerPlayerId,
    required this.wonderType,
  });

  final String cityId;
  final String ownerPlayerId;
  final WonderType wonderType;
}

final class WonderProductionRefundedEvent extends GameEvent {
  const WonderProductionRefundedEvent({
    required this.cityId,
    required this.ownerPlayerId,
    required this.wonderType,
    required this.refundedProduction,
  });

  final String cityId;
  final String ownerPlayerId;
  final WonderType wonderType;
  final int refundedProduction;
}

final class CityProducedUnitEvent extends GameEvent {
  const CityProducedUnitEvent({
    required this.cityId,
    required this.unitType,
    required this.producedUnitId,
  });
  final String cityId;
  final GameUnitType unitType;
  final String producedUnitId;
}

final class CityClaimedHexEvent extends GameEvent {
  const CityClaimedHexEvent({
    required this.cityId,
    required this.col,
    required this.row,
  });
  final String cityId;
  final int col;
  final int row;
}
