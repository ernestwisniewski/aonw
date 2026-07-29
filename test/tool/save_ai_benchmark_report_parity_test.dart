import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves sparse roster and map reference benchmark output', () async {
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
    expect(counts['mapTiles'], greaterThan(0));
    expect((report['save'] as Map<String, dynamic>)['mapName'], 'verdantia');
    expect(runtime['localSinglePlayer'], isTrue);
    expect(
      await markdownFile.readAsString(),
      contains('local AI yes, local single-player yes'),
    );
  });

  test(
    'treats an intended attack on an AI city as an active hostile threat',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'aonw-save-ai-benchmark-threat.',
      );
      addTearDown(() => directory.delete(recursive: true));
      final snapshot = _pendingCityAttackSnapshot();
      final saveFile = File('${directory.path}/snapshot.json');
      final jsonFile = File('${directory.path}/report.json');
      await saveFile.writeAsString(
        jsonEncode({'state': SaveSnapshotCodec.toJson(snapshot)}),
      );

      final result = await Process.run('dart', [
        'run',
        'tool/run_save_ai_benchmark.dart',
        '--save',
        saveFile.path,
        '--strategy',
        'random',
        '--json-out',
        jsonFile.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final report =
          jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;
      final player =
          (report['players'] as List<dynamic>).single as Map<String, dynamic>;
      final strategy = player['strategy'] as Map<String, dynamic>;
      final targetability = strategy['targetability'] as List<dynamic>;
      final human = targetability.cast<Map<String, dynamic>>().singleWhere(
        (target) => target['playerId'] == 'human_attacker',
      );

      expect(human['isHostile'], isTrue);
      expect(
        (strategy['assignments'] as Map<String, dynamic>)['defenses'],
        greaterThan(0),
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

SaveSnapshot _pendingCityAttackSnapshot() {
  const humanId = 'human_attacker';
  const aiId = 'ai_defender';
  return SaveSnapshot(
    save: GameSave(
      id: 'pending_city_attack',
      name: 'Pending city attack benchmark fixture',
      mapName: 'verdantia',
      mapSource: MapSource.asset,
      turn: 20,
      playerStates: const {
        humanId: PlayerTurnState.active,
        aiId: PlayerTurnState.active,
      },
      savedAt: DateTime.utc(2026, 7, 29),
      camera: CameraState.zero,
      players: const [
        Player(id: humanId, name: 'Human', colorValue: 0xFF2563EB),
        Player(
          id: aiId,
          name: 'AI',
          colorValue: 0xFFDC2626,
          kind: PlayerKind.ai,
          ai: AiPlayer(strategyId: AiStrategyId.random, seed: 1),
        ),
      ],
      gameMode: GameMode.multiplayer,
    ),
    units: [
      GameUnit(
        id: 'human_attacker_unit',
        ownerPlayerId: humanId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 1,
        row: 0,
      ),
      GameUnit(
        id: 'ai_defender_unit',
        ownerPlayerId: aiId,
        type: GameUnitType.warrior,
        name: 'Warrior',
        col: 0,
        row: 1,
      ),
    ],
    cities: const [
      GameCity(
        id: 'ai_city',
        ownerPlayerId: aiId,
        name: 'AI City',
        center: CityHex(col: 1, row: 1),
      ),
    ],
    runtimeState: const GameRuntimeState(
      intendedAttacks: [
        IntendedAttack(
          attackerUnitId: 'human_attacker_unit',
          defenderCol: 1,
          defenderRow: 1,
          declaredAtTick: 20,
          declaringPlayerId: humanId,
        ),
      ],
    ),
  );
}
