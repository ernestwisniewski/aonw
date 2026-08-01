import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/fog/fog_reveal_calculator.dart';
import 'package:aonw_core/game/domain/fog/fog_reveal_source.dart';
import 'package:aonw_core/game/domain/hex/hex_coordinate.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_phase.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/movement/scout_auto_explore_planner.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

import 'measurement.dart';

part 'auto_explore_workload.dart';
part 'fog_reveal_workload.dart';
part 'movement_path_workload.dart';
part 'world_map_workload.dart';

const mapLookupScales = [100, 1000, 10000];

void _validateTimingSamples(int timingSamples) {
  if (timingSamples <= 0) {
    throw ArgumentError.value(
      timingSamples,
      'timingSamples',
      'Must be positive.',
    );
  }
}

bool _mapsEqual(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}

({int cols, int rows}) _dimensionsFor(int scale) => switch (scale) {
  100 => (cols: 10, rows: 10),
  1000 => (cols: 25, rows: 40),
  10000 => (cols: 100, rows: 100),
  _ => throw ArgumentError.value(
    scale,
    'scale',
    'Supported scales are 100, 1000, and 10000.',
  ),
};

final class _Probe {
  const _Probe(this.name, this.col, this.row);

  final String name;
  final int col;
  final int row;
}

final class _ScaleResult {
  const _ScaleResult({required this.stable, required this.observations});

  final Map<String, Object?> stable;
  final Map<String, Object?> observations;
}
