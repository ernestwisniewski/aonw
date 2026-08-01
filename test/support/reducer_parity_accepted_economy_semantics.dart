part of 'reducer_parity_accepted_semantics.dart';

void requireAcceptedResourceTrade({
  required String fixtureId,
  required DomainCommand command,
  required PersistentGameState before,
  required PersistentGameState after,
  required List<GameEvent> events,
}) {
  final beforeAgreements = before.runtimeState.resourceTradeAgreements;
  final afterAgreements = after.runtimeState.resourceTradeAgreements;
  final expected = switch (command) {
    final OpenResourceTradeCommand value => _expectedGoldTradeAgreements(
      value,
      beforeAgreements.length,
    ),
    final OpenResourceExchangeCommand value =>
      _expectedResourceExchangeAgreements(value, beforeAgreements.length),
    _ => throw StateError('Expected a resource trade command.'),
  };
  final expectedAgreements = [...beforeAgreements, ...expected]
    ..sort((left, right) => left.id.compareTo(right.id));
  final expectedState = before.copyWith(
    runtimeState: before.runtimeState.copyWith(
      resourceTradeAgreements: expectedAgreements,
    ),
  );
  if (events.isNotEmpty ||
      afterAgreements.length != beforeAgreements.length + expected.length ||
      after != expectedState) {
    throw FormatException(
      '$fixtureId must commit only the reviewed resource trade agreements.',
    );
  }
}

List<ResourceTradeAgreement> _expectedGoldTradeAgreements(
  OpenResourceTradeCommand command,
  int existingAgreementCount,
) {
  return [
    ResourceTradeAgreement(
      id: _expectedGoldTradeAgreementId(
        agreementId: command.agreementId,
        playerId: command.playerId,
        targetPlayerId: command.targetPlayerId,
        resource: command.resource,
        existingAgreementCount: existingAgreementCount,
      ),
      exporterPlayerId: command.targetPlayerId,
      importerPlayerId: command.playerId,
      resource: command.resource,
      goldPerTurn: command.goldPerTurn,
      remainingTurns: command.durationTurns,
    ),
  ];
}

List<ResourceTradeAgreement> _expectedResourceExchangeAgreements(
  OpenResourceExchangeCommand command,
  int existingAgreementCount,
) {
  final baseId = _expectedExchangeAgreementId(
    agreementId: command.agreementId,
    playerId: command.playerId,
    targetPlayerId: command.targetPlayerId,
    offeredResource: command.offeredResource,
    requestedResource: command.requestedResource,
    existingAgreementCount: existingAgreementCount,
  );
  return [
    ResourceTradeAgreement(
      id: '${baseId}_requested',
      exporterPlayerId: command.targetPlayerId,
      importerPlayerId: command.playerId,
      resource: command.requestedResource,
      goldPerTurn: 0,
      remainingTurns: command.durationTurns,
    ),
    ResourceTradeAgreement(
      id: '${baseId}_offered',
      exporterPlayerId: command.playerId,
      importerPlayerId: command.targetPlayerId,
      resource: command.offeredResource,
      goldPerTurn: 0,
      remainingTurns: command.durationTurns,
    ),
  ];
}

String _expectedGoldTradeAgreementId({
  required String? agreementId,
  required String playerId,
  required String targetPlayerId,
  required ResourceType resource,
  required int existingAgreementCount,
}) {
  return agreementId ??
      'resource_trade_${playerId}_${targetPlayerId}_${resource.name}_$existingAgreementCount';
}

String _expectedExchangeAgreementId({
  required String? agreementId,
  required String playerId,
  required String targetPlayerId,
  required ResourceType offeredResource,
  required ResourceType requestedResource,
  required int existingAgreementCount,
}) {
  return agreementId ??
      'resource_exchange_${playerId}_${targetPlayerId}_${offeredResource.name}_${requestedResource.name}_$existingAgreementCount';
}

void requireAcceptedRichTurnFinalization(
  String fixtureId,
  PersistentGameState before,
  PersistentGameState after,
  List<GameEvent> events,
) {
  if (fixtureId != 'turn-rich-map-finalization-accepted') return;
  final hold = after
      .runtimeState
      .mapObjectiveHoldStatesByObjectiveId['strategic_pass_1'];
  final objectiveEvents = events.whereType<MapObjectiveSecuredEvent>().toList();
  final objective = objectiveEvents.singleOrNull;
  if ((
        hold?.playerId,
        hold?.holdTurns,
        objective?.playerId,
        objective?.objectiveId,
        objective?.goldPerTurn,
        (after.playerGold['player_1'] ?? 0) -
            (before.playerGold['player_1'] ?? 0),
      ) !=
      ('player_1', 2, 'player_1', 'strategic_pass_1', 4, 4)) {
    throw FormatException(
      '$fixtureId must secure the reviewed objective and its gold reward.',
    );
  }

  final research = after.research.forPlayer('player_1');
  final discoveries = events
      .whereType<StrategicResourceDiscoveredEvent>()
      .toList();
  final discovery = discoveries.singleOrNull;
  if ((
        !research.hasUnlocked(TechnologyId.animalHusbandry),
        research.activeTechnologyId,
        discovery?.resourceType,
        discovery?.controlledCount,
      ) !=
      (false, null, ResourceType.horses, 1)) {
    throw FormatException(
      '$fixtureId must finish research and reveal the controlled horses.',
    );
  }

  final improvements = after.fieldImprovements
      .where((value) => value.builtByCityId == 'city_1')
      .toList();
  final improvement = improvements.singleOrNull;
  if ((
        before.units.byId('worker_1')?.workerJob?.remainingTurns,
        after.units.byId('worker_1'),
        improvement?.hex,
        improvement?.type,
      ) !=
      (1, null, const CityHex(col: 0, row: 1), FieldImprovementType.farm)) {
    throw FormatException(
      '$fixtureId must complete the reviewed worker improvement.',
    );
  }

  final foodBefore = before.cities.byId('city_1')?.storedFood;
  final foodAfter = after.cities.byId('city_1')?.storedFood;
  if (foodBefore == null || foodAfter == null || foodAfter <= foodBefore) {
    throw FormatException('$fixtureId must advance the reviewed city economy.');
  }
}

void requireAcceptedTurnSubmission({
  required String fixtureId,
  required SubmitTurnCommand command,
  required int inputTurn,
  required Iterable<String> playerIds,
  required Object? expectedTurn,
  required Map<String, dynamic> expectedPlayerStates,
  required PersistentGameState before,
  required PersistentGameState after,
  required DateTime now,
  required List<GameEvent> events,
}) {
  if (expectedTurn == inputTurn) {
    if (!after.runtimeState.hasSubmitted(command.playerId) ||
        expectedPlayerStates[command.playerId] != 'finished' ||
        events.isNotEmpty) {
      throw FormatException(
        '$fixtureId must commit the reviewed waiting submission.',
      );
    }
    return;
  }

  final expectedPlayerIds = playerIds.toList()..sort();
  final allSubmitted = events.whereType<AllPlayersSubmittedEvent>().toList();
  final turnEndedIds = events
      .whereType<TurnEndedEvent>()
      .map((event) => event.playerId)
      .toList();
  if (expectedTurn != inputTurn + 1 ||
      after.runtimeState.submittedPlayerIds.isNotEmpty ||
      after.runtimeState.turnStartedAt != now ||
      expectedPlayerStates.values.any((value) => value != 'active') ||
      allSubmitted.length != 1 ||
      !_sameOrderedValues(allSubmitted.single.playerIds, expectedPlayerIds) ||
      !_sameOrderedValues(turnEndedIds, expectedPlayerIds)) {
    throw FormatException(
      '$fixtureId must commit the reviewed simultaneous turn.',
    );
  }
  requireAcceptedRichTurnFinalization(fixtureId, before, after, events);
}

bool _sameOrderedValues<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
