import 'package:aonw_core/ai/mcts/mcts_simulation_projection.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'mcts_simulator_parity_support.dart';

const _firstOpponentId = 'player_2';
const _secondOpponentId = 'player_3';
const _opponentMessageId = 'message_from_first_opponent';

void main() {
  test('each opponent observes the canonical commands applied before it', () {
    final strategy = _CapturingOpponentStrategy();
    final mapView = MctsSimulatorParityFixtures.mapData().indexedReadView();
    final initialState = _initialState();
    final baseSnapshot = MctsSimulatorParityFixtures.engineSnapshot(
      initialState,
    );
    final initialSnapshot = baseSnapshot.copyWith(
      domain: baseSnapshot.domain.copyWith(turn: 9),
    );
    final root = SimulatedState.fromView(
      GameView.fromPersistentState(
        initialState,
        forPlayerId: 'player_1',
        turn: 9,
        mapData: mapView,
        ruleset: GameRuleset.defaults,
        engineSnapshot: initialSnapshot,
        ignoreFogOfWar: true,
      ),
      maxPlanningDepth: 8,
    );

    final advanced = TracingMctsSimulator(
      opponentStrategy: strategy,
      simulateOpponentPlans: true,
    ).advanceTurn(root);
    final secondOpponentView = strategy.secondOpponentView!;
    final observedMessage =
        secondOpponentView.diplomacy.messages[_opponentMessageId]!;

    expect(secondOpponentView.forPlayerId, _secondOpponentId);
    expect(
      secondOpponentView.research
          .forPlayer(_firstOpponentId)
          .activeTechnologyId,
      TechnologyId.agriculture,
    );
    expect(
      secondOpponentView.engineSnapshot!.domain.research,
      secondOpponentView.research,
    );
    expect(
      secondOpponentView.engineSnapshot!.domain.diplomacy,
      secondOpponentView.diplomacy,
    );
    expect(observedMessage.createdTurn, 9);
    expect(observedMessage.expiresOnTurn, 14);

    final nextView = advanced.view;
    final nextSnapshot = nextView.engineSnapshot!;
    final persistentProjection =
        MctsSimulationProjection.persistentStateFromView(
          nextView,
          units: nextView.movementBlockingUnits,
          cities: [...nextView.ownCities, ...nextView.rememberedEnemyCities],
          research: nextView.research,
        );
    final finalMessage = nextView.diplomacy.messages[_opponentMessageId]!;

    expect(nextView.turn, 10);
    expect(finalMessage.response, DiplomaticMessageResponse.conciliatory);
    expect(finalMessage.respondedTurn, 9);
    expect(persistentProjection.research, nextView.research);
    expect(persistentProjection.runtimeState.diplomacy, nextView.diplomacy);
    expect(nextSnapshot.domain.turn, nextView.turn);
    expect(nextSnapshot.domain.research, nextView.research);
    expect(nextSnapshot.domain.diplomacy, nextView.diplomacy);
    _expectTurnDerivedDiplomacyUsesTurn(nextView, mapView);
  });
}

final class _CapturingOpponentStrategy implements AiStrategy {
  GameView? secondOpponentView;

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    if (view.forPlayerId == _firstOpponentId) {
      return AiTurnPlan(
        commands: const [
          SelectTechnologyCommand(_firstOpponentId, TechnologyId.agriculture),
          SendDiplomaticMessageCommand(
            playerId: _firstOpponentId,
            targetPlayerId: _secondOpponentId,
            topic: DiplomaticMessageTopic.troopsNearCities,
            messageId: _opponentMessageId,
          ),
        ],
      );
    }
    if (view.forPlayerId != _secondOpponentId) return AiTurnPlan.empty;
    secondOpponentView = view;
    if (!_observesFirstOpponentCommands(view)) return AiTurnPlan.empty;
    return AiTurnPlan(
      commands: const [
        RespondDiplomaticMessageCommand(
          playerId: _secondOpponentId,
          messageId: _opponentMessageId,
          response: DiplomaticMessageResponse.conciliatory,
        ),
      ],
    );
  }

  bool _observesFirstOpponentCommands(GameView view) {
    final snapshot = view.engineSnapshot;
    if (snapshot == null) return false;
    final viewTechnology = view.research
        .forPlayer(_firstOpponentId)
        .activeTechnologyId;
    final snapshotTechnology = snapshot.domain.research
        .forPlayer(_firstOpponentId)
        .activeTechnologyId;
    return viewTechnology == TechnologyId.agriculture &&
        snapshotTechnology == TechnologyId.agriculture &&
        view.diplomacy.messages.containsKey(_opponentMessageId) &&
        snapshot.domain.diplomacy.messages.containsKey(_opponentMessageId);
  }
}

PersistentGameState _initialState() {
  return PersistentGameState.snapshot(
    playerColors: const {
      'player_1': 1,
      _firstOpponentId: 2,
      _secondOpponentId: 3,
    },
    units: [
      _unit('unit_1', 'player_1', 0),
      _unit('unit_2', _firstOpponentId, 1),
      _unit('unit_3', _secondOpponentId, 2),
    ],
    runtimeState: GameRuntimeState.snapshot(
      diplomacy: DiplomacyState.empty
          .addContact('player_1', _firstOpponentId)
          .addContact(_firstOpponentId, _secondOpponentId),
    ),
  );
}

GameUnit _unit(String id, String playerId, int col) {
  return GameUnit(
    id: id,
    ownerPlayerId: playerId,
    type: GameUnitType.warrior,
    name: 'Warrior',
    col: col,
    row: 0,
  );
}

void _expectTurnDerivedDiplomacyUsesTurn(
  GameView nextView,
  MapReadView mapView,
) {
  final nextSnapshot = nextView.engineSnapshot!;
  final afterMessage = SimulatedState.fromView(nextView, maxPlanningDepth: 8)
      .apply(
        const CommandMctsAction(
          SendDiplomaticMessageCommand(
            playerId: 'player_1',
            targetPlayerId: _firstOpponentId,
            topic: DiplomaticMessageTopic.troopsNearCities,
            messageId: 'message_after_advance',
          ),
        ),
      )
      .view;
  final message = afterMessage.diplomacy.messages['message_after_advance']!;
  expect(message.createdTurn, 10);
  expect(message.expiresOnTurn, 15);

  final proposalResult = const GameEngine().apply(
    snapshot: nextSnapshot,
    command: const SendDiplomaticProposalCommand(
      playerId: 'player_1',
      targetPlayerId: _firstOpponentId,
      kind: DiplomaticProposalKind.friendship,
      proposalId: 'proposal_after_advance',
    ),
    context: GameEngineContext(
      actorPlayerId: 'player_1',
      mapView: mapView,
      ruleset: GameRuleset.defaults,
      commandTick: 10,
    ),
  );
  expect(proposalResult, isA<GameEngineAccepted>());
  final proposal = proposalResult
      .snapshot
      .domain
      .diplomacy
      .pendingProposals['proposal_after_advance']!;
  expect(proposal.createdTurn, 10);
  expect(proposal.expiresOnTurn, 15);

  final truceSnapshot = nextSnapshot.copyWith(
    domain: nextSnapshot.domain.copyWith(
      diplomacy: nextSnapshot.domain.diplomacy.setStatus(
        'player_1',
        _firstOpponentId,
        DiplomaticRelationStatus.truce,
        turn: 5,
        statusExpiresOnTurn: 10,
      ),
    ),
  );
  final warResult = const GameEngine().apply(
    snapshot: truceSnapshot,
    command: const DeclareWarCommand(
      playerId: 'player_1',
      targetPlayerId: _firstOpponentId,
    ),
    context: GameEngineContext(
      actorPlayerId: 'player_1',
      mapView: mapView,
      ruleset: GameRuleset.defaults,
      commandTick: 11,
    ),
  );
  expect(warResult, isA<GameEngineAccepted>());
  final warDiplomacy = warResult.snapshot.domain.diplomacy;
  expect(
    warDiplomacy.relationBetween('player_1', _firstOpponentId).lastChangedTurn,
    10,
  );
  expect(
    warDiplomacy.scoreEntriesBetween('player_1', _firstOpponentId).last.turn,
    10,
  );
}
