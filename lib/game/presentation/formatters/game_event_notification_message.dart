import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/combat_modifier_labels.dart';
import 'package:aonw/game/presentation/formatters/diplomacy_history_presenter.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

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
    GameSave? save,
  ) {
    return _GameEventNotificationMessageFormatter(
      l10n: l10n,
      notification: notification,
      save: save,
    ).message();
  }
}

class _GameEventNotificationMessageFormatter {
  final AppLocalizations l10n;
  final GameEventNotification notification;
  final GameSave? save;

  const _GameEventNotificationMessageFormatter({
    required this.l10n,
    required this.notification,
    required this.save,
  });

  GameState get state => notification.state;

  GameState? get previousState => notification.previousState;

  GameActivityContext get activityContext => notification.context;

  GameEventNotificationMessage message() {
    final event = notification.event;
    return switch (event) {
      CityFoundedEvent() ||
      CityBuiltBuildingEvent() ||
      CityProducedUnitEvent() ||
      CityClaimedHexEvent() => _cityEventMessage(event),
      UnitMovedEvent() ||
      UnitGainedExperienceEvent() ||
      WorkerCompletedJobEvent() => _unitEventMessage(event),
      UnitAttackedEvent() ||
      CombatResolvedEvent() ||
      UnitKilledEvent() ||
      UnitRetreatedEvent() ||
      CityCapturedEvent() ||
      CityDestroyedEvent() => _combatEventMessage(event),
      TurnEndedEvent() ||
      DominationThresholdReachedEvent() => _turnEventMessage(event),
      ResearchPointsGainedEvent() ||
      TechnologyResearchedEvent() ||
      StrategicResourceDiscoveredEvent() => _researchEventMessage(event),
      MapObjectiveSecuredEvent() => _objectiveEventMessage(event),
      CivilizationMetEvent() ||
      DiplomaticProposalSentEvent() ||
      DiplomaticProposalRespondedEvent() ||
      DiplomaticProposalExpiredEvent() ||
      DiplomaticRelationChangedEvent() ||
      DiplomaticMessageSentEvent() ||
      DiplomaticMessageRespondedEvent() ||
      DiplomaticScoreChangedEvent() ||
      DiplomaticPromiseBrokenEvent() => _diplomacyEventMessage(event),
      CommandRejectedEvent() ||
      AllPlayersSubmittedEvent() ||
      PlayerTimedOutEvent() ||
      TurnAutoResolvedEvent() ||
      PlayerKickedEvent() => _systemEventMessage(event),
    };
  }

  GameEventNotificationMessage _cityEventMessage(GameEvent event) {
    return switch (event) {
      CityFoundedEvent(:final cityId, :final ownerPlayerId) =>
        GameEventNotificationMessage(
          title: l10n.eventCityFoundedTitle,
          body:
              '${_cityName(l10n, state, cityId, activityContext)} (${_playerName(l10n, save, ownerPlayerId)})',
          thumbnail: const CityEventNotificationThumbnail(),
        ),
      CityBuiltBuildingEvent(:final cityId, :final buildingType) =>
        GameEventNotificationMessage(
          title: l10n.eventCityBuiltBuildingTitle,
          body:
              '${_cityName(l10n, state, cityId, activityContext)}: ${GameDisplayNames.cityBuilding(l10n, buildingType)}',
          thumbnail: BuildingEventNotificationThumbnail(buildingType),
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

  GameEventNotificationMessage _combatEventMessage(GameEvent event) {
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
      CombatResolvedEvent(
        :final attackerUnitId,
        :final defenderUnitId,
        :final outcome,
      ) =>
        _combatMessage(
          l10n: l10n,
          state: state,
          save: save,
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
              '${_cityName(l10n, state, cityId, activityContext)} (${_playerName(l10n, save, newOwnerPlayerId)})',
          thumbnail: const CityEventNotificationThumbnail(),
        ),
      CityDestroyedEvent(:final cityId, :final attackerOwnerPlayerId) =>
        GameEventNotificationMessage(
          title: l10n.eventCityDestroyedTitle,
          body:
              '${_cityName(l10n, previousState ?? state, cityId, activityContext)} (${_playerName(l10n, save, attackerOwnerPlayerId)})',
          thumbnail: const CityEventNotificationThumbnail(),
        ),
      _ => _unsupportedEvent('combat', event),
    };
  }

  GameEventNotificationMessage _turnEventMessage(GameEvent event) {
    return switch (event) {
      TurnEndedEvent(:final playerId) => GameEventNotificationMessage(
        title: l10n.eventTurnEndedTitle,
        body: _playerName(l10n, save, playerId),
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
          save: save,
          state: state,
          playerId: playerId,
          controlPercent: controlPercent,
          requiredControlPercent: requiredControlPercent,
          holdTurns: holdTurns,
          requiredHoldTurns: requiredHoldTurns,
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
            _playerName(l10n, save, playerId),
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
              '${_playerName(l10n, save, playerId)}: ${GameDisplayNames.technology(l10n, technologyId)}',
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
            _playerName(l10n, save, playerId),
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
            _playerName(l10n, save, playerId),
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
    return switch (event) {
      CivilizationMetEvent(:final metPlayerId) => _civilizationMetMessage(
        l10n: l10n,
        save: save,
        state: state,
        metPlayerId: metPlayerId,
      ),
      DiplomaticProposalSentEvent() ||
      DiplomaticProposalRespondedEvent() ||
      DiplomaticProposalExpiredEvent() ||
      DiplomaticRelationChangedEvent() ||
      DiplomaticMessageSentEvent() ||
      DiplomaticMessageRespondedEvent() ||
      DiplomaticScoreChangedEvent() ||
      DiplomaticPromiseBrokenEvent() => _diplomacyHistoryMessage(
        l10n: l10n,
        notification: notification,
        save: save,
      ),
      _ => _unsupportedEvent('diplomacy', event),
    };
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
      PlayerTimedOutEvent(:final turn, :final playerId) =>
        GameEventNotificationMessage(
          title: l10n.eventPlayerTimedOutTitle,
          body: l10n.eventPlayerTimedOutBody(
            _playerName(l10n, save, playerId),
            turn,
          ),
          thumbnail: const IconEventNotificationThumbnail(
            EventNotificationIconThumbnailKind.warning,
          ),
        ),
      TurnAutoResolvedEvent(:final turn, :final playerId) =>
        GameEventNotificationMessage(
          title: l10n.eventPlayerTimedOutTitle,
          body: l10n.eventPlayerTimedOutBody(
            _playerName(l10n, save, playerId),
            turn,
          ),
          thumbnail: const IconEventNotificationThumbnail(
            EventNotificationIconThumbnailKind.warning,
          ),
        ),
      PlayerKickedEvent(:final turn, :final playerId) =>
        GameEventNotificationMessage(
          title: l10n.eventPlayerTimedOutTitle,
          body: l10n.eventPlayerTimedOutBody(
            _playerName(l10n, save, playerId),
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

GameEventNotificationMessage _diplomacyHistoryMessage({
  required AppLocalizations l10n,
  required GameEventNotification notification,
  required GameSave? save,
}) {
  final event = notification.event;
  final text = DiplomacyHistoryPresenter.event(
    l10n,
    event,
    turn: notification.turn,
    playerNameFor: (playerId) => _playerName(l10n, save, playerId),
  );
  final details = <String>[
    if (text.detail != null) text.detail!,
    if (text.detail == null && text.delta != null)
      DiplomacyHistoryPresenter.signedDelta(text.delta!),
  ];
  return GameEventNotificationMessage(
    title: text.title,
    body: text.subtitle,
    details: details,
    thumbnail: _diplomacyThumbnail(event),
  );
}

GameEventNotificationThumbnail _diplomacyThumbnail(GameEvent event) {
  return switch (event) {
    DiplomaticProposalRespondedEvent(:final accepted) =>
      IconEventNotificationThumbnail(
        accepted
            ? EventNotificationIconThumbnailKind.success
            : EventNotificationIconThumbnailKind.warning,
      ),
    DiplomaticProposalExpiredEvent() ||
    DiplomaticPromiseBrokenEvent() => const IconEventNotificationThumbnail(
      EventNotificationIconThumbnailKind.warning,
    ),
    DiplomaticRelationChangedEvent(:final newStatus) =>
      IconEventNotificationThumbnail(
        newStatus == DiplomaticRelationStatus.war
            ? EventNotificationIconThumbnailKind.warning
            : EventNotificationIconThumbnailKind.civilization,
      ),
    DiplomaticMessageRespondedEvent(:final relationDelta) =>
      IconEventNotificationThumbnail(
        relationDelta >= 0
            ? EventNotificationIconThumbnailKind.success
            : EventNotificationIconThumbnailKind.warning,
      ),
    DiplomaticScoreChangedEvent(:final delta) => IconEventNotificationThumbnail(
      delta >= 0
          ? EventNotificationIconThumbnailKind.success
          : EventNotificationIconThumbnailKind.warning,
    ),
    DiplomaticProposalSentEvent() ||
    DiplomaticMessageSentEvent() => const IconEventNotificationThumbnail(
      EventNotificationIconThumbnailKind.civilization,
    ),
    _ => const IconEventNotificationThumbnail(
      EventNotificationIconThumbnailKind.civilization,
    ),
  };
}

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

GameEventNotificationMessage _civilizationMetMessage({
  required AppLocalizations l10n,
  required GameSave? save,
  required GameState state,
  required String metPlayerId,
}) {
  final country = _playerCountry(save, state, metPlayerId);
  final civilizationName = GameDisplayNames.playerCountry(l10n, country);
  final leaderName = GameDisplayNames.playerCountryLeader(l10n, country);
  return GameEventNotificationMessage(
    title: l10n.eventCivilizationMetTitle,
    body: l10n.eventCivilizationMetBody(
      civilizationName,
      _playerName(l10n, save, metPlayerId),
    ),
    details: [leaderName],
    thumbnail: const IconEventNotificationThumbnail(
      EventNotificationIconThumbnailKind.civilization,
    ),
  );
}

GameEventNotificationMessage _combatMessage({
  required AppLocalizations l10n,
  required GameSave? save,
  required GameState state,
  required GameState? previousState,
  required String attackerUnitId,
  required String defenderUnitId,
  required CombatOutcome outcome,
  required GameActivityContext activityContext,
}) {
  final defenderUnitSnapshot = activityContext.units[defenderUnitId];
  final defenderUnit =
      _unitById(previousState, defenderUnitId) ??
      _unitById(state, defenderUnitId);
  final defenderCitySnapshot = activityContext.cities[defenderUnitId];
  final defenderCity =
      _cityByIdOrNull(previousState, defenderUnitId) ??
      _cityByIdOrNull(state, defenderUnitId);
  final attackerName = _combatUnitName(
    l10n,
    state,
    attackerUnitId,
    previousState,
    activityContext,
  );
  final defenderName = defenderUnitSnapshot != null || defenderUnit != null
      ? _combatUnitName(
          l10n,
          state,
          defenderUnitId,
          previousState,
          activityContext,
        )
      : defenderCitySnapshot != null
      ? _citySnapshotName(l10n, defenderCitySnapshot)
      : defenderCity != null
      ? GameDisplayNames.city(l10n, defenderCity)
      : defenderUnitId;
  final attackerOwnerPlayerId = _unitOwnerPlayerId(
    state,
    attackerUnitId,
    previousState,
    activityContext,
  );
  final defenderOwnerPlayerId =
      _unitOwnerPlayerId(
        state,
        defenderUnitId,
        previousState,
        activityContext,
      ) ??
      _cityOwnerPlayerId(state, defenderUnitId, previousState, activityContext);

  return GameEventNotificationMessage(
    title: l10n.eventCombatTitle,
    body: l10n.eventCombatSimpleBody(
      _playerCountryName(l10n, save, state, attackerOwnerPlayerId),
      attackerName,
      _playerCountryName(l10n, save, state, defenderOwnerPlayerId),
      defenderName,
      outcome.attackerHpAfter,
      outcome.defenderHpAfter,
    ),
    details: _combatDetails(
      l10n: l10n,
      attackerName: attackerName,
      defenderName: defenderName,
      outcome: outcome,
    ),
    thumbnail:
        _unitThumbnail(state, attackerUnitId, previousState, activityContext) ??
        _unitThumbnail(state, defenderUnitId, previousState, activityContext) ??
        const CombatEventNotificationThumbnail(),
  );
}

List<String> _combatDetails({
  required AppLocalizations l10n,
  required String attackerName,
  required String defenderName,
  required CombatOutcome outcome,
}) {
  final details = <String>[
    l10n.eventCombatDamageLine(
      defenderName,
      _damageFromAttack(outcome),
      _defenderCombatResult(l10n, outcome),
    ),
  ];
  final retaliationDamage = _damageFromRetaliation(outcome);
  if (retaliationDamage <= 0) {
    details.add(l10n.eventCombatNoRetaliationLine(attackerName));
  } else {
    details.add(
      l10n.eventCombatDamageLine(
        attackerName,
        retaliationDamage,
        _attackerCombatResult(l10n, outcome),
      ),
    );
  }
  final attackDamage = _damageFromAttack(outcome);
  if (attackDamage > 0) {
    details.add(l10n.eventCombatAttackDamageDetail(attackDamage));
  }
  if (retaliationDamage > 0) {
    details.add(l10n.eventCombatRetaliationDamageDetail(retaliationDamage));
  }
  details.addAll([
    if (outcome.defenderKilled) l10n.eventCombatDefenderKilledDetail,
    if (outcome.attackerKilled) l10n.eventCombatAttackerKilledDetail,
    if (outcome.defenderRetreated) l10n.eventCombatDefenderRetreatedDetail,
  ]);
  final seenModifiers = <String>{};

  void addModifier(CombatModifier modifier) {
    final key =
        '${modifier.runtimeType}:${modifier.label}:'
        '${modifier.target.name}:${modifier.delta}';
    if (seenModifiers.add(key)) {
      details.add(_modifierDetail(l10n, modifier));
    }
  }

  for (final step in outcome.steps) {
    switch (step) {
      case AttackStep(:final active):
        for (final modifier in active) {
          addModifier(modifier);
        }
      case RetaliationStep(:final active):
        for (final modifier in active) {
          addModifier(modifier);
        }
      case RollStep(:final value):
        details.add(l10n.eventCombatRollDetail(value));
      case ModifierAppliedStep(:final modifier):
        addModifier(modifier);
    }
  }
  return details;
}

String _defenderCombatResult(AppLocalizations l10n, CombatOutcome outcome) {
  if (outcome.defenderKilled) return l10n.eventCombatDefeatedResult;
  if (outcome.defenderRetreated) {
    return l10n.eventCombatDefenderRetreatedResult(outcome.defenderHpAfter);
  }
  return l10n.eventCombatHpResult(outcome.defenderHpAfter);
}

String _attackerCombatResult(AppLocalizations l10n, CombatOutcome outcome) {
  if (outcome.attackerKilled) return l10n.eventCombatDefeatedResult;
  return l10n.eventCombatHpResult(outcome.attackerHpAfter);
}

GameEventNotificationMessage _dominationThresholdMessage({
  required AppLocalizations l10n,
  required GameSave? save,
  required GameState state,
  required String playerId,
  required double controlPercent,
  required double requiredControlPercent,
  required int holdTurns,
  required int requiredHoldTurns,
}) {
  final playerName = _playerName(l10n, save, playerId);
  final isSelf =
      state.activePlayerId.isNotEmpty && state.activePlayerId == playerId;
  final control = _percentLabel(controlPercent);
  final required = _percentLabel(requiredControlPercent);
  final remaining = (requiredHoldTurns - holdTurns).clamp(0, requiredHoldTurns);
  return GameEventNotificationMessage(
    title: isSelf
        ? l10n.eventDominationStartedTitle
        : l10n.eventDominationRivalAboveTitle,
    body: l10n.eventDominationBody(playerName, control, required),
    details: [
      l10n.eventDominationHoldProgressDetail(holdTurns, requiredHoldTurns),
      if (remaining == 0)
        l10n.eventDominationReadyDetail
      else if (isSelf)
        l10n.eventDominationKeepHoldingDetail(_turnsLabel(l10n, remaining))
      else
        l10n.eventDominationInterruptDetail(_turnsLabel(l10n, remaining)),
    ],
    thumbnail: IconEventNotificationThumbnail(
      isSelf
          ? EventNotificationIconThumbnailKind.success
          : EventNotificationIconThumbnailKind.warning,
    ),
  );
}

int _damageFromAttack(CombatOutcome outcome) {
  for (final step in outcome.steps) {
    if (step is AttackStep) return step.damage;
  }
  return 0;
}

int _damageFromRetaliation(CombatOutcome outcome) {
  for (final step in outcome.steps) {
    if (step is RetaliationStep) return step.damage;
  }
  return 0;
}

String _modifierDetail(AppLocalizations l10n, CombatModifier modifier) {
  final sign = modifier.delta > 0 ? '+' : '';
  return '${CombatModifierLabels.rawLabel(l10n, modifier.label)} '
      '${_statTargetLabel(l10n, modifier.target)} $sign${modifier.delta}';
}

String _statTargetLabel(AppLocalizations l10n, CombatStatTarget target) {
  return switch (target) {
    CombatStatTarget.attack => l10n.eventCombatStatAttack,
    CombatStatTarget.defense => l10n.eventCombatStatDefense,
    CombatStatTarget.hp => l10n.eventCombatStatHp,
    CombatStatTarget.range => l10n.eventCombatStatRange,
    CombatStatTarget.mobility => l10n.eventCombatStatMobility,
  };
}

String _cityName(
  AppLocalizations l10n,
  GameState state,
  String cityId, [
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  final citySnapshot = activityContext.cities[cityId];
  if (citySnapshot != null) return _citySnapshotName(l10n, citySnapshot);
  final city = _cityById(state, cityId);
  return city == null ? cityId : GameDisplayNames.city(l10n, city);
}

GameCity? _cityById(GameState state, String cityId) {
  for (final city in state.cities) {
    if (city.id == cityId) return city;
  }
  return null;
}

GameCity? _cityByIdOrNull(GameState? state, String cityId) {
  if (state == null) return null;
  return _cityById(state, cityId);
}

String _unitName(
  AppLocalizations l10n,
  GameState state,
  String unitId, [
  GameState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  return _unitNameOrNull(l10n, state, unitId, previousState, activityContext) ??
      unitId;
}

String? _unitNameOrNull(
  AppLocalizations l10n,
  GameState state,
  String unitId, [
  GameState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  final unitSnapshot = activityContext.units[unitId];
  if (unitSnapshot != null) return _unitSnapshotName(l10n, unitSnapshot);
  final unit = _unitById(state, unitId) ?? _unitById(previousState, unitId);
  return unit == null ? null : GameDisplayNames.unit(l10n, unit);
}

String _combatUnitName(
  AppLocalizations l10n,
  GameState state,
  String unitId, [
  GameState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  return _combatUnitNameOrNull(
        l10n,
        state,
        unitId,
        previousState,
        activityContext,
      ) ??
      unitId;
}

String? _combatUnitNameOrNull(
  AppLocalizations l10n,
  GameState state,
  String unitId, [
  GameState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  final unitSnapshot = activityContext.units[unitId];
  if (unitSnapshot != null) return _unitSnapshotName(l10n, unitSnapshot);
  final unit = _unitById(state, unitId) ?? _unitById(previousState, unitId);
  return unit == null ? null : GameDisplayNames.unitWithType(l10n, unit);
}

String? _unitOwnerPlayerId(
  GameState state,
  String unitId, [
  GameState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  final unitSnapshot = activityContext.units[unitId];
  if (unitSnapshot != null) return unitSnapshot.ownerPlayerId;
  final unit = _unitById(state, unitId) ?? _unitById(previousState, unitId);
  return unit?.ownerPlayerId;
}

String? _cityOwnerPlayerId(
  GameState state,
  String cityId, [
  GameState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  final citySnapshot = activityContext.cities[cityId];
  if (citySnapshot != null) return citySnapshot.ownerPlayerId;
  final city =
      _cityByIdOrNull(state, cityId) ?? _cityByIdOrNull(previousState, cityId);
  return city?.ownerPlayerId;
}

String _percentLabel(double value) => value.round().toString();

String _turnsLabel(AppLocalizations l10n, int count) =>
    l10n.eventTurnCountLabel(count);

GameUnit? _unitById(GameState? state, String unitId) {
  if (state == null) return null;
  for (final unit in state.units) {
    if (unit.id == unitId) return unit;
  }
  return null;
}

UnitEventNotificationThumbnail? _unitThumbnail(
  GameState state,
  String unitId, [
  GameState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  final unitSnapshot = activityContext.units[unitId];
  if (unitSnapshot != null) {
    return UnitEventNotificationThumbnail(unitSnapshot.type);
  }
  final unit = _unitById(state, unitId) ?? _unitById(previousState, unitId);
  return unit == null ? null : UnitEventNotificationThumbnail(unit.type);
}

String _unitSnapshotName(AppLocalizations l10n, GameActivityUnitSnapshot unit) {
  return GameDisplayNames.unitWithType(
    l10n,
    GameUnit(
      id: unit.id,
      ownerPlayerId: unit.ownerPlayerId,
      type: unit.type,
      name: unit.name,
      col: 0,
      row: 0,
    ),
  );
}

String _citySnapshotName(AppLocalizations l10n, GameActivityCitySnapshot city) {
  return GameDisplayNames.city(
    l10n,
    GameCity(
      id: city.id,
      ownerPlayerId: city.ownerPlayerId,
      name: city.name,
      center: const CityHex(col: 0, row: 0),
    ),
  );
}

String _playerName(AppLocalizations l10n, GameSave? save, String playerId) {
  final player = _playerById(save, playerId);
  return player == null ? playerId : GameDisplayNames.player(l10n, player);
}

String _playerCountryName(
  AppLocalizations l10n,
  GameSave? save,
  GameState state,
  String? playerId,
) {
  if (playerId == null || playerId.isEmpty) return '';
  final player = _playerById(save, playerId);
  if (player != null) {
    return GameDisplayNames.playerCountry(l10n, player.country);
  }
  final stateCountry = state.playerCountries[playerId];
  if (stateCountry != null) {
    return GameDisplayNames.playerCountry(l10n, stateCountry);
  }
  return _playerName(l10n, save, playerId);
}

PlayerCountry _playerCountry(GameSave? save, GameState state, String playerId) {
  return _playerById(save, playerId)?.country ??
      state.countryForPlayer(playerId);
}

Player? _playerById(GameSave? save, String playerId) {
  if (save == null) return null;
  for (final player in save.players) {
    if (player.id == playerId) return player;
  }
  return null;
}
