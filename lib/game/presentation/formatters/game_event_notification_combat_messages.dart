part of 'game_event_notification_message.dart';

GameEventNotificationMessage _combatEventMessage({
  required AppLocalizations l10n,
  required _GameEventPlayerRoster? roster,
  required GameState state,
  required GameState? previousState,
  required GameActivityContext activityContext,
  required GameEvent event,
}) {
  return switch (event) {
    UnitAttackedEvent(:final attackerUnitId, :final defenderUnitId) =>
      GameEventNotificationMessage(
        title: l10n.eventUnitAttackedTitle,
        body:
            '${_unitName(l10n, state, attackerUnitId, previousState, activityContext)} -> '
            '${_unitName(l10n, state, defenderUnitId, previousState, activityContext)}',
        thumbnail:
            _unitThumbnail(
              state,
              attackerUnitId,
              previousState,
              activityContext,
            ) ??
            _unitThumbnail(
              state,
              defenderUnitId,
              previousState,
              activityContext,
            ) ??
            const CombatEventNotificationThumbnail(),
      ),
    CityAttackedEvent(:final attackerUnitId, :final cityId) =>
      GameEventNotificationMessage(
        title: l10n.eventUnitAttackedTitle,
        body:
            '${_unitName(l10n, state, attackerUnitId, previousState, activityContext)} -> '
            '${_cityName(l10n, state, cityId, activityContext)}',
        thumbnail:
            _unitThumbnail(
              state,
              attackerUnitId,
              previousState,
              activityContext,
            ) ??
            const CombatEventNotificationThumbnail(),
      ),
    CombatResolvedEvent(
      :final attackerUnitId,
      :final defenderUnitId,
      :final outcome,
    ) =>
      _combatMessage(
        l10n: l10n,
        state: state,
        roster: roster,
        previousState: previousState,
        attackerUnitId: attackerUnitId,
        defenderUnitId: defenderUnitId,
        outcome: outcome,
        activityContext: activityContext,
      ),
    UnitKilledEvent(:final unitId) => GameEventNotificationMessage(
      title: l10n.eventUnitKilledTitle,
      body: _unitName(l10n, state, unitId, previousState, activityContext),
      thumbnail:
          _unitThumbnail(state, unitId, previousState, activityContext) ??
          const CombatEventNotificationThumbnail(),
    ),
    UnitRetreatedEvent(:final unitId) => GameEventNotificationMessage(
      title: l10n.eventUnitRetreatedTitle,
      body: _unitName(l10n, state, unitId, previousState, activityContext),
      thumbnail:
          _unitThumbnail(state, unitId, previousState, activityContext) ??
          const CombatEventNotificationThumbnail(),
    ),
    CityCapturedEvent(:final cityId, :final newOwnerPlayerId) =>
      GameEventNotificationMessage(
        title: l10n.eventCityCapturedTitle,
        body:
            '${_cityName(l10n, state, cityId, activityContext)} (${_playerName(l10n, roster, newOwnerPlayerId)})',
        thumbnail: const CityEventNotificationThumbnail(),
      ),
    CityDestroyedEvent(:final cityId, :final attackerOwnerPlayerId) =>
      GameEventNotificationMessage(
        title: l10n.eventCityDestroyedTitle,
        body:
            '${_cityName(l10n, previousState ?? state, cityId, activityContext)} (${_playerName(l10n, roster, attackerOwnerPlayerId)})',
        thumbnail: const CityEventNotificationThumbnail(),
      ),
    _ => _unsupportedEvent('combat', event),
  };
}
