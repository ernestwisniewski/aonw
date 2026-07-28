import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'preserves legacy roster report output when canonical roster is completed',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'aonw-save-ai-benchmark-report.',
      );
      addTearDown(() => directory.delete(recursive: true));
      final snapshot = SaveSnapshot(save: _sparseRosterSave());
      final saveFile = File('${directory.path}/snapshot.json');
      final jsonFile = File('${directory.path}/report.json');
      final markdownFile = File('${directory.path}/report.md');
      await saveFile.writeAsString(
        jsonEncode({'state': SaveSnapshotCodec.toJson(snapshot)}),
      );

      final result = await Process.run('dart', [
        'run',
        'tool/run_save_ai_benchmark.dart',
        '--save',
        saveFile.path,
        '--map',
        File('assets/maps/verdantia/map.json').absolute.path,
        '--strategy',
        'random',
        '--json-out',
        jsonFile.path,
        '--markdown-out',
        markdownFile.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final report =
          jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;
      final runtime = report['runtime'] as Map<String, dynamic>;
      final counts = report['counts'] as Map<String, dynamic>;

      expect(snapshot.domain.participants, hasLength(3));
      expect(counts['players'], 2);
      expect(runtime['localSinglePlayer'], isTrue);
      expect(
        await markdownFile.readAsString(),
        contains('local AI yes, local single-player yes'),
      );
    },
  );
}

GameSave _sparseRosterSave() {
  return GameSave(
    id: 'sparse_roster',
    name: 'Sparse roster benchmark fixture',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {
      'human': PlayerTurnState.active,
      'ai': PlayerTurnState.active,
      'legacy_missing': PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 7, 29),
    camera: CameraState.zero,
    players: const [
      Player(id: 'human', name: 'Human', colorValue: 0xFF2563EB),
      Player(
        id: 'ai',
        name: 'AI',
        colorValue: 0xFFDC2626,
        kind: PlayerKind.ai,
        ai: AiPlayer(strategyId: AiStrategyId.random, seed: 1),
      ),
    ],
    gameMode: GameMode.multiplayer,
  );
}
