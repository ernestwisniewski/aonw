part of 'replay_service_test.dart';

void _registerReplayCommandBoundaryTest() {
  test('rejects presentation intents in authoritative replay logs', () async {
    final service = _service(
      replayStore: _MemoryReplayStore({'save_1': _snapshot()}),
      eventLog: _MemoryEventLog([
        LoggedCommand(
          offset: 1,
          timestamp: DateTime.utc(2026, 4, 24, 12, 1),
          turn: 1,
          command: const FocusTurnStartActionCommand('p1'),
        ),
      ]),
    );

    await expectLater(
      service.buildTimeline('save_1'),
      throwsA(
        isA<ReplayBuildException>()
            .having(
              (error) => error.reason,
              'reason',
              ReplayBuildFailureReason.corruptLog,
            )
            .having(
              (error) => error.message,
              'message',
              contains('presentation intent'),
            ),
      ),
    );
  });
}
