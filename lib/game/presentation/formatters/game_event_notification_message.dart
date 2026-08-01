import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/application/services/game_event_descriptor.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/combat_modifier_labels.dart';
import 'package:aonw/game/presentation/formatters/diplomacy_history_presenter.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/formatters/game_value_formatters.dart';
import 'package:aonw/game/presentation/formatters/stability_event_messages.dart';
import 'package:aonw/game/presentation/providers/game/game_event_notifications_provider.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'game_event_notification_combat_messages.dart';
part 'game_event_notification_city_messages.dart';
part 'game_event_notification_player_names.dart';

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
    return switch (event) {
      CivilizationMetEvent(:final metPlayerId) => _civilizationMetMessage(
        l10n: l10n,
        roster: roster,
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
        roster: roster,
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
  required _GameEventPlayerRoster? roster,
}) {
  final event = notification.event;
  final text = DiplomacyHistoryPresenter.event(
    l10n,
    event,
    turn: notification.turn,
    playerNameFor: (playerId) => _playerName(l10n, roster, playerId),
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
  required _GameEventPlayerRoster? roster,
  required GameClientState state,
  required String metPlayerId,
}) {
  final country = _playerCountry(roster, state, metPlayerId);
  final civilizationName = GameDisplayNames.playerCountry(l10n, country);
  final leaderName = GameDisplayNames.playerCountryLeader(l10n, country);
  return GameEventNotificationMessage(
    title: l10n.eventCivilizationMetTitle,
    body: l10n.eventCivilizationMetBody(
      civilizationName,
      _playerName(l10n, roster, metPlayerId),
    ),
    details: [leaderName],
    thumbnail: const IconEventNotificationThumbnail(
      EventNotificationIconThumbnailKind.civilization,
    ),
  );
}

GameEventNotificationMessage _combatMessage({
  required AppLocalizations l10n,
  required _GameEventPlayerRoster? roster,
  required GameClientState state,
  required GameClientState? previousState,
  required String attackerUnitId,
  required String defenderUnitId,
  required CombatOutcome outcome,
  required GameActivityContext activityContext,
}) {
  final attackerUnit = _resolveUnit(
    state,
    attackerUnitId,
    previousState: previousState,
    activityContext: activityContext,
  );
  final defenderUnit = _resolveUnit(
    state,
    defenderUnitId,
    previousState: previousState,
    activityContext: activityContext,
  );
  final defenderCity = _resolveCity(
    state,
    defenderUnitId,
    previousState: previousState,
    activityContext: activityContext,
    preferPreviousState: true,
  );
  final defenderOwnerCity = _resolveCity(
    state,
    defenderUnitId,
    previousState: previousState,
    activityContext: activityContext,
  );
  final attackerName =
      _resolvedCombatUnitName(l10n, attackerUnit) ?? attackerUnitId;
  final defenderName =
      _resolvedCombatUnitName(l10n, defenderUnit) ??
      _resolvedCityName(l10n, defenderCity) ??
      defenderUnitId;
  final attackerOwnerPlayerId = _resolvedUnitOwnerPlayerId(attackerUnit);
  final defenderOwnerPlayerId =
      _resolvedUnitOwnerPlayerId(defenderUnit) ??
      _resolvedCityOwnerPlayerId(defenderOwnerCity);

  return GameEventNotificationMessage(
    title: l10n.eventCombatTitle,
    body: l10n.eventCombatSimpleBody(
      _playerCountryName(l10n, roster, state, attackerOwnerPlayerId),
      attackerName,
      _playerCountryName(l10n, roster, state, defenderOwnerPlayerId),
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
        _resolvedUnitThumbnail(attackerUnit) ??
        _resolvedUnitThumbnail(defenderUnit) ??
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
  required _GameEventPlayerRoster? roster,
  required GameClientState state,
  required String playerId,
  required double controlPercent,
  required double requiredControlPercent,
  required int holdTurns,
  required int requiredHoldTurns,
}) {
  final playerName = _playerName(l10n, roster, playerId);
  final isSelf =
      state.activePlayerId.isNotEmpty && state.activePlayerId == playerId;
  final control = percent(controlPercent, false, false);
  final required = percent(requiredControlPercent, false, false);
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
  GameClientState state,
  String cityId, [
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  return _resolvedCityName(
        l10n,
        _resolveCity(state, cityId, activityContext: activityContext),
      ) ??
      cityId;
}

String _unitName(
  AppLocalizations l10n,
  GameClientState state,
  String unitId, [
  GameClientState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  return _unitNameOrNull(l10n, state, unitId, previousState, activityContext) ??
      unitId;
}

String? _unitNameOrNull(
  AppLocalizations l10n,
  GameClientState state,
  String unitId, [
  GameClientState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  return _resolvedUnitName(
    l10n,
    _resolveUnit(
      state,
      unitId,
      previousState: previousState,
      activityContext: activityContext,
    ),
  );
}

String _turnsLabel(AppLocalizations l10n, int count) =>
    l10n.eventTurnCountLabel(count);

UnitEventNotificationThumbnail? _unitThumbnail(
  GameClientState state,
  String unitId, [
  GameClientState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
]) {
  return _resolvedUnitThumbnail(
    _resolveUnit(
      state,
      unitId,
      previousState: previousState,
      activityContext: activityContext,
    ),
  );
}

String? _resolvedUnitName(AppLocalizations l10n, Object? unit) {
  return switch (unit) {
    final GameActivityUnitSnapshot snapshot => _unitSnapshotName(
      l10n,
      snapshot,
    ),
    final GameUnit unit => GameDisplayNames.unit(l10n, unit),
    _ => null,
  };
}

String? _resolvedCombatUnitName(AppLocalizations l10n, Object? unit) {
  return switch (unit) {
    final GameActivityUnitSnapshot snapshot => _unitSnapshotName(
      l10n,
      snapshot,
    ),
    final GameUnit unit => GameDisplayNames.unitWithType(l10n, unit),
    _ => null,
  };
}

String? _resolvedUnitOwnerPlayerId(Object? unit) {
  return switch (unit) {
    GameActivityUnitSnapshot(:final ownerPlayerId) ||
    GameUnit(:final ownerPlayerId) => ownerPlayerId,
    _ => null,
  };
}

UnitEventNotificationThumbnail? _resolvedUnitThumbnail(Object? unit) {
  return switch (unit) {
    GameActivityUnitSnapshot(:final type) ||
    GameUnit(:final type) => UnitEventNotificationThumbnail(type),
    _ => null,
  };
}

String? _resolvedCityName(AppLocalizations l10n, Object? city) {
  return switch (city) {
    final GameActivityCitySnapshot snapshot => _citySnapshotName(
      l10n,
      snapshot,
    ),
    final GameCity city => GameDisplayNames.city(l10n, city),
    _ => null,
  };
}

String? _resolvedCityOwnerPlayerId(Object? city) {
  return switch (city) {
    GameActivityCitySnapshot(:final ownerPlayerId) ||
    GameCity(:final ownerPlayerId) => ownerPlayerId,
    _ => null,
  };
}

Object? _resolveUnit(
  GameClientState state,
  String unitId, {
  GameClientState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
  bool preferPreviousState = false,
}) {
  final unitSnapshot = activityContext.units[unitId];
  if (unitSnapshot != null) return unitSnapshot;
  final unit = preferPreviousState
      ? previousState?.unitById(unitId) ?? state.unitById(unitId)
      : state.unitById(unitId) ?? previousState?.unitById(unitId);
  return unit;
}

Object? _resolveCity(
  GameClientState state,
  String cityId, {
  GameClientState? previousState,
  GameActivityContext activityContext = GameActivityContext.empty,
  bool preferPreviousState = false,
}) {
  final citySnapshot = activityContext.cities[cityId];
  if (citySnapshot != null) return citySnapshot;
  final city = preferPreviousState
      ? previousState?.cityById(cityId) ?? state.cityById(cityId)
      : state.cityById(cityId) ?? previousState?.cityById(cityId);
  return city;
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
    GameCity.snapshot(
      id: city.id,
      ownerPlayerId: city.ownerPlayerId,
      name: city.name,
      center: const CityHex(col: 0, row: 0),
    ),
  );
}
