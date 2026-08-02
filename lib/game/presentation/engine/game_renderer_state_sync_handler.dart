import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/game_hover_intent_resolver.dart';
import 'package:aonw/game/presentation/engine/game_render_view_model.dart';
import 'package:aonw/game/presentation/engine/game_renderer.dart'
    show WorkerActionPaletteOptionsBuilder;
import 'package:aonw/game/presentation/engine/game_renderer_layer_synchronizer.dart';
import 'package:aonw/game/presentation/engine/game_scene_builder.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/hover_intent_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/marker_density_policy.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

typedef RendererSyncCallback = void Function({bool suppressCameraFocus});

/// Owns renderer state, view settings, presentation caches, and layer sync.
final class GameRendererStateSyncHandler {
  GameRendererStateSyncHandler({
    required String loadingPlayerId,
    required MapViewMode initialViewMode,
    required HexDisplaySettings initialDisplaySettings,
    required bool initialReduceMotion,
    required WorkerActionPaletteOptionsBuilder? workerOptionsBuilder,
    required this.mapData,
    required this.layerSynchronizer,
    required this.sceneBuilder,
    required this.viewModelNotifier,
    required this.isReady,
    required this.isDisposed,
    required this.isDragging,
    required this.hasMultipleViewportPointers,
    required this.inspectionActive,
    required this.hoverIntentMarkerLayer,
    required this.tileDataAtWidgetPosition,
  }) : _viewMode = initialViewMode,
       _displaySettings = initialDisplaySettings,
       _reduceMotion = initialReduceMotion,
       _workerOptionsBuilder = workerOptionsBuilder,
       _state = GameClientState(activePlayerId: loadingPlayerId);

  final WorldMap mapData;
  final GameRendererLayerSynchronizer layerSynchronizer;
  final GameSceneBuilder sceneBuilder;
  final ValueNotifier<RenderState> viewModelNotifier;
  final bool Function() isReady;
  final bool Function() isDisposed;
  final bool Function() isDragging;
  final bool Function() hasMultipleViewportPointers;
  final bool Function() inspectionActive;
  final HoverIntentMarkerLayer Function() hoverIntentMarkerLayer;
  final WorldTile? Function(Vector2 position) tileDataAtWidgetPosition;

  GameClientState _state;
  MapViewMode _viewMode;
  HexDisplaySettings _displaySettings;
  bool _reduceMotion;
  WorkerActionPaletteOptionsBuilder? _workerOptionsBuilder;
  int? _currentTurn;
  Vector2? lastHoverWidgetPosition;
  ({int col, int row, bool forceInspect})? lastSyncedHoverHex;
  GameHoverIntentResolver? _cachedHoverIntentResolver;
  GameClientState? _cachedHoverIntentResolverState;
  bool? _cachedHoverIntentResolverReduceMotion;

  GameClientState get state => _state;
  int? get currentTurn => _currentTurn;
  MapViewMode get viewMode => _viewMode;
  HexDisplaySettings get displaySettings => _displaySettings;
  bool get reduceMotion => _reduceMotion;
  set viewMode(MapViewMode value) {
    if (_viewMode == value) return;
    _viewMode = value;
    applyViewMode();
  }

  set workerOptionsBuilder(WorkerActionPaletteOptionsBuilder? value) {
    if (_workerOptionsBuilder == value) return;
    _workerOptionsBuilder = value;
    if (isReady()) syncAfterAction();
  }

  set displaySettings(HexDisplaySettings value) {
    if (_displaySettings == value) return;
    _displaySettings = value;
    if (isReady()) {
      sceneBuilder.grid.displaySettings = value;
      syncGridSelection();
    }
  }

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    syncReduceMotion();
  }

  void applyState(
    GameClientState state, {
    required bool suppressCameraFocus,
    int? currentTurn,
  }) {
    if (isDisposed()) return;
    if (currentTurn != null) _currentTurn = currentTurn;
    _state = state;
    if (isReady()) {
      syncAfterAction(suppressCameraFocus: suppressCameraFocus);
    } else {
      publishViewModelFromState();
    }
  }

  void syncGridSelection() {
    if (!isReady() || isDisposed()) return;
    final selection = viewModelNotifier.value.selection;
    final tile = selection?.tile;
    if (selection?.type == GameSelectionType.tile && tile != null) {
      sceneBuilder.grid.selectTile(tile.col, tile.row);
    } else {
      sceneBuilder.grid.clearSelection();
    }
  }

  void syncAfterAction({bool suppressCameraFocus = false}) {
    layerSynchronizer.syncAfterAction(suppressCameraFocus: suppressCameraFocus);
  }

  void syncHoverIntentAfterStateChange() {
    if (_hoverIntentResolver().isStale(
      hoverIntentMarkerLayer().activeKind,
      longPressInspectActive: inspectionActive(),
    )) {
      clearHoverIntent();
      return;
    }
    lastSyncedHoverHex = null;
    refreshHoverIntent();
  }

  List<ActionPaletteOption> workerActionPaletteOptions() {
    final builder = _workerOptionsBuilder;
    if (builder == null) return const [];
    final pending = _state.pendingAction;
    if (pending is! PendingWorkerActionSelection) return const [];
    final worker = _state.unitById(pending.unitId);
    if (worker == null || worker.type != GameUnitType.worker) return const [];
    return builder(
      state: _state,
      worker: worker,
      pendingAction: pending,
      mapData: mapData,
    );
  }

  MarkerDensity get currentMarkerDensity =>
      layerSynchronizer.currentMarkerDensity;

  void publishZoom() => layerSynchronizer.publishZoom();

  void syncMarkerDensityForZoom({bool force = false}) =>
      layerSynchronizer.syncMarkerDensityForZoom(force: force);

  void syncReduceMotion() {
    layerSynchronizer.syncReduceMotion();
    if (isReady()) {
      lastSyncedHoverHex = null;
      refreshHoverIntent();
    }
  }

  void syncHoverIntentAtWidgetPosition(
    Vector2 widgetPosition, {
    bool forceInspect = false,
  }) {
    if (!isReady() || isDragging() || hasMultipleViewportPointers()) {
      clearHoverIntent();
      return;
    }
    final tileData = tileDataAtWidgetPosition(widgetPosition);
    if (tileData == null) {
      clearHoverIntent();
      return;
    }
    lastHoverWidgetPosition = widgetPosition.clone();
    syncHoverIntentForTile(
      tileData,
      forceInspect: forceInspect || inspectionActive(),
    );
  }

  void syncHoverIntentForTile(WorldTile tileData, {bool forceInspect = false}) {
    if (!isReady()) return;
    final cacheKey = (
      col: tileData.col,
      row: tileData.row,
      forceInspect: forceInspect,
    );
    if (lastSyncedHoverHex == cacheKey) return;
    lastSyncedHoverHex = cacheKey;
    final intent = _hoverIntentResolver().resolve(
      tileData,
      forceInspect: forceInspect,
    );
    hoverIntentMarkerLayer().sync(parent: sceneBuilder.grid, intent: intent);
  }

  void refreshHoverIntent() {
    final hoverPosition = lastHoverWidgetPosition;
    if (hoverPosition == null) return;
    syncHoverIntentAtWidgetPosition(
      hoverPosition,
      forceInspect: inspectionActive(),
    );
  }

  void clearHoverIntent() {
    lastHoverWidgetPosition = null;
    lastSyncedHoverHex = null;
    hoverIntentMarkerLayer().clear();
  }

  GameHoverIntentResolver _hoverIntentResolver() {
    final cached = _cachedHoverIntentResolver;
    if (cached != null &&
        identical(_cachedHoverIntentResolverState, _state) &&
        _cachedHoverIntentResolverReduceMotion == _reduceMotion) {
      return cached;
    }
    final resolver = GameHoverIntentResolver(
      state: _state,
      mapView: mapData,
      reduceMotion: _reduceMotion,
      colorForPlayer: colorForPlayer,
    );
    _cachedHoverIntentResolver = resolver;
    _cachedHoverIntentResolverState = _state;
    _cachedHoverIntentResolverReduceMotion = _reduceMotion;
    return resolver;
  }

  void publishViewModelFromState() {
    if (isDisposed()) return;
    final viewModel = RenderState.fromState(_state);
    if (viewModelNotifier.value == viewModel) return;
    viewModelNotifier.value = viewModel;
  }

  int colorForPlayer(String playerId) {
    return layerSynchronizer.colorForPlayer(playerId);
  }

  void applyViewMode() {
    if (!isReady() || isDisposed()) return;
    sceneBuilder.setViewMode(_viewMode);
    syncAfterAction();
  }
}
