import 'dart:io';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/reducer_parity_fixture.dart';

const _repeatCount = 3;

void main() {
  group('local reducer parity fixtures', () {
    for (final variant in const [
      (name: 'canonical map order', reverseInputMapEntries: false),
      (name: 'reversed map order', reverseInputMapEntries: true),
    ]) {
      final fixtures = ReducerParityCorpus.load(
        Directory.current,
        reverseInputMapEntries: variant.reverseInputMapEntries,
      );
      group(variant.name, () {
        for (final fixture in fixtures) {
          for (var run = 1; run <= _repeatCount; run++) {
            test('${fixture.id} run $run', () => _runFixture(fixture));
          }
        }
      });
    }
  });
}

void _runFixture(ReducerParityFixture fixture) {
  final baseSnapshot = SaveSnapshot.fromPersistentState(
    save: fixture.save,
    state: fixture.state,
  );
  final initialState = baseSnapshot.toGameState(
    activePlayerId: fixture.actorPlayerId,
  );
  expect(
    initialState.toPersistentState().toJson(),
    fixture.state.toJson(),
    reason: '${fixture.id} cannot lose canonical input before reduction',
  );

  final ruleset = GameRuleset.standard().copyWith(
    paceBalance: fixture.save.matchRules.paceBalance,
  );
  final result =
      LocalCommandResolver(
        reducer: GameStateReducer(mapData: fixture.mapData, ruleset: ruleset),
      ).resolve(
        baseSnapshot: baseSnapshot,
        currentState: initialState,
        command: fixture.command,
        savedAt: fixture.now,
        context: GameCommandContext(
          actorPlayerId: fixture.actorPlayerId,
          commandTick: fixture.tick,
        ),
      );

  expect(reducerParitySave(result.save), fixture.expectedSave);
  expect(result.state.toPersistentState().toJson(), fixture.expectedState);
  expect(reducerParityEvents(result.events), fixture.expectedEvents);
  expect(result.save.savedAt, fixture.now);
  if (!fixture.expectedAccepted) {
    expect(result.events, isEmpty);
    expect(result.state.toPersistentState().toJson(), fixture.state.toJson());
  }
}
