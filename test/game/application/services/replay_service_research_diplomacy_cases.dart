part of 'replay_service_test.dart';

void _registerResearchDiplomacyReplayTest() {
  test('replays research and diplomacy through the game engine', () async {
    final service = _service(
      replayStore: _MemoryReplayStore({
        'save_1': _snapshot(
          players: const [
            Player(id: 'p1', name: 'Alice', colorValue: 0xFF4A7FC4),
            Player(id: 'p2', name: 'Bob', colorValue: 0xFFC47F4A),
          ],
          runtimeState: GameRuntimeState(
            diplomacy: DiplomacyState.empty.addContact('p1', 'p2'),
            pendingAction: const PendingResearchSelection(ownerPlayerId: 'p1'),
          ),
        ),
      }),
      eventLog: _MemoryEventLog([
        RecordedDomainCommand(
          offset: 1,
          timestamp: DateTime.utc(2026, 4, 24, 12, 1),
          turn: 1,
          actorPlayerId: 'p1',
          command: const SelectTechnologyCommand(
            'p1',
            TechnologyId.agriculture,
          ),
        ),
        RecordedDomainCommand(
          offset: 2,
          timestamp: DateTime.utc(2026, 4, 24, 12, 2),
          turn: 1,
          actorPlayerId: 'p1',
          command: const SendDiplomaticProposalCommand(
            playerId: 'p1',
            targetPlayerId: 'p2',
            kind: DiplomaticProposalKind.friendship,
            proposalId: 'proposal_1',
          ),
          events: const [
            DiplomaticProposalSentEvent(
              proposalId: 'proposal_1',
              fromPlayerId: 'p1',
              toPlayerId: 'p2',
              kind: DiplomaticProposalKind.friendship,
              expiresOnTurn: 6,
            ),
          ],
        ),
      ]),
    );

    final timeline = await service.buildTimeline('save_1');

    expect(timeline.steps, hasLength(2));
    expect(
      timeline.steps.first.state.research.forPlayer('p1').activeTechnologyId,
      TechnologyId.agriculture,
    );
    expect(timeline.steps.first.state.pendingAction, isNull);
    expect(timeline.steps.last.state.diplomacy.pendingProposals.keys, [
      'proposal_1',
    ]);
    expect(timeline.steps.last.events.map(GameEventSerializer.toJson), [
      {
        'type': 'DiplomaticProposalSent',
        'proposalId': 'proposal_1',
        'fromPlayerId': 'p1',
        'toPlayerId': 'p2',
        'kind': 'friendship',
        'expiresOnTurn': 6,
      },
    ]);
    expect(timeline.steps.map((step) => step.effectiveActorPlayerId), [
      'p1',
      'p1',
    ]);
  });
}
