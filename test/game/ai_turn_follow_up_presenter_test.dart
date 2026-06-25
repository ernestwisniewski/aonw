import 'package:aonw/game/application/services/ai_turn_follow_up_planner.dart';
import 'package:aonw/game/application/services/game_handoff.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/services/ai_turn_follow_up_presenter.dart';
import 'package:aonw/game/presentation/services/turn_presentation_sequencer.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnFollowUpPresenter', () {
    test('clears multiplayer handoff and schedules the next AI', () async {
      final calls = <String>[];
      final presenter = _presenter(calls);

      final nextAi = await presenter.present(
        action: const AiTurnFollowUpScheduleAi('ai_2'),
        gameMode: GameMode.multiplayer,
        localAiRuntimeEnabled: true,
        terminalUiEffects: const [],
      );

      expect(nextAi, 'ai_2');
      expect(calls, const ['clear']);
    });

    test('clears hot-seat handoff before scheduling another AI', () async {
      final calls = <String>[];
      final presenter = _presenter(calls);

      final nextAi = await presenter.present(
        action: const AiTurnFollowUpScheduleAi('ai_2'),
        gameMode: GameMode.hotSeat,
        localAiRuntimeEnabled: true,
        terminalUiEffects: const [],
      );

      expect(nextAi, 'ai_2');
      expect(calls, const ['clear']);
    });

    test('sets hot-seat handoff data for human player', () async {
      final handoffs = <HandoffData>[];
      final presenter = _presenter(
        <String>[],
        handoffs: handoffs,
        playerNameFormatter: (player) => 'formatted ${player.name}',
      );

      await presenter.present(
        action: const AiTurnFollowUpHotSeatHandoff(
          player: _human,
          turnNumber: 7,
          freshTurn: true,
        ),
        gameMode: GameMode.hotSeat,
        localAiRuntimeEnabled: true,
        terminalUiEffects: const [],
      );

      expect(handoffs, hasLength(1));
      expect(handoffs.single.playerId, 'human');
      expect(handoffs.single.playerName, 'formatted Human');
      expect(handoffs.single.playerColorValue, _human.colorValue);
      expect(handoffs.single.turnNumber, 7);
      expect(handoffs.single.freshTurn, isTrue);
    });

    test(
      'delegates human turn start sequence and logs turn-advance report',
      () async {
        final calls = <String>[];
        final reports = <TurnPresentationReport>[];
        final presenter = _presenter(calls, reports: reports);

        await presenter.present(
          action: const AiTurnFollowUpConfirmHumanTurn(
            playerId: 'human',
            playTurnAdvanceEffects: true,
          ),
          gameMode: GameMode.multiplayer,
          localAiRuntimeEnabled: true,
          terminalUiEffects: const [
            ShowFloatingTextEffect(
              text: 'turn',
              col: 1,
              row: 2,
              colorValue: 0xFFFFFFFF,
            ),
          ],
        );

        expect(calls, const [
          'clear',
          'effects:1',
          'confirm:human',
          'focus:human',
          'report:1',
        ]);
        expect(reports, hasLength(1));
        expect(reports.single.turnAdvanceEffectCount, 1);
      },
    );
  });
}

AiTurnFollowUpPresenter _presenter(
  List<String> calls, {
  List<HandoffData>? handoffs,
  List<TurnPresentationReport>? reports,
  String Function(Player player)? playerNameFormatter,
}) {
  return AiTurnFollowUpPresenter(
    clearHandoff: () => calls.add('clear'),
    setHandoff: (handoff) {
      calls.add('handoff:${handoff.playerId}');
      handoffs?.add(handoff);
    },
    playerNameFormatter: playerNameFormatter ?? (player) => player.name,
    logTurnAdvanceReport: (report) {
      calls.add('report:${report.turnAdvanceEffectCount}');
      reports?.add(report);
    },
    turnPresentationSequencer: TurnPresentationSequencer(
      playTurnAdvanceEffects: (effects) async {
        calls.add('effects:${effects.length}');
        return effects.length;
      },
      confirmHumanTurn: (playerId) async {
        calls.add('confirm:$playerId');
      },
      focusTurnStartMapTarget: (playerId) async {
        calls.add('focus:$playerId');
      },
    ),
  );
}

const _human = Player(id: 'human', name: 'Human', colorValue: 0xFF2563EB);
