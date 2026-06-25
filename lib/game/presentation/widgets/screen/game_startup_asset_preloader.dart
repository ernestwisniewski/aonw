import 'dart:async';

import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/fog_of_war_overlay.dart';
import 'package:aonw/map/rendering/terrain_theme.dart';
import 'package:aonw/map/rendering/tile/hex_icon_cache.dart';
import 'package:flutter/foundation.dart';

abstract final class GameStartupAssetPreloader {
  static Future<void> preload(
    GameSession session, {
    ValueChanged<double>? onProgress,
  }) async {
    onProgress?.call(0);
    final iconPaths = _mapIconPaths(session).toList(growable: false);
    final totalTasks = iconPaths.length + 2;
    var completedTasks = 0;
    void taskDone() {
      completedTasks++;
      onProgress?.call(completedTasks / totalTasks);
    }

    await Future.wait([
      Future.wait(
        iconPaths.map((path) async {
          try {
            await HexIconCache.load(path);
          } finally {
            taskDone();
          }
        }),
      ),
      AnimationFrameAdjustmentCatalogCache.load().whenComplete(taskDone),
      FogOfWarOverlay.preloadShaderProgram().whenComplete(taskDone),
    ]);
    onProgress?.call(1);
  }

  static Iterable<String> _mapIconPaths(GameSession session) sync* {
    final seen = <String>{};
    for (final tile in session.mapData.tiles) {
      for (final terrain in tile.terrains) {
        final path = TerrainTheme.icon(terrain);
        if (seen.add(path)) yield path;
      }
      for (final resource in tile.resources) {
        final path = TerrainTheme.resourceIcon(resource);
        if (path != null && seen.add(path)) yield path;
      }
    }
  }
}
