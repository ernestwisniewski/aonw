import 'package:aonw/editor/engine/editor_grid.dart';
import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/rendering/hex_world.dart';
import 'package:aonw/map/rendering/map_image_layer.dart';
import 'package:aonw/map/rendering/map_objective_marker_layer.dart';
import 'package:aonw/shared/input/hex_input_behavior.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class EditorWorld extends HexWorld with KeyboardEvents, HexInputBehavior {
  final MapData mapData;
  final String? imagePath;
  EditorState _editorState;
  MapViewMode _viewMode;
  HexDisplaySettings _displaySettings;

  /// Called when the user taps a tile so the screen can sync the toolbar.
  final void Function(int col, int row)? onTileSelected;

  /// Called when the default zoom changes so the screen can persist it.
  final void Function(double zoom)? onDefaultZoomChanged;

  EditorWorld({
    required this.mapData,
    required EditorState editorState,
    this.imagePath,
    this.onTileSelected,
    this.onDefaultZoomChanged,
    MapViewMode initialViewMode = MapViewMode.tile,
    HexDisplaySettings? displaySettings,
  }) : _editorState = editorState,
       _viewMode = initialViewMode,
       _displaySettings = displaySettings ?? const HexDisplaySettings();

  late final EditorGrid _grid;
  late final MapImageLayer _imageLayer;
  late final MapObjectiveMarkerLayer _objectiveMarkerLayer;
  bool _isReady = false;
  bool _hasReferenceImage = false;

  EditorGrid get grid => _grid;
  MapImageLayer get imageLayer => _imageLayer;
  bool get hasReferenceImage => _hasReferenceImage;
  MapViewMode get viewMode => _viewMode;

  double get defaultZoom => mapData.defaultZoom;

  set editorState(EditorState value) {
    _editorState = value;
    if (_isReady) {
      _grid.editorState = value;
    }
  }

  set defaultZoom(double value) {
    mapData.defaultZoom = value;
    onDefaultZoomChanged?.call(value);
  }

  set displaySettings(HexDisplaySettings value) {
    if (_displaySettings == value) return;
    _displaySettings = value;
    if (_isReady) {
      _grid.displaySettings = value;
    }
  }

  set viewMode(MapViewMode value) {
    if (_viewMode == value) return;
    _viewMode = value;
    _applyViewMode();
  }

  @override
  Future<void> buildWorld() async {
    final overlayImagePath = imagePath;
    _hasReferenceImage = overlayImagePath != null;

    _imageLayer = MapImageLayer(
      config: MapConfig.defaultConfig,
      cols: mapData.cols,
      rows: mapData.rows,
    );
    await world.add(_imageLayer);
    if (overlayImagePath != null) {
      await _loadImageIntoLayer(overlayImagePath);
    }

    _grid = EditorGrid(
      mapData: mapData,
      config: MapConfig.defaultConfig,
      editorState: _editorState,
      viewMode: _viewMode,
      onTileSelected: onTileSelected,
      onObjectivesChanged: _syncObjectiveMarkers,
      displaySettings: _displaySettings,
    );
    await world.add(_grid);

    _objectiveMarkerLayer = MapObjectiveMarkerLayer(colorForPlayer: (_) => 0);
    _syncObjectiveMarkers();

    _isReady = true;
    _applyViewMode();
  }

  void _applyViewMode() {
    if (!_isReady) return;
    _imageLayer.showImage = _hasReferenceImage && _viewMode.showsImage;
    _grid.viewMode = _viewMode;
  }

  void _syncObjectiveMarkers() {
    _objectiveMarkerLayer.sync(
      parent: world,
      objectives: [
        for (final objective in mapData.objectives)
          MapObjectiveProgress(
            definition: objective,
            controllingPlayerId: null,
            holdTurns: 0,
          ),
      ],
    );
  }

  /// Call after +C/-C/+R/-R to keep the image layer in sync with the grid.
  void resizeImageLayer(int cols, int rows) {
    if (!_isReady) return;
    _imageLayer.resize(cols, rows);
  }

  Future<void> loadImageOverlay(String imagePath) async {
    if (!_isReady) return;
    await _loadImageIntoLayer(imagePath);
    _hasReferenceImage = _imageLayer.hasImage;
    _applyViewMode();
  }

  Future<void> _loadImageIntoLayer(String imagePath) =>
      _imageLayer.loadAuto(imagePath);

  /// Re-paints the selected tile with the current editorState.
  void repaintSelected() {
    if (!_isReady) return;
    _grid.editorState = _editorState;
    _grid.repaintSelected();
  }

  void clearSelectedTerrains() {
    if (!_isReady) return;
    if (!_grid.clearSelectedTerrains()) return;
    final coords = _grid.selectedTileCoords;
    if (coords == null) return;
    onTileSelected?.call(coords.col, coords.row);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyT) {
      clearSelectedTerrains();
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  void addColumn() {
    if (!_isReady) return;
    _grid.editorState = _editorState;
    _grid.addColumn();
  }

  void removeColumn() {
    if (!_isReady) return;
    _grid.editorState = _editorState;
    _grid.removeColumn();
  }

  void addRow() {
    if (!_isReady) return;
    _grid.editorState = _editorState;
    _grid.addRow();
  }

  void removeRow() {
    if (!_isReady) return;
    _grid.editorState = _editorState;
    _grid.removeRow();
  }
}
