import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/rust_game_session_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runs a complete strategic AI turn on the retained native isolate',
    () async {
      final gateway = RustGameSessionGateway(assets: _FileAssetBundle());
      addTearDown(gateway.close);
      final scene = await gateway.startLocalMatch(_setup());

      final humanTurn = await gateway.endTurn(
        expectedRevision: scene.player.stamp.revision,
      );
      expect(humanTurn.accepted, isTrue);

      await expectLater(
        gateway.advanceAiTurn(
          LocalAiTurnRequestView(
            aiPlayerId: 'player-2',
            humanPlayerId: 'preview-player',
            commandBudget: 1025,
          ),
        ),
        throwsA(
          isA<LocalGameSessionException>()
              .having(
                (error) => error.code,
                'code',
                'invalid_ai_command_budget',
              )
              .having(
                (error) => error.resyncedPlayer?.actorPlayerId,
                'restored actor',
                'preview-player',
              ),
        ),
      );

      var eventLoopHeartbeat = false;
      Timer.run(() => eventLoopHeartbeat = true);
      final execution = await gateway.advanceAiTurn(
        LocalAiTurnRequestView(
          aiPlayerId: 'player-2',
          humanPlayerId: 'preview-player',
        ),
      );

      expect(eventLoopHeartbeat, isTrue);
      expect(execution.aiPlayerId, 'player-2');
      expect(execution.completedTurn, isTrue);
      expect(execution.executedCommands, greaterThan(0));
      expect(execution.player.actorPlayerId, 'preview-player');
      expect(
        execution.player.stamp.revision,
        greaterThan(humanTurn.player!.stamp.revision),
      );
    },
  );
}

LocalMatchSetupView _setup() => LocalMatchSetupView(
  assets: MapAssetPaths.starter,
  participants: [
    LocalParticipantSetupView(
      id: 'preview-player',
      name: 'Player',
      colorValue: 0xff3d5a80,
      country: LocalPlayerCountryView.poland,
      control: LocalPlayerControlView.human,
    ),
    LocalParticipantSetupView(
      id: 'player-2',
      name: 'AI',
      colorValue: 0xffee6c4d,
      country: LocalPlayerCountryView.japan,
      control: LocalPlayerControlView.ai,
      ai: const LocalAiProfileView(seed: 42),
    ),
  ],
  fogEnabled: false,
);

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = key == MapAssetPaths.starter.scenarioDocument
        ? _localAiScenario(await File(key).readAsString())
        : await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

List<int> _localAiScenario(String source) {
  final document = jsonDecode(source) as Map<String, Object?>;
  final initialUnits = document['initialUnits'] as List<Object?>;
  document['initialUnits'] = [
    ...initialUnits,
    const {
      'id': 'ai-commander',
      'ownerPlayerId': 'player-2',
      'kind': 'commander',
      'name': 'AI Commander',
      'col': 6,
      'row': 3,
    },
  ];
  return utf8.encode(jsonEncode(document));
}
