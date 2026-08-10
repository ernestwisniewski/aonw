part of 'game_event_notification_message.dart';

Never _unsupportedEvent(String group, GameEvent event) {
  throw StateError(
    'Unsupported $group notification event: ${event.runtimeType}',
  );
}

String _strategicResourcePressureDetail(
  AppLocalizations l10n,
  StrategicResourceDiscoveryPressure pressure,
) {
  return switch (pressure) {
    StrategicResourceDiscoveryPressure.securedSupply =>
      l10n.eventStrategicResourcePressureSecured,
    StrategicResourceDiscoveryPressure.expansionRace =>
      l10n.eventStrategicResourcePressureExpansionRace,
    StrategicResourceDiscoveryPressure.contestedSupply =>
      l10n.eventStrategicResourcePressureContested,
    StrategicResourceDiscoveryPressure.rivalMonopoly =>
      l10n.eventStrategicResourcePressureRivalMonopoly,
  };
}
