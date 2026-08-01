import 'dart:io';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/reducer_parity_auto_explore_characterization.dart';
import '../../../support/reducer_parity_combat_characterization.dart';
import '../../../support/reducer_parity_diplomacy_characterization.dart';
import '../../../support/reducer_parity_fixture.dart';
import '../../../support/reducer_parity_movement_characterization.dart';
import '../../../support/reducer_parity_resource_trade_characterization.dart';

const _repeatCount = 3;

void main() {
  group('local reducer parity fixtures', () {
    for (final variant in const [
      (name: 'canonical map order', reverseInputMapEntries: false),
      (name: 'reversed map order', reverseInputMapEntries: true),
    ]) {
      final fixtures = CombatReducerParityCharacterization.extend(
        AutoExploreReducerParityCharacterization.extend(
          MovementReducerParityCharacterization.extend(
            DiplomacyReducerParityCharacterization.extend(
              ResourceTradeReducerParityCharacterization.extend(
                ReducerParityCorpus.load(
                  Directory.current,
                  reverseInputMapEntries: variant.reverseInputMapEntries,
                ),
              ),
            ),
          ),
        ),
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
  final baseSnapshot = GameSnapshotFactory.fromDomainState(
    save: fixture.save,
    state: fixture.state,
  );
  final initialState = baseSnapshot.toClientState(
    activePlayerId: fixture.actorPlayerId,
  );
  expect(
    CanonicalGameSnapshotCodec.encodeDomainState(initialState.domain),
    CanonicalGameSnapshotCodec.encodeDomainState(fixture.state),
    reason: '${fixture.id} cannot lose canonical input before reduction',
  );

  final ruleset = GameRuleset.standard().copyWith(
    paceBalance: fixture.save.matchRules.paceBalance,
  );
  final command = fixture.command;
  expect(command, isA<DomainCommand>());
  final result =
      LocalCommandResolver(
        reducer: GameStateReducer(mapData: fixture.mapData, ruleset: ruleset),
      ).resolve(
        baseSnapshot: baseSnapshot,
        currentState: initialState,
        command: command,
        savedAt: fixture.now,
        context: GameCommandContext(
          actorPlayerId: fixture.actorPlayerId,
          commandTick: fixture.tick,
        ),
      );

  expect(reducerParitySave(result.snapshot.save), fixture.expectedSave);
  expect(
    CanonicalGameSnapshotCodec.encodeDomainState(result.state.domain),
    fixture.expectedState,
  );
  expect(reducerParityEvents(result.events), fixture.expectedEvents);
  expect(result.snapshot.metadata.savedAtUtc, fixture.now);
  if (!fixture.expectedAccepted &&
      (fixture.id.startsWith('resource-trade-characterization-') ||
          fixture.id.startsWith('diplomacy-characterization-') ||
          fixture.id.startsWith('movement-characterization-') ||
          fixture.id.startsWith('combat-characterization-'))) {
    expect(result.state, same(initialState));
    expect(result.events, isEmpty);
  }
  if (!fixture.expectedAccepted) {
    expect(result.events, isEmpty);
    expect(
      CanonicalGameSnapshotCodec.encodeDomainState(result.state.domain),
      CanonicalGameSnapshotCodec.encodeDomainState(fixture.state),
    );
  }
}
