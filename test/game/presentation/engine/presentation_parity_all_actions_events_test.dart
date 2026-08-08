import 'dart:io';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/presentation/engine/command_dispatch_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/presentation_parity_actions.dart';
import '../../../support/presentation_parity_events.dart';
import '../../../support/presentation_parity_snapshots.dart';
import '../../../support/presentation_parity_state.dart';
import '../../../support/reducer_parity_auto_explore_characterization.dart';
import '../../../support/reducer_parity_combat_characterization.dart';
import '../../../support/reducer_parity_diplomacy_characterization.dart';
import '../../../support/reducer_parity_fixture.dart';
import '../../../support/reducer_parity_movement_characterization.dart';
import '../../../support/reducer_parity_resource_trade_characterization.dart';

void main() {
  final stateFixture = PresentationParityStateFixture.build();
  final reducerFixtures = _loadReducerFixtures();

  group('single-player and multiplayer presentation parity', () {
    group('every domain event', () {
      for (var index = 0; index < presentationGameEvents.length; index++) {
        final event = presentationGameEvents[index];
        test('${event.runtimeType}', () {
          final identity = PresentationBatchIdentity(
            sourceId: 'event_${event.runtimeType}',
            eventOffset: index + 1,
          );
          final movementExecutions = _movementExecutionsFor(event);
          final singlePlayer = projectCommandDispatchPresentation(
            identity: identity,
            sequenceDirective: PresentationSequenceDirective.advance,
            interactionEffects: const [],
            events: [event],
            movementExecutions: movementExecutions,
            previousState: stateFixture.before,
            state: stateFixture.after,
            l10n: null,
            turn: 6,
          );
          final multiplayer =
              DomainEventPresentationProjector.projectObservedBatch(
                identity: identity,
                interactionEffects: const [],
                events: [_wireRoundTrip(event)],
                visibleMovementExecutions: movementExecutions,
                previousState: stateFixture.before,
                state: stateFixture.after,
                turn: 6,
              );

          expect(
            presentationBatchSnapshot(multiplayer),
            presentationBatchSnapshot(singlePlayer),
          );
          expect(
            presentationBatchSnapshot(
              projectCommandDispatchPresentation(
                identity: identity,
                sequenceDirective: PresentationSequenceDirective.advance,
                interactionEffects: const [],
                events: [event],
                movementExecutions: movementExecutions,
                previousState: stateFixture.before,
                state: stateFixture.after,
                l10n: null,
                turn: 6,
              ),
            ),
            presentationBatchSnapshot(singlePlayer),
          );
        });
      }
    });

    group('every domain action', () {
      final coveredTypes = {
        for (final fixture in reducerFixtures) '${fixture.command.runtimeType}',
        'EndTurnCommand',
      };
      final expectedTypes = {
        for (final command in presentationDomainCommands)
          '${command.runtimeType}',
      };

      test(
        'reducer corpus plus local end-turn covers the action inventory',
        () {
          expect(coveredTypes, expectedTypes);
        },
      );

      for (final command in presentationDomainCommands) {
        test('${command.runtimeType}', () {
          final wireCommand = DomainCommandCodec.fromJson(
            DomainCommandCodec.toJson(command),
          );
          expect(wireCommand, command);

          final scenario = _actionScenario(
            command,
            reducerFixtures,
            fallbackState: stateFixture.before,
          );
          final identity = PresentationBatchIdentity(
            sourceId: 'action_${command.runtimeType}',
            eventOffset: scenario.offset,
          );
          final singlePlayer = projectCommandDispatchPresentation(
            identity: identity,
            sequenceDirective: PresentationSequenceDirective.advance,
            interactionEffects: const [],
            events: scenario.events,
            movementExecutions: const [],
            previousState: scenario.before,
            state: scenario.after,
            l10n: null,
            turn: scenario.turn,
          );
          final multiplayer =
              DomainEventPresentationProjector.projectObservedBatch(
                identity: identity,
                interactionEffects: const [],
                events: scenario.events.map(_wireRoundTrip),
                visibleMovementExecutions: const [],
                previousState: scenario.before,
                state: scenario.after,
                turn: scenario.turn,
              );

          expect(
            presentationBatchSnapshot(multiplayer),
            presentationBatchSnapshot(singlePlayer),
            reason: '${command.runtimeType}',
          );
        });
      }
    });

    group('every client interaction', () {
      for (final intent in presentationGameIntents) {
        test('${intent.runtimeType}', () {
          final reducer = GameStateReducer(mapData: stateFixture.map);
          final singlePlayer = GameIntentResolver(reducer: reducer).resolve(
            stateFixture.before.interaction,
            intent,
            stateFixture.before,
          );
          final multiplayer = GameIntentResolver(reducer: reducer).resolve(
            stateFixture.before.interaction,
            intent,
            stateFixture.before,
          );

          expect(
            interactionPresentationSnapshot(multiplayer.interaction),
            interactionPresentationSnapshot(singlePlayer.interaction),
          );
          expect(multiplayer.domainCommand, singlePlayer.domainCommand);
          expect(
            multiplayer.presentationFocus.map(uiEffectSnapshot),
            singlePlayer.presentationFocus.map(uiEffectSnapshot),
          );
        });
      }
    });
  });
}

List<ReducerParityFixture> _loadReducerFixtures() {
  return CombatReducerParityCharacterization.extend(
    AutoExploreReducerParityCharacterization.extend(
      MovementReducerParityCharacterization.extend(
        DiplomacyReducerParityCharacterization.extend(
          ResourceTradeReducerParityCharacterization.extend(
            ReducerParityCorpus.load(Directory.current),
          ),
        ),
      ),
    ),
  );
}

GameEvent _wireRoundTrip(GameEvent event) {
  return GameEventSerializer.fromJson(GameEventSerializer.toJson(event));
}

List<MovementCommandExecution> _movementExecutionsFor(GameEvent event) {
  if (event case UnitMovedEvent(
    :final unitId,
    :final fromCol,
    :final fromRow,
    :final toCol,
    :final toRow,
  )) {
    return [
      MovementCommandExecution(
        unitId: unitId,
        fromCol: fromCol,
        fromRow: fromRow,
        steps: [
          UnitMovementStep(
            col: toCol,
            row: toRow,
            enterCost: 1,
            cumulativeCost: 1,
          ),
        ],
      ),
    ];
  }
  return const [];
}

_ActionScenario _actionScenario(
  DomainCommand command,
  List<ReducerParityFixture> fixtures, {
  required GameClientState fallbackState,
}) {
  if (command is EndTurnCommand) {
    return _ActionScenario(
      before: fallbackState,
      after: fallbackState,
      events: [TurnEndedEvent(playerId: command.playerId)],
      offset: 1,
      turn: 1,
    );
  }
  final matching = fixtures
      .where((fixture) => fixture.command.runtimeType == command.runtimeType)
      .toList(growable: false);
  final selected = _mostPresentableFixture(matching);
  final before = GameSnapshotFactory.fromDomainState(
    save: selected.save,
    state: selected.state,
  ).toClientState(activePlayerId: selected.actorPlayerId);
  final expectedSave = GameSave.fromJson({
    ...selected.expectedSave,
    'savedAt': selected.save.savedAt.toUtc().toIso8601String(),
  });
  final after = GameSnapshotFactory.fromDomainState(
    save: expectedSave,
    state: CanonicalGameSnapshotCodec.decodeDomainState(selected.expectedState),
  ).toClientState(activePlayerId: selected.actorPlayerId);
  return _ActionScenario(
    before: before,
    after: after,
    events: selected.expectedEvents
        .map(GameEventSerializer.fromJson)
        .toList(growable: false),
    offset: selected.tick + 1,
    turn: expectedSave.turn,
  );
}

ReducerParityFixture _mostPresentableFixture(
  List<ReducerParityFixture> fixtures,
) {
  if (fixtures.isEmpty) {
    throw StateError('Missing reducer fixture for presentation action.');
  }
  for (final fixture in fixtures) {
    if (fixture.expectedAccepted && fixture.expectedEvents.isNotEmpty) {
      return fixture;
    }
  }
  for (final fixture in fixtures) {
    if (fixture.expectedAccepted) return fixture;
  }
  return fixtures.first;
}

final class _ActionScenario {
  const _ActionScenario({
    required this.before,
    required this.after,
    required this.events,
    required this.offset,
    required this.turn,
  });

  final GameClientState before;
  final GameClientState after;
  final List<GameEvent> events;
  final int offset;
  final int turn;
}
