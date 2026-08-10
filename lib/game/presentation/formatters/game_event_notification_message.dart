import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/combat_modifier_labels.dart';
import 'package:aonw/game/presentation/formatters/diplomacy_history_presenter.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/game_value_formatters.dart';
import 'package:aonw/game/presentation/formatters/stability_event_messages.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'game_event_notification_city_messages.dart';
part 'game_event_notification_combat_messages.dart';
part 'game_event_notification_diplomacy_messages.dart';
part 'game_event_notification_entity_resolution.dart';
part 'game_event_notification_helpers.dart';
part 'game_event_notification_models.dart';
part 'game_event_notification_player_names.dart';
part 'game_event_notification_turn_messages.dart';

class GameEventNotificationMessage {
  final String title;
  final String body;
  final List<String> details;
  final GameEventNotificationThumbnail? thumbnail;

  GameEventNotificationMessage({
    required this.title,
    required this.body,
    List<String> details = const [],
    this.thumbnail,
  }) : details = List.unmodifiable(details);

  static GameEventNotificationMessage from(
    AppLocalizations l10n,
    GameEventNotification notification,
    GameSave? legacySave,
  ) {
    return fromPlayers(l10n, notification, legacySave?.players ?? const []);
  }

  static GameEventNotificationMessage fromPlayers(
    AppLocalizations l10n,
    GameEventNotification notification,
    Iterable<Player> players,
  ) {
    return _GameEventNotificationMessageFormatter(
      l10n: l10n,
      notification: notification,
      roster: _GameEventPlayerRoster(players),
    ).message();
  }
}

class _GameEventNotificationMessageFormatter {
  final AppLocalizations l10n;
  final GameEventNotification notification;
  final _GameEventPlayerRoster roster;

  const _GameEventNotificationMessageFormatter({
    required this.l10n,
    required this.notification,
    required this.roster,
  });

  GameClientState get state => notification.state;

  GameClientState? get previousState => notification.previousState;

  GameActivityContext get activityContext => notification.context;

  GameEventNotificationMessage message() {
    final event = notification.event;
    return switch (GameEventDescriptor.forEvent(event).messageGroup) {
      GameEventMessageGroup.city => _cityEventMessage(event),
      GameEventMessageGroup.unit => _unitEventMessage(event),
      GameEventMessageGroup.combat => _combatEventMessage(
        l10n: l10n,
        roster: roster,
        state: state,
        previousState: previousState,
        activityContext: activityContext,
        event: event,
      ),
      GameEventMessageGroup.turn => _turnEventMessage(event),
      GameEventMessageGroup.research => _researchEventMessage(event),
      GameEventMessageGroup.objective => _objectiveEventMessage(event),
      GameEventMessageGroup.diplomacy => _diplomacyEventMessage(event),
      GameEventMessageGroup.system => _systemEventMessage(event),
    };
  }

  GameEventNotificationMessage _cityEventMessage(GameEvent event) =>
      _cityNotificationMessage(
        l10n: l10n,
        roster: roster,
        state: state,
        activityContext: activityContext,
        event: event,
      );

  GameEventNotificationMessage _unitEventMessage(GameEvent event) {
    return switch (event) {
      UnitMovedEvent(:final unitId) => GameEventNotificationMessage(
        title: l10n.eventUnitMovedTitle,
        body: _unitName(l10n, state, unitId, previousState, activityContext),
        thumbnail: _unitThumbnail(
          state,
          unitId,
          previousState,
          activityContext,
        ),
      ),
      UnitGainedExperienceEvent(
        :final unitId,
        :final amount,
        :final rank,
        :final promoted,
      ) =>
        GameEventNotificationMessage(
          title: promoted
              ? l10n.eventUnitPromotedTitle
              : l10n.eventUnitExperienceTitle,
          body: l10n.eventUnitExperienceBody(
            _unitName(l10n, state, unitId, previousState, activityContext),
            amount,
            GameDisplayNames.unitVeterancyRank(l10n, rank),
          ),
          thumbnail: _unitThumbnail(
            state,
            unitId,
            previousState,
            activityContext,
          ),
        ),
      WorkerCompletedJobEvent(:final unitId) => GameEventNotificationMessage(
        title: l10n.eventWorkerCompletedJobTitle,
        body: _unitName(l10n, state, unitId, previousState, activityContext),
        thumbnail:
            _unitThumbnail(state, unitId, previousState, activityContext) ??
            const UnitEventNotificationThumbnail(GameUnitType.worker),
      ),
      _ => _unsupportedEvent('unit', event),
    };
  }

  GameEventNotificationMessage _turnEventMessage(GameEvent event) {
    return switch (event) {
      TurnEndedEvent(:final playerId) => GameEventNotificationMessage(
        title: l10n.eventTurnEndedTitle,
        body: _playerName(l10n, roster, playerId),
        thumbnail: const IconEventNotificationThumbnail(
          EventNotificationIconThumbnailKind.turn,
        ),
      ),
      DominationThresholdReachedEvent(
        :final playerId,
        :final controlPercent,
        :final requiredControlPercent,
        :final holdTurns,
        :final requiredHoldTurns,
      ) =>
        _dominationThresholdMessage(
          l10n: l10n,
          roster: roster,
          state: state,
          playerId: playerId,
          controlPercent: controlPercent,
          requiredControlPercent: requiredControlPercent,
          holdTurns: holdTurns,
          requiredHoldTurns: requiredHoldTurns,
        ),
      StabilityBandChangedEvent(:final playerId, :final newBand, :final net) =>
        stabilityBandChangedMessage(
          l10n: l10n,
          playerName: _playerName(l10n, roster, playerId),
          newBand: newBand,
          net: net,
        ),
      _ => _unsupportedEvent('turn', event),
    };
  }

  GameEventNotificationMessage _researchEventMessage(GameEvent event) {
    return switch (event) {
      ResearchPointsGainedEvent(:final playerId, :final points) =>
        GameEventNotificationMessage(
          title: l10n.eventResearchPointsTitle,
          body: l10n.eventResearchPointsBody(
            _playerName(l10n, roster, playerId),
            points,
          ),
          thumbnail: const IconEventNotificationThumbnail(
            EventNotificationIconThumbnailKind.science,
          ),
        ),
      TechnologyResearchedEvent(:final playerId, :final technologyId) =>
        GameEventNotificationMessage(
          title: l10n.eventTechnologyResearchedTitle,
          body:
              '${_playerName(l10n, roster, playerId)}: ${GameDisplayNames.technology(l10n, technologyId)}',
          thumbnail: TechnologyEventNotificationThumbnail(technologyId),
        ),
      StrategicResourceDiscoveredEvent(
        :final playerId,
        :final resourceType,
        :final controlledCount,
        :final rivalControlledCount,
        :final unclaimedCount,
        :final pressure,
        :final nearestUnclaimedCol,
        :final nearestUnclaimedRow,
      ) =>
        GameEventNotificationMessage(
          title: l10n.eventStrategicResourceDiscoveredTitle,
          body: l10n.eventStrategicResourceDiscoveredBody(
            _playerName(l10n, roster, playerId),
            GameDisplayNames.resource(l10n, resourceType),
          ),
          details: [
            l10n.eventStrategicResourceControlledDetail(controlledCount),
            l10n.eventStrategicResourceRivalDetail(rivalControlledCount),
            l10n.eventStrategicResourceUnclaimedDetail(unclaimedCount),
            _strategicResourcePressureDetail(l10n, pressure),
            if (nearestUnclaimedCol != null && nearestUnclaimedRow != null)
              l10n.eventStrategicResourceSettleHint(
                nearestUnclaimedCol,
                nearestUnclaimedRow,
              ),
          ],
          thumbnail: const IconEventNotificationThumbnail(
            EventNotificationIconThumbnailKind.science,
          ),
        ),
      _ => _unsupportedEvent('research', event),
    };
  }

  GameEventNotificationMessage _objectiveEventMessage(GameEvent event) {
    return switch (event) {
      MapObjectiveSecuredEvent(
        :final playerId,
        :final objectiveType,
        :final col,
        :final row,
        :final holdTurns,
        :final requiredHoldTurns,
        :final victoryPoints,
        :final goldPerTurn,
      ) =>
        GameEventNotificationMessage(
          title: l10n.eventMapObjectiveSecuredTitle,
          body: l10n.eventMapObjectiveSecuredBody(
            _playerName(l10n, roster, playerId),
            GameDisplayNames.mapObjective(l10n, objectiveType),
          ),
          details: [
            l10n.eventMapObjectiveHoldDetail(holdTurns, requiredHoldTurns),
            l10n.eventMapObjectiveLocationDetail(col, row),
            if (victoryPoints > 0)
              l10n.eventMapObjectiveVictoryRewardDetail(victoryPoints),
            if (goldPerTurn > 0)
              l10n.eventMapObjectiveGoldRewardDetail(goldPerTurn),
          ],
          thumbnail: const IconEventNotificationThumbnail(
            EventNotificationIconThumbnailKind.success,
          ),
        ),
      _ => _unsupportedEvent('objective', event),
    };
  }

  GameEventNotificationMessage _diplomacyEventMessage(GameEvent event) {
    if (event case CivilizationMetEvent(:final metPlayerId)) {
      return _civilizationMetMessage(
        l10n: l10n,
        roster: roster,
        state: state,
        metPlayerId: metPlayerId,
      );
    }
    if (_isDiplomacyHistoryEvent(event)) {
      return _diplomacyHistoryMessage(
        l10n: l10n,
        notification: notification,
        roster: roster,
      );
    }
    return _unsupportedEvent('diplomacy', event);
  }

  GameEventNotificationMessage _systemEventMessage(GameEvent event) {
    return switch (event) {
      CommandRejectedEvent(:final reason) => GameEventNotificationMessage(
        title: l10n.eventCommandRejectedTitle,
        body: reason,
        thumbnail: const IconEventNotificationThumbnail(
          EventNotificationIconThumbnailKind.warning,
        ),
      ),
      AllPlayersSubmittedEvent(:final turn, :final playerIds) =>
        GameEventNotificationMessage(
          title: l10n.eventAllPlayersSubmittedTitle,
          body: l10n.eventAllPlayersSubmittedBody(turn, playerIds.length),
          thumbnail: const IconEventNotificationThumbnail(
            EventNotificationIconThumbnailKind.success,
          ),
        ),
      PlayerTimedOutEvent(:final turn, :final playerId) ||
      TurnAutoResolvedEvent(:final turn, :final playerId) ||
      PlayerKickedEvent(
        :final turn,
        :final playerId,
      ) => GameEventNotificationMessage(
        title: l10n.eventPlayerTimedOutTitle,
        body: l10n.eventPlayerTimedOutBody(
          _playerName(l10n, roster, playerId),
          turn,
        ),
        thumbnail: const IconEventNotificationThumbnail(
          EventNotificationIconThumbnailKind.warning,
        ),
      ),
      _ => _unsupportedEvent('system', event),
    };
  }
}
