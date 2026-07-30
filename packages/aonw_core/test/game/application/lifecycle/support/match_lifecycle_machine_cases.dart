import 'package:aonw_core/application.dart';
import 'package:test/test.dart';

typedef _LifecycleCase = ({
  String name,
  MatchLifecycleState state,
  MatchLifecycleAction action,
  MatchLifecycleState? next,
  String? rejection,
  bool changed,
});

const _open = OpenMatchLifecycleState();
const _running = RunningMatchLifecycleState();
const _finished = FinishedMatchLifecycleState(
  reason: MatchCompletionReason.conquest,
);
const _abandoned = AbandonedMatchLifecycleState(
  reason: MatchAbandonmentReason.ownerLeft,
);

const _cases = <_LifecycleCase>[
  (
    name: 'open starts',
    state: _open,
    action: StartMatchLifecycle(),
    next: _running,
    rejection: null,
    changed: true,
  ),
  (
    name: 'open can be abandoned',
    state: _open,
    action: AbandonMatchLifecycle(MatchAbandonmentReason.ownerLeft),
    next: _abandoned,
    rejection: null,
    changed: true,
  ),
  (
    name: 'open cannot finish',
    state: _open,
    action: FinishMatchLifecycle(MatchCompletionReason.conquest),
    next: null,
    rejection: 'invalid_lifecycle_transition',
    changed: false,
  ),
  (
    name: 'running can finish',
    state: _running,
    action: FinishMatchLifecycle(MatchCompletionReason.conquest),
    next: _finished,
    rejection: null,
    changed: true,
  ),
  (
    name: 'running can be abandoned',
    state: _running,
    action: AbandonMatchLifecycle(MatchAbandonmentReason.ownerLeft),
    next: _abandoned,
    rejection: null,
    changed: true,
  ),
  (
    name: 'duplicate start loses race with running state',
    state: _running,
    action: StartMatchLifecycle(),
    next: null,
    rejection: 'match_not_open',
    changed: false,
  ),
  (
    name: 'duplicate identical finish is idempotent',
    state: _finished,
    action: FinishMatchLifecycle(MatchCompletionReason.conquest),
    next: _finished,
    rejection: null,
    changed: false,
  ),
  (
    name: 'terminal finish cannot be rewritten',
    state: _finished,
    action: FinishMatchLifecycle(MatchCompletionReason.draw),
    next: null,
    rejection: 'match_terminal',
    changed: false,
  ),
  (
    name: 'finished cannot be abandoned',
    state: _finished,
    action: AbandonMatchLifecycle(MatchAbandonmentReason.playerLeft),
    next: null,
    rejection: 'match_terminal',
    changed: false,
  ),
  (
    name: 'finished cannot start',
    state: _finished,
    action: StartMatchLifecycle(),
    next: null,
    rejection: 'match_terminal',
    changed: false,
  ),
  (
    name: 'duplicate identical abandonment is idempotent',
    state: _abandoned,
    action: AbandonMatchLifecycle(MatchAbandonmentReason.ownerLeft),
    next: _abandoned,
    rejection: null,
    changed: false,
  ),
  (
    name: 'terminal abandonment cannot be rewritten',
    state: _abandoned,
    action: AbandonMatchLifecycle(MatchAbandonmentReason.playerLeft),
    next: null,
    rejection: 'match_terminal',
    changed: false,
  ),
  (
    name: 'abandoned cannot start',
    state: _abandoned,
    action: StartMatchLifecycle(),
    next: null,
    rejection: 'match_terminal',
    changed: false,
  ),
  (
    name: 'abandoned cannot finish',
    state: _abandoned,
    action: FinishMatchLifecycle(MatchCompletionReason.conquest),
    next: null,
    rejection: 'match_terminal',
    changed: false,
  ),
];

void registerMatchLifecycleMachineCases(MatchLifecycleMachine machine) {
  for (final testCase in _cases) {
    test(testCase.name, () {
      final result = machine.apply(testCase.state, testCase.action);
      if (testCase.next case final expected?) {
        expect(result, isA<MatchLifecycleAccepted>());
        final accepted = result as MatchLifecycleAccepted;
        expect(accepted.state, expected);
        expect(accepted.changed, testCase.changed);
      } else {
        expect(result, isA<MatchLifecycleRejected>());
        final rejected = result as MatchLifecycleRejected;
        expect(rejected.state, same(testCase.state));
        expect(rejected.reason.code, testCase.rejection);
      }
    });
  }
}
