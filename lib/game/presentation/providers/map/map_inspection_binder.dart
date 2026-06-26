import 'dart:ui';

import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/presentation/formatters/map_objective_progress_for_tile.dart';
import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/map/map_inspection_provider.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class MapInspectionBinder {
  const MapInspectionBinder({required this.ref, required this.session});

  final WidgetRef ref;
  final GameSession session;

  void inspectTile(TileData tileData, Offset? anchor) {
    ref
        .read(mapInspectionControllerProvider.notifier)
        .inspectTile(
          tileData,
          anchor: anchor,
          objectiveProgress: _objectiveProgressFor(tileData),
        );
  }

  void previewTile(TileData tileData, Offset? anchor) {
    ref
        .read(mapInspectionControllerProvider.notifier)
        .previewTile(
          tileData,
          anchor: anchor,
          objectiveProgress: _objectiveProgressFor(tileData),
        );
  }

  MapObjectiveProgress? _objectiveProgressFor(TileData tileData) {
    return mapObjectiveProgressForTile(
      mapData: session.mapData,
      tileData: tileData,
      gameState: ref.read(gameStateProvider(session.saveId)).value,
    );
  }
}
