import 'dart:io';

import 'package:aonw/map/persistence/map_loader.dart';
import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bundled map AI flow', () {
    for (final mapName in ['verdantia', 'myranth', 'terenos']) {
      test(
        '$mapName opens without rejected commands or stalled founding',
        () async {
          final mapData = await _loadBundledMap(mapName);
          final playerCount =
              MapPlayerCapacityRules.singlePlayerPlayersForMapData(mapData);
          final players = _players(playerCount);
          final result = EconomySimulation.run(
            config: EconomySimulationConfig(
              turns: 12,
              player: players.first,
              opponents: players.skip(1).toList(growable: false),
              mapData: mapData,
              mctsConfig: _flowSmokeMctsConfig,
            ),
          );

          expect(
            result.rejectedCommands,
            isEmpty,
            reason: result.rejectedCommandRecords
                .map(_rejectedSummary)
                .join('\n'),
          );
          for (final player in players) {
            final rows = result.rowsByPlayerId[player.id]!;
            expect(
              rows.any((row) => row.cityCount > 0),
              isTrue,
              reason: '${player.id} should found a city on $mapName',
            );
            expect(
              rows.last.cityCount,
              greaterThanOrEqualTo(1),
              reason: '${player.id} should still have a city on $mapName',
            );
            expect(
              rows.last.militaryCount,
              greaterThanOrEqualTo(1),
              reason: '${player.id} should retain a defense on $mapName',
            );
            expect(rows.last.netGoldPerTurn, greaterThanOrEqualTo(-2));
          }
        },
      );
    }
  });
}

Future<MapData> _loadBundledMap(String mapName) async {
  final file = File('assets/maps/$mapName/map.json');
  return MapLoader.fromJson(await file.readAsString());
}

List<Player> _players(int count) {
  return [
    for (var index = 0; index < count; index++)
      Player(
        id: 'player_${index + 1}',
        name: 'AI ${index + 1}',
        colorValue: Player.palette[index % Player.palette.length],
        country: PlayerCountry.values[index % PlayerCountry.values.length],
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.mcts,
          difficulty: AiDifficulty.normal,
          seed: 1000 + index,
        ),
      ),
  ];
}

const _flowSmokeMctsConfig = MctsConfig(
  iterationBudget: 12,
  minIterations: 12,
  maxPlanningDepth: 3,
  candidateLimit: 6,
);

String _rejectedSummary(EconomySimulationRejectedCommand record) {
  final command = record.command;
  final commandText = switch (command) {
    MoveUnitCommand(:final unitId, :final targetCol, :final targetRow) =>
      'move $unitId -> $targetCol,$targetRow',
    final other => other.runtimeType.toString(),
  };
  return 'turn=${record.turn} player=${record.playerId} '
      'reason=${record.reason} $commandText';
}
