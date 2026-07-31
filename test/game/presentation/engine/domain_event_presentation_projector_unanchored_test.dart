part of 'domain_event_presentation_projector_observed_test.dart';

void _registerUnanchoredMovementProjectionTests() {
  test('uses authoritative execution for ambiguous duplicate events', () {
    final effects = DomainEventPresentationProjector.projectObserved(
      interactionEffects: const [],
      previousState: _state(aCol: 0, bCol: 0),
      state: _state(aCol: 2, bCol: 0),
      events: const [
        UnitMovedEvent(
          unitId: 'unit_a',
          fromCol: 0,
          fromRow: 0,
          toCol: 2,
          toRow: 0,
        ),
        UnitMovedEvent(
          unitId: 'unit_a',
          fromCol: 0,
          fromRow: 0,
          toCol: 2,
          toRow: 0,
        ),
      ],
      visibleMovementExecutions: [
        _execution('unit_a', 0, 0, 1, 0, 7, 7),
        _execution('unit_a', 1, 0, 2, 0, 13, 20),
      ],
    );

    expect(effects.whereType<AnimateUnitMoveEffect>().map(_snapshot), const [
      ('unit_a', 0, 0, 1, 0, 7, 7),
      ('unit_a', 1, 0, 2, 0, 13, 20),
    ]);
  });

  test('animates server-reviewed movement without a public event', () {
    final effects = DomainEventPresentationProjector.projectObserved(
      interactionEffects: const [],
      previousState: _state(aCol: 0),
      state: _state(aCol: 2),
      events: const [],
      visibleMovementExecutions: [
        _execution('unit_a', 0, 0, 1, 0, 7, 7),
        _execution('unit_a', 1, 0, 2, 0, 13, 20),
      ],
    );

    expect(effects.whereType<AnimateUnitMoveEffect>().map(_snapshot), const [
      ('unit_a', 0, 0, 1, 0, 7, 7),
      ('unit_a', 1, 0, 2, 0, 13, 20),
    ]);
  });

  test('keeps authoritative order when only one event is public', () {
    final effects = DomainEventPresentationProjector.projectObserved(
      interactionEffects: const [],
      previousState: _state(aCol: 0, bCol: 0),
      state: _state(aCol: 2, bCol: 1),
      events: const [
        UnitMovedEvent(
          unitId: 'unit_b',
          fromCol: 0,
          fromRow: 1,
          toCol: 1,
          toRow: 1,
        ),
      ],
      visibleMovementExecutions: _exactExecutions(),
    );

    expect(effects.whereType<AnimateUnitMoveEffect>().map(_snapshot), const [
      ('unit_a', 0, 0, 1, 0, 7, 7),
      ('unit_b', 0, 1, 1, 1, 11, 11),
      ('unit_a', 1, 0, 2, 0, 13, 20),
    ]);
  });
}
