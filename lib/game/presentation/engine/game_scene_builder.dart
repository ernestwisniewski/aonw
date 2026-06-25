import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/map_image_layer.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

typedef GameTileTapCallback = void Function(TileData tileData);

class GameSceneBuilder {
  HexGrid? _grid;
  MapImageLayer? _imageLayer;
  bool _hasReferenceImage = false;

  HexGrid get grid {
    assert(_grid != null, 'Call build() before accessing grid');
    return _grid!;
  }

  MapImageLayer get imageLayer {
    assert(_imageLayer != null, 'Call build() before accessing imageLayer');
    return _imageLayer!;
  }

  bool get hasReferenceImage => _hasReferenceImage;

  Future<void> build({
    required Component parent,
    required MapData mapData,
    String? imagePath,
    required MapViewMode viewMode,
    required HexDisplaySettings displaySettings,
    required GameTileTapCallback onTileTapped,
    ValueChanged<double>? onReferenceImageProgress,
  }) async {
    _imageLayer = MapImageLayer(
      config: MapConfig.defaultConfig,
      cols: mapData.cols,
      rows: mapData.rows,
    );
    await parent.add(_imageLayer!);

    if (imagePath != null) {
      await _imageLayer!.loadAuto(
        imagePath,
        onProgress: onReferenceImageProgress,
      );
      _hasReferenceImage = _imageLayer!.hasImage;
    } else {
      onReferenceImageProgress?.call(1);
    }

    _grid = HexGrid(
      mapData: mapData,
      config: MapConfig.defaultConfig,
      viewMode: viewMode,
      displaySettings: displaySettings,
      onTileTapped: onTileTapped,
      autoSelectOnTap: false,
    );
    await parent.add(_grid!);
  }

  void setViewMode(MapViewMode mode) {
    _imageLayer?.showImage = _hasReferenceImage && mode.showsImage;
    _grid?.viewMode = mode;
  }

  void rebuild() {
    _grid?.rebuild();
  }
}
