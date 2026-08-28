import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_activity_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_command_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('ends a local turn only after the accepted recipient patch', () async {
    final nextPlayer = PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: testSessionStamp(revision: 1, stateDigest: 'd' * 64),
      turn: 2,
      pendingAction: null,
      units: const [],
    );
    final session = FakeGameSession.success(
      testMapScene(),
      turnResult: TurnCommandResultView.accepted(
        player: nextPlayer,
        activities: const [
          TurnActivityView(
            identity: TurnActivityIdentityView(revision: 1, eventIndex: 0),
            kind: TurnActivityKindView.turnEnded,
          ),
        ],
        evidence: TurnKernelEvidenceView(
          processors: const ['movement'],
          foundedCityIds: const [],
          combatExecutionCount: 0,
          resetUnitIds: const [],
          movementExecutionCount: 0,
          invalidatedOrderUnitIds: const [],
          finishedAutoExploreUnitIds: const [],
        ),
      ),
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);
    await controller.load();

    controller.endTurn();
    controller.endTurn();
    await Future<void>.delayed(Duration.zero);

    final ready = controller.state as GameSessionReady;
    expect(session.endTurnCalls, 1);
    expect(session.lastEndTurnExpectedRevision, 0);
    expect(ready.recipient.turn, 2);
    expect(
      ready.turnPresentations.latestActivity?.kind,
      TurnActivityKindView.turnEnded,
    );
    expect(ready.turnAction.inFlight, isFalse);
  });

  test('keeps authoritative state after a rejected end turn', () async {
    final session = FakeGameSession.success(
      testMapScene(),
      turnResult: const TurnCommandResultView.rejected(
        code: TurnRejectionCodeView.playerNotActive,
      ),
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);
    await controller.load();

    controller.endTurn();
    await Future<void>.delayed(Duration.zero);

    final ready = controller.state as GameSessionReady;
    expect(ready.recipient.turn, 1);
    expect(
      ready.turnAction.failure?.rejectionCode,
      TurnRejectionCodeView.playerNotActive,
    );
  });
}

MapCoordinator _controller(FakeGameSession session) => MapCoordinator(
  session: session,
  movement: session,
  unitActions: session,
  logistics: session,
  turns: session,
);
