library;

import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/current_content_legacy_fixture.dart';

part 'save_ai_benchmark_report_parity_goldens.dart';

const _replayEventsWithoutFinalization = <String, int>{
  'total': 0,
  'commandRejected': 0,
  'unitAttacks': 0,
  'combatResolved': 0,
  'unitKills': 0,
  'cityCaptures': 0,
  'cityDestroyed': 0,
  'allPlayersSubmitted': 0,
};

const _replayEventsAfterFinalization = <String, int>{
  'total': 4,
  'commandRejected': 0,
  'unitAttacks': 0,
  'combatResolved': 0,
  'unitKills': 0,
  'cityCaptures': 0,
  'cityDestroyed': 0,
  'allPlayersSubmitted': 1,
};

const _sparseReplayEventsAfterFinalization = <String, int>{
  'total': 3,
  'commandRejected': 0,
  'unitAttacks': 0,
  'combatResolved': 0,
  'unitKills': 0,
  'cityCaptures': 0,
  'cityDestroyed': 0,
  'allPlayersSubmitted': 1,
};

typedef _ReplayFixture = ({
  String name,
  GameSave save,
  int startTurn,
  List<List<String>> playerOrder,
  List<List<Map<String, int>>> eventCounts,
});

void main() {
  test(
    'preserves canonical roster and map reference benchmark output',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'aonw-save-ai-benchmark-report.',
      );
      addTearDown(() => directory.delete(recursive: true));
      final snapshot = GameSnapshotFactory.create(save: _benchmarkSave());
      final saveFile = File('${directory.path}/snapshot.json');
      final jsonFile = File('${directory.path}/report.json');
      final markdownFile = File('${directory.path}/report.md');
      final mapFile = await _writeLegacyMapFixture(directory, 'verdantia');
      await saveFile.writeAsString(
        jsonEncode({'state': SaveSnapshotCodec.toJson(snapshot)}),
      );

      final result = await Process.run('dart', [
        'run',
        'tool/run_save_ai_benchmark.dart',
        '--save',
        saveFile.path,
        '--map',
        mapFile.path,
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

      expect(snapshot.domain.participants, hasLength(2));
      expect(counts['players'], 2);
      expect(counts['mapTiles'], greaterThan(0));
      expect((report['save'] as Map<String, dynamic>)['mapName'], 'verdantia');
      expect(runtime['localSinglePlayer'], isTrue);
      expect(
        await markdownFile.readAsString(),
        contains('local AI yes, local single-player yes'),
      );
    },
  );

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
      final mapFile = await _writeLegacyMapFixture(directory, 'verdantia');
      await saveFile.writeAsString(
        jsonEncode({'state': SaveSnapshotCodec.toJson(snapshot)}),
      );

      final result = await Process.run('dart', [
        'run',
        'tool/run_save_ai_benchmark.dart',
        '--save',
        saveFile.path,
        '--map',
        mapFile.path,
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

  test(
    'MCTS benchmark carries the engine envelope into unit actions',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'aonw-save-ai-benchmark-mcts-envelope.',
      );
      addTearDown(() => directory.delete(recursive: true));
      final saveFile = File('${directory.path}/snapshot.json');
      final jsonFile = File('${directory.path}/report.json');
      final mapFile = await _writeLegacyMapFixture(directory, 'verdantia');
      await saveFile.writeAsString(
        jsonEncode({
          'state': SaveSnapshotCodec.toJson(_pendingCityAttackSnapshot()),
        }),
      );

      final result = await Process.run('dart', [
        'run',
        'tool/run_save_ai_benchmark.dart',
        '--save',
        saveFile.path,
        '--map',
        mapFile.path,
        '--strategy',
        'mcts',
        '--profiles',
        'batterySaver',
        '--json-out',
        jsonFile.path,
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final report =
          jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;
      expect(report['players'], hasLength(1));
    },
  );

  test(
    'replays canonical rosters against pinned report goldens',
    _verifyReplayParity,
  );
}

Future<void> _verifyReplayParity() async {
  for (final fixture in _replayFixtures()) {
    await _verifyReplayFixture(fixture);
  }
}

List<_ReplayFixture> _replayFixtures() => [
  (
    name: 'normal',
    save: _benchmarkSave().copyWith(
      id: 'normal_roster',
      turn: 7,
      playerStates: const {
        'human': PlayerTurnState.active,
        'ai': PlayerTurnState.active,
        'ai_beta': PlayerTurnState.active,
      },
      players: const [
        Player(id: 'human', name: 'Human', colorValue: 0xFF2563EB),
        Player(
          id: 'ai',
          name: 'AI',
          colorValue: 0xFFDC2626,
          kind: PlayerKind.ai,
          ai: AiPlayer(strategyId: AiStrategyId.random, seed: 1),
        ),
        Player(
          id: 'ai_beta',
          name: 'AI Beta',
          colorValue: 0xFF7C3AED,
          kind: PlayerKind.ai,
          ai: AiPlayer(strategyId: AiStrategyId.random, seed: 2),
        ),
      ],
    ),
    startTurn: 7,
    playerOrder: const [
      ['ai', 'ai_beta'],
      ['ai', 'ai_beta'],
    ],
    eventCounts: const [
      [_replayEventsWithoutFinalization, _replayEventsAfterFinalization],
      [_replayEventsWithoutFinalization, _replayEventsAfterFinalization],
    ],
  ),
  (
    name: 'single_ai',
    save: _benchmarkSave(),
    startTurn: 1,
    playerOrder: const [
      ['ai'],
      ['ai'],
    ],
    eventCounts: const [
      [_sparseReplayEventsAfterFinalization],
      [_sparseReplayEventsAfterFinalization],
    ],
  ),
];

Future<void> _verifyReplayFixture(_ReplayFixture fixture) async {
  final directory = await Directory.systemTemp.createTemp(
    'aonw-save-ai-benchmark-${fixture.name}-replay.',
  );
  addTearDown(() => directory.delete(recursive: true));
  final saveFile = File('${directory.path}/snapshot.json');
  final jsonFile = File('${directory.path}/report.json');
  final markdownFile = File('${directory.path}/report.md');
  final mapFile = await _writeLegacyMapFixture(directory, 'verdantia');
  await saveFile.writeAsString(
    jsonEncode({
      'state': SaveSnapshotCodec.toJson(
        GameSnapshotFactory.create(save: fixture.save),
      ),
    }),
  );

  final result = await _runReplayReport(
    saveFile: saveFile,
    mapFile: mapFile,
    jsonFile: jsonFile,
    markdownFile: markdownFile,
  );

  expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  final report =
      jsonDecode(await jsonFile.readAsString()) as Map<String, dynamic>;
  final replay = report['multiTurnReplay'] as Map<String, dynamic>;
  expect(
    _normalizedReplayJson(replay),
    _replayJsonGolden(fixture: fixture, savePath: saveFile.path),
  );
  expect(
    _normalizedReplayMarkdown(
      _multiTurnMarkdown(await markdownFile.readAsString()),
    ),
    _replayMarkdownGolden(fixture),
  );
  _expectReplayCycles(report, fixture);
}

void _expectReplayCycles(Map<String, dynamic> report, _ReplayFixture fixture) {
  final replay = report['multiTurnReplay'] as Map<String, dynamic>;
  final cycles = replay['cycles'] as List<dynamic>;

  expect(replay['startTurn'], fixture.startTurn);
  expect(replay['endTurn'], fixture.startTurn + 2);
  expect(cycles, hasLength(2));
  for (var index = 0; index < cycles.length; index++) {
    final cycle = cycles[index] as Map<String, dynamic>;
    expect(cycle['startTurn'], fixture.startTurn + index);
    expect(cycle['endTurn'], fixture.startTurn + index + 1);
    final turns = (cycle['playerTurns'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(
      turns.map((turn) => turn['playerId']).toList(),
      fixture.playerOrder[index],
    );
    expect(
      turns
          .map(
            (turn) =>
                Map<String, int>.from(turn['events'] as Map<String, dynamic>),
          )
          .toList(),
      fixture.eventCounts[index],
    );
    expect(
      turns.map((turn) => turn['terminalChangedState']).toList(),
      everyElement(isTrue),
    );
  }
}

Future<ProcessResult> _runReplayReport({
  required File saveFile,
  required File mapFile,
  required File jsonFile,
  required File markdownFile,
}) {
  return Process.run('dart', [
    'run',
    'tool/run_save_ai_benchmark.dart',
    '--save',
    saveFile.path,
    '--map',
    mapFile.path,
    '--strategy',
    'random',
    '--multi-turns',
    '2',
    '--json-out',
    jsonFile.path,
    '--markdown-out',
    markdownFile.path,
  ]);
}

Future<File> _writeLegacyMapFixture(Directory directory, String mapName) async {
  final file = File('${directory.path}/$mapName-map.json');
  await file.writeAsString(await loadCurrentMapAsLegacyFixture(mapName));
  return file;
}

GameSave _benchmarkSave() {
  return GameSave(
    id: 'sparse_roster',
    name: 'Benchmark fixture',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {
      'human': PlayerTurnState.active,
      'ai': PlayerTurnState.active,
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

CanonicalGameSnapshot _pendingCityAttackSnapshot() {
  const humanId = 'human_attacker';
  const aiId = 'ai_defender';
  return GameSnapshotFactory.create(
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

    intendedAttacks: [
      const IntendedAttack(
        attackerUnitId: 'human_attacker_unit',
        defenderCol: 1,
        defenderRow: 1,
        declaredAtTick: 20,
        declaringPlayerId: humanId,
      ),
    ],
  );
}
