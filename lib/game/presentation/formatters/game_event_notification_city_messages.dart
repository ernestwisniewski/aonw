part of 'game_event_notification_message.dart';

GameEventNotificationMessage _cityNotificationMessage({
  required AppLocalizations l10n,
  required _GameEventPlayerRoster? roster,
  required GameState state,
  required GameActivityContext activityContext,
  required GameEvent event,
}) {
  return switch (event) {
    CityFoundedEvent(:final cityId, :final ownerPlayerId) =>
      GameEventNotificationMessage(
        title: l10n.eventCityFoundedTitle,
        body:
            '${_cityName(l10n, state, cityId, activityContext)} (${_playerName(l10n, roster, ownerPlayerId)})',
        thumbnail: const CityEventNotificationThumbnail(),
      ),
    CityBuiltBuildingEvent(:final cityId, :final buildingType) =>
      GameEventNotificationMessage(
        title: l10n.eventCityBuiltBuildingTitle,
        body:
            '${_cityName(l10n, state, cityId, activityContext)}: ${GameDisplayNames.cityBuilding(l10n, buildingType)}',
        thumbnail: BuildingEventNotificationThumbnail(buildingType),
      ),
    CityBuiltWonderEvent(:final cityId, :final wonderType) =>
      GameEventNotificationMessage(
        title: l10n.eventCityBuiltBuildingTitle,
        body:
            '${_cityName(l10n, state, cityId, activityContext)}: ${wonderType.displayName}',
        thumbnail: const IconEventNotificationThumbnail(
          EventNotificationIconThumbnailKind.success,
        ),
      ),
    WonderProductionRefundedEvent(
      :final cityId,
      :final wonderType,
      :final refundedProduction,
    ) =>
      GameEventNotificationMessage(
        title: l10n.eventCityBuiltBuildingTitle,
        body:
            '${_cityName(l10n, state, cityId, activityContext)}: ${wonderType.displayName} (+$refundedProduction production)',
        thumbnail: const IconEventNotificationThumbnail(
          EventNotificationIconThumbnailKind.warning,
        ),
      ),
    CityProducedUnitEvent(:final cityId, :final unitType) =>
      GameEventNotificationMessage(
        title: l10n.eventCityProducedUnitTitle,
        body:
            '${_cityName(l10n, state, cityId, activityContext)}: ${GameDisplayNames.unitType(l10n, unitType)}',
        thumbnail: UnitEventNotificationThumbnail(unitType),
      ),
    CityClaimedHexEvent(:final cityId) => GameEventNotificationMessage(
      title: l10n.eventCityClaimedHexTitle,
      body: l10n.eventCityClaimedHexBody(
        _cityName(l10n, state, cityId, activityContext),
      ),
      thumbnail: const CityEventNotificationThumbnail(),
    ),
    _ => _unsupportedEvent('city', event),
  };
}
