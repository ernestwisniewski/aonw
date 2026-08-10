part of 'game_event_notification_message.dart';

GameEventNotificationMessage _combatEventMessage({
  required AppLocalizations l10n,
  required _GameEventPlayerRoster? roster,
  required GameClientState state,
  required GameClientState? previousState,
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
  final participants = _combatParticipants(
    l10n: l10n,
    state: state,
    previousState: previousState,
    attackerUnitId: attackerUnitId,
    defenderUnitId: defenderUnitId,
    activityContext: activityContext,
  );
  final countryState = previousState ?? state;
  return GameEventNotificationMessage(
    title: l10n.eventCombatTitle,
    body: l10n.eventCombatSimpleBody(
      _playerCountryName(
        l10n,
        roster,
        countryState,
        participants.attackerOwner,
      ),
      participants.attackerName,
      _playerCountryName(
        l10n,
        roster,
        countryState,
        participants.defenderOwner,
      ),
      participants.defenderName,
      outcome.attackerHpAfter,
      outcome.defenderHpAfter,
    ),
    details: _combatDetails(
      l10n: l10n,
      attackerName: participants.attackerName,
      defenderName: participants.defenderName,
      outcome: outcome,
    ),
    thumbnail:
        _resolvedUnitThumbnail(participants.attacker) ??
        _resolvedUnitThumbnail(participants.defender) ??
        const CombatEventNotificationThumbnail(),
  );
}

_CombatParticipants _combatParticipants({
  required AppLocalizations l10n,
  required GameClientState state,
  required GameClientState? previousState,
  required String attackerUnitId,
  required String defenderUnitId,
  required GameActivityContext activityContext,
}) {
  final attacker = _resolveUnit(
    state,
    attackerUnitId,
    previousState: previousState,
    activityContext: activityContext,
  );
  final defender = _resolveUnit(
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
  return (
    attacker: attacker,
    defender: defender,
    attackerName: _resolvedCombatUnitName(l10n, attacker) ?? attackerUnitId,
    defenderName:
        _resolvedCombatUnitName(l10n, defender) ??
        _resolvedCityName(l10n, defenderCity) ??
        defenderUnitId,
    attackerOwner: _resolvedUnitOwnerPlayerId(attacker),
    defenderOwner:
        _resolvedUnitOwnerPlayerId(defender) ??
        _resolvedCityOwnerPlayerId(defenderOwnerCity),
  );
}

List<String> _combatDetails({
  required AppLocalizations l10n,
  required String attackerName,
  required String defenderName,
  required CombatOutcome outcome,
}) {
  return [
    ..._combatDamageDetails(
      l10n: l10n,
      attackerName: attackerName,
      defenderName: defenderName,
      outcome: outcome,
    ),
    if (outcome.defenderKilled) l10n.eventCombatDefenderKilledDetail,
    if (outcome.attackerKilled) l10n.eventCombatAttackerKilledDetail,
    if (outcome.defenderRetreated) l10n.eventCombatDefenderRetreatedDetail,
    ..._combatStepDetails(l10n, outcome.steps),
  ];
}

List<String> _combatDamageDetails({
  required AppLocalizations l10n,
  required String attackerName,
  required String defenderName,
  required CombatOutcome outcome,
}) {
  final attackDamage = _damageFromAttack(outcome);
  final retaliationDamage = _damageFromRetaliation(outcome);
  return [
    l10n.eventCombatDamageLine(
      defenderName,
      attackDamage,
      _defenderCombatResult(l10n, outcome),
    ),
    if (retaliationDamage <= 0)
      l10n.eventCombatNoRetaliationLine(attackerName)
    else
      l10n.eventCombatDamageLine(
        attackerName,
        retaliationDamage,
        _attackerCombatResult(l10n, outcome),
      ),
    if (attackDamage > 0) l10n.eventCombatAttackDamageDetail(attackDamage),
    if (retaliationDamage > 0)
      l10n.eventCombatRetaliationDamageDetail(retaliationDamage),
  ];
}

List<String> _combatStepDetails(AppLocalizations l10n, List<CombatStep> steps) {
  final details = <String>[];
  final seenModifiers = <String>{};
  for (final step in steps) {
    switch (step) {
      case AttackStep(:final active) || RetaliationStep(:final active):
        _appendModifiers(l10n, active, seenModifiers, details);
      case RollStep(:final value):
        details.add(l10n.eventCombatRollDetail(value));
      case ModifierAppliedStep(:final modifier):
        _appendModifiers(l10n, [modifier], seenModifiers, details);
    }
  }
  return details;
}

void _appendModifiers(
  AppLocalizations l10n,
  Iterable<CombatModifier> modifiers,
  Set<String> seenModifiers,
  List<String> details,
) {
  for (final modifier in modifiers) {
    final key =
        '${modifier.runtimeType}:${modifier.label}:'
        '${modifier.target.name}:${modifier.delta}';
    if (seenModifiers.add(key)) {
      details.add(_modifierDetail(l10n, modifier));
    }
  }
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

typedef _CombatParticipants = ({
  Object? attacker,
  Object? defender,
  String attackerName,
  String defenderName,
  String? attackerOwner,
  String? defenderOwner,
});
