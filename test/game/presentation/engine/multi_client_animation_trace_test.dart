import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/multi_client_animation_harness.dart';
import '../../../support/presentation_parity_events.dart';
import '../../../support/presentation_parity_state.dart';

const _sourceId = 'presentation_trace_match';
const _startMicrosUtc = 2000000000;
const _batchSpacingMicros = 60000000;

void main() {
  final state = PresentationParityStateFixture.build();
  final batches = _fullTurnBatches(state);

  test(
    'duplicate out-of-order latency jitter and reconnect converge exactly',
    () async {
      final harness = MultiClientAnimationHarness();
      for (final client in ['single', 'host', 'guest', 'jitter']) {
        harness.attachClient(client, sourceId: _sourceId, nextEventOffset: 1);
      }

      await _deliverOrder(harness, 'single', batches, const [0, 1, 2]);
      await _deliverOrder(harness, 'host', batches, const [0, 1, 1, 2, 0]);
      await _deliverOrder(harness, 'guest', batches, const [1, 0, 2, 1]);
      await _deliverOrder(harness, 'jitter', batches, const [2, 1, 0, 2]);

      final expected = harness.trace('single');
      for (final client in ['host', 'guest', 'jitter']) {
        expect(harness.trace(client), expected, reason: client);
      }

      for (final client in ['single', 'host', 'guest', 'jitter']) {
        await _deliverOrder(harness, client, batches, const [0, 1, 2]);
        expect(harness.trace(client), expected, reason: '$client reconnect');
        harness.verifyExactlyOnceAndNoOverlap(client);
      }
    },
  );

  test(
    'snapshot catch-up late join and replay have explicit lifecycles',
    () async {
      final harness = MultiClientAnimationHarness()
        ..attachClient('live', sourceId: _sourceId, nextEventOffset: 1);
      await _deliverOrder(harness, 'live', batches, const [0, 1, 2]);

      harness.attachClient('late', sourceId: _sourceId, nextEventOffset: 4);
      await _deliverOrder(harness, 'late', batches, const [0, 1, 2]);
      expect(harness.trace('late'), isEmpty);

      final future = _batch(
        state,
        offset: 4,
        events: presentationGameEvents.take(5),
      );
      await harness.deliver('live', future, arrivalMicrosUtc: 4000);
      await harness.deliver('late', future, arrivalMicrosUtc: 9000);
      expect(
        harness.traceForOffset('late', 4),
        harness.traceForOffset('live', 4),
      );

      harness.attachClient('replay', sourceId: _sourceId, nextEventOffset: 1);
      await _deliverOrder(
        harness,
        'replay',
        [...batches, future],
        const [0, 1, 2, 3],
      );
      expect(harness.trace('replay'), harness.trace('live'));
      harness.verifyExactlyOnceAndNoOverlap('replay');
    },
  );

  test(
    'representative full-turn animation trace matches reviewed golden',
    () async {
      final goldenBatch = _batch(
        state,
        offset: 1,
        events: [
          presentationGameEvents.whereType<CityFoundedEvent>().single,
          presentationGameEvents.whereType<UnitMovedEvent>().single,
          presentationGameEvents.whereType<TechnologyResearchedEvent>().single,
          presentationGameEvents.whereType<TurnEndedEvent>().single,
        ],
      );
      final harness = MultiClientAnimationHarness()
        ..attachClient('golden', sourceId: _sourceId, nextEventOffset: 1);
      await harness.deliver('golden', goldenBatch, arrivalMicrosUtc: 1000);
      final actual = const JsonEncoder.withIndent(
        '  ',
      ).convert(harness.trace('golden'));
      final golden = File(
        'test/fixtures/presentation/full_turn_animation_trace.json',
      ).readAsStringSync();

      expect(actual, golden.trimRight());
    },
  );
}

List<ProjectedGameEffectBatch> _fullTurnBatches(
  PresentationParityStateFixture state,
) {
  return [
    _batch(state, offset: 1, events: presentationGameEvents.take(14)),
    _batch(state, offset: 2, events: presentationGameEvents.skip(14).take(14)),
    _batch(state, offset: 3, events: presentationGameEvents.skip(28)),
  ];
}

ProjectedGameEffectBatch _batch(
  PresentationParityStateFixture state, {
  required int offset,
  required Iterable<GameEvent> events,
}) {
  final wireEvents = events
      .map(
        (event) =>
            GameEventSerializer.fromJson(GameEventSerializer.toJson(event)),
      )
      .toList(growable: false);
  return DomainEventPresentationProjector.projectObservedBatch(
    identity: PresentationBatchIdentity(
      sourceId: _sourceId,
      eventOffset: offset,
      authoritativeTick: 100 + offset,
      authoritativeStartMicrosUtc:
          _startMicrosUtc + (offset - 1) * _batchSpacingMicros,
    ),
    interactionEffects: const [],
    events: wireEvents,
    visibleMovementExecutions: const [],
    previousState: state.before,
    state: state.after,
    turn: 6,
  );
}

Future<void> _deliverOrder(
  MultiClientAnimationHarness harness,
  String client,
  List<ProjectedGameEffectBatch> batches,
  List<int> order,
) async {
  var arrival = 1000;
  for (final index in order) {
    await harness.deliver(client, batches[index], arrivalMicrosUtc: arrival);
    arrival += 173;
  }
}
