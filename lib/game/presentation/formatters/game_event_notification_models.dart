part of 'game_event_notification_message.dart';

sealed class GameEventNotificationThumbnail {
  const GameEventNotificationThumbnail();
}

final class TechnologyEventNotificationThumbnail
    extends GameEventNotificationThumbnail {
  final TechnologyId technologyId;

  const TechnologyEventNotificationThumbnail(this.technologyId);
}

final class BuildingEventNotificationThumbnail
    extends GameEventNotificationThumbnail {
  final CityBuildingType buildingType;

  const BuildingEventNotificationThumbnail(this.buildingType);
}

final class UnitEventNotificationThumbnail
    extends GameEventNotificationThumbnail {
  final GameUnitType unitType;

  const UnitEventNotificationThumbnail(this.unitType);
}

final class CityEventNotificationThumbnail
    extends GameEventNotificationThumbnail {
  const CityEventNotificationThumbnail();
}

final class CombatEventNotificationThumbnail
    extends GameEventNotificationThumbnail {
  const CombatEventNotificationThumbnail();
}

enum EventNotificationIconThumbnailKind {
  science,
  turn,
  success,
  warning,
  civilization,
}

final class IconEventNotificationThumbnail
    extends GameEventNotificationThumbnail {
  final EventNotificationIconThumbnailKind kind;

  const IconEventNotificationThumbnail(this.kind);
}
