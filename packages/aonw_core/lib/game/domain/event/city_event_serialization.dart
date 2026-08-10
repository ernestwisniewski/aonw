import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/util/wire_json.dart';

/// Wire codec for city production and territory events.
abstract final class CityEventSerializer {
  static Map<String, dynamic> toJson(GameEvent event) {
    return switch (event) {
      CityBuiltBuildingEvent(:final cityId, :final buildingType) => {
        'type': 'CityBuiltBuilding',
        'cityId': cityId,
        'buildingType': buildingType.name,
      },
      CityBuiltWonderEvent(
        :final cityId,
        :final ownerPlayerId,
        :final wonderType,
      ) =>
        {
          'type': 'CityBuiltWonder',
          'cityId': cityId,
          'ownerPlayerId': ownerPlayerId,
          'wonderType': wonderType.name,
        },
      WonderProductionRefundedEvent(
        :final cityId,
        :final ownerPlayerId,
        :final wonderType,
        :final refundedProduction,
      ) =>
        {
          'type': 'WonderProductionRefunded',
          'cityId': cityId,
          'ownerPlayerId': ownerPlayerId,
          'wonderType': wonderType.name,
          'refundedProduction': refundedProduction,
        },
      CityProducedUnitEvent(
        :final cityId,
        :final unitType,
        :final producedUnitId,
      ) =>
        {
          'type': 'CityProducedUnit',
          'cityId': cityId,
          'unitType': unitType.name,
          'producedUnitId': producedUnitId,
        },
      CityClaimedHexEvent(:final cityId, :final col, :final row) => {
        'type': 'CityClaimedHex',
        'cityId': cityId,
        'col': col,
        'row': row,
      },
      _ => throw ArgumentError.value(event, 'event', 'Not a city event'),
    };
  }

  static GameEvent? tryFromJson(Map<String, dynamic> json, String type) {
    return switch (type) {
      'CityBuiltBuilding' => CityBuiltBuildingEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        buildingType: requiredEnumField(
          json,
          type,
          'buildingType',
          CityBuildingType.values,
        ),
      ),
      'CityBuiltWonder' => CityBuiltWonderEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
        wonderType: requiredEnumField(
          json,
          type,
          'wonderType',
          WonderType.values,
        ),
      ),
      'WonderProductionRefunded' => WonderProductionRefundedEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
        wonderType: requiredEnumField(
          json,
          type,
          'wonderType',
          WonderType.values,
        ),
        refundedProduction: requiredIntField(json, type, 'refundedProduction'),
      ),
      'CityProducedUnit' => CityProducedUnitEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        unitType: requiredEnumField(
          json,
          type,
          'unitType',
          GameUnitType.values,
        ),
        producedUnitId: requiredStringField(json, type, 'producedUnitId'),
      ),
      'CityClaimedHex' => CityClaimedHexEvent(
        cityId: requiredStringField(json, type, 'cityId'),
        col: requiredIntField(json, type, 'col'),
        row: requiredIntField(json, type, 'row'),
      ),
      _ => null,
    };
  }
}
