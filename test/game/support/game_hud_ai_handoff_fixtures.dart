import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/player/handoff_provider.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_hud_shared_fixtures.dart';

const aiChainPlayers = [
  hudPlayer,
  Player(
    id: 'player_2',
    name: 'AI Bob',
    colorValue: 0xFFc45050,
    kind: PlayerKind.ai,
    ai: AiPlayer(
      strategyId: AiStrategyId.random,
      difficulty: AiDifficulty.normal,
      persona: AiPersona.balanced,
      seed: 2,
    ),
  ),
  Player(
    id: 'player_3',
    name: 'AI Cora',
    colorValue: 0xFF70a45d,
    kind: PlayerKind.ai,
    ai: AiPlayer(
      strategyId: AiStrategyId.random,
      difficulty: AiDifficulty.normal,
      persona: AiPersona.balanced,
      seed: 3,
    ),
  ),
  Player(
    id: 'player_4',
    name: 'AI Dale',
    colorValue: 0xFFb8854f,
    kind: PlayerKind.ai,
    ai: AiPlayer(
      strategyId: AiStrategyId.random,
      difficulty: AiDifficulty.normal,
      persona: AiPersona.balanced,
      seed: 4,
    ),
  ),
];

const aiChainPlayerStates = {
  'player_1': PlayerTurnState.finished,
  'player_2': PlayerTurnState.active,
  'player_3': PlayerTurnState.active,
  'player_4': PlayerTurnState.active,
};

final class AiChainFixture {
  const AiChainFixture({
    required this.save,
    required this.repository,
    required this.renderer,
    this.queuedUnit,
  });

  final GameSave save;
  final FakeHudRepository repository;
  final HudTestRenderer renderer;
  final GameUnit? queuedUnit;
}

AiChainFixture createHotseatAiChainFixture() {
  final save = hudSave.copyWith(
    players: aiChainPlayers,
    playerStates: aiChainPlayerStates,
  );
  final renderer = HudTestRenderer(mapData: hudMap());
  return AiChainFixture(
    save: save,
    renderer: renderer,
    repository: FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          activePlayerId: 'player_1',
          activePlayerCanAct: false,
        ),
      ),
    ),
  );
}

AiChainFixture createMultiplayerAiChainFixture() {
  final save = hudSave.copyWith(
    gameMode: GameMode.multiplayer,
    players: aiChainPlayers,
    playerStates: aiChainPlayerStates,
  );
  final queuedUnit =
      GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0)
          .copyWith(movementPoints: 0)
          .copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 1,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
                UnitMovementStep(
                  col: 1,
                  row: 0,
                  enterCost: 1,
                  cumulativeCost: 1,
                ),
              ],
            ),
          );
  final aiUnits = [
    for (final unit in const [
      ('player_2', 2, 2),
      ('player_3', 0, 2),
      ('player_4', 2, 0),
    ])
      GameUnit.startingCommander(
        ownerPlayerId: unit.$1,
        col: unit.$2,
        row: unit.$3,
      ).copyWith(movementPoints: 0),
  ];
  final renderer = HudTestRenderer(mapData: hudMap());
  return AiChainFixture(
    save: save,
    queuedUnit: queuedUnit,
    renderer: renderer,
    repository: FakeHudRepository(
      snapshot: GameSnapshotFactory.fromClientState(
        save: save,
        state: GameClientState(
          units: [queuedUnit, ...aiUnits],
          activePlayerId: 'player_1',
          activePlayerCanAct: false,
          submittedPlayerIds: const {'player_1'},
        ),
      ),
    ),
  );
}

Future<void> waitForHotseatAiChain(
  WidgetTester tester,
  ProviderContainer container,
  AiChainFixture fixture,
) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump();
    await tester.runAsync(() async {
      for (var tick = 0; tick < 40; tick++) {
        final handoff = container.read(gameHandoffProvider);
        if (fixture.repository.snapshot.save.turn > fixture.save.turn &&
            handoff?.playerId == 'player_1') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    final handoff = container.read(gameHandoffProvider);
    if (fixture.repository.snapshot.save.turn > fixture.save.turn &&
        handoff?.playerId == 'player_1') {
      break;
    }
  }
  await tester.pump();
}

Future<void> waitForMultiplayerAiChain(
  WidgetTester tester,
  ProviderContainer container,
  AiChainFixture fixture,
) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump();
    await tester.runAsync(() async {
      for (var tick = 0; tick < 40; tick++) {
        final state = container.read(gameStateProvider('save')).value;
        if (fixture.repository.snapshot.save.turn > fixture.save.turn &&
            state?.activePlayerId == 'player_1' &&
            (state?.activePlayerCanAct ?? false)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    final state = container.read(gameStateProvider('save')).value;
    if (fixture.repository.snapshot.save.turn > fixture.save.turn &&
        state?.activePlayerId == 'player_1' &&
        (state?.activePlayerCanAct ?? false)) {
      break;
    }
  }
  await tester.pump();
}
