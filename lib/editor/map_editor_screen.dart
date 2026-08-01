import 'package:aonw/editor/dialogs/editor_dialogs.dart';
import 'package:aonw/editor/domain/map_draft.dart';
import 'package:aonw/editor/engine/editor_state.dart';
import 'package:aonw/editor/engine/editor_world.dart';
import 'package:aonw/editor/providers/editor_providers.dart';
import 'package:aonw/editor/services/map_exporter.dart';
import 'package:aonw/editor/services/map_saver.dart';
import 'package:aonw/editor/widgets/editor_bottom_toolbar.dart';
import 'package:aonw/editor/widgets/editor_options_overlay.dart';
import 'package:aonw/editor/widgets/editor_top_bar.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:aonw/map/widgets/dice_roll_test_overlay.dart';
import 'package:aonw/shared/providers/hex_display_provider.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:aonw/shared/widgets/viewport_gesture_layer.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MapEditorScreen extends ConsumerStatefulWidget {
  final MapSelection? selection;

  const MapEditorScreen({this.selection, super.key});

  @override
  ConsumerState<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends ConsumerState<MapEditorScreen> {
  EditorWorld? _game;
  MapDraft? _activeDraft;
  String? _activeImagePath;
  String? _pendingImageSourcePath;
  bool _pendingImageSliceMode = false;
  MapViewMode _viewMode = MapViewMode.tile;
  bool _hasGraphicMode = false;
  bool _showDiceRollTestOverlay = false;
  bool _isInitializing = true;
  Object? _loadError;
  double _defaultZoom = 1.0;

  /// True while syncing toolbar to a tapped tile — suppresses repaintSelected.
  bool _syncingFromTile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeEditor());
  }

  Future<void> _initializeEditor() async {
    setState(() {
      _isInitializing = true;
      _loadError = null;
    });

    try {
      if (widget.selection case final selection?) {
        final mapRepository = ref.read(mapRepositoryProvider);
        final sourceMap = await mapRepository.loadMap(selection);
        final imagePath = await mapRepository.resolveImagePath(selection);
        if (!mounted) return;

        final draft = MapDraft.fromWorldMap(sourceMap);
        ref.read(editorMapProvider.notifier).load(draft);
        setState(() {
          _activeImagePath = imagePath;
          _pendingImageSourcePath = null;
          _pendingImageSliceMode = false;
          _hasGraphicMode = imagePath != null;
          _viewMode = imagePath != null
              ? MapViewMode.graphic
              : MapViewMode.tile;
          _defaultZoom = draft.defaultZoom;
        });
      } else {
        final created = await _promptForNewMap();
        if (!mounted || !created) return;
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<bool> _promptForNewMap() async {
    final config = await showNewMapDialog(context);
    if (!mounted) return false;
    if (config == null) {
      context.go('/editor');
      return false;
    }

    ref
        .read(editorMapProvider.notifier)
        .create(config.cols, config.rows, config.defaultTerrain);
    setState(() {
      _activeImagePath = null;
      _pendingImageSourcePath = null;
      _pendingImageSliceMode = false;
      _viewMode = MapViewMode.tile;
      _hasGraphicMode = false;
    });
    return true;
  }

  void _ensureGame(
    MapDraft? draft,
    EditorState editorState,
    HexDisplaySettings displaySettings,
  ) {
    if (draft == null) return;
    if (!identical(_activeDraft, draft)) {
      _activeDraft = draft;
      _game = EditorWorld(
        draft: draft,
        editorState: editorState,
        imagePath: _activeImagePath,
        initialViewMode: _viewMode,
        onTileSelected: _onTileSelected,
        onDefaultZoomChanged: (zoom) => setState(() => _defaultZoom = zoom),
        displaySettings: displaySettings,
      );
    }
    _game?.editorState = editorState;
    _game?.viewMode = _viewMode;
    _game?.displaySettings = displaySettings;
  }

  /// Called by EditorGrid when a tile is tapped.
  /// Syncs the toolbar to the tile's current terrain/resource/height.
  void _onTileSelected(int col, int row) {
    final draft = ref.read(editorMapProvider);
    if (draft == null) return;
    final tile = draft.tileAt(col, row);
    final editorState = ref.read(editorStateProvider);
    _syncingFromTile = true;
    ref
        .read(editorStateProvider.notifier)
        .syncToTile(
          terrains: tile?.terrains ?? editorState.selectedTerrains.toList(),
          resources: tile?.resources ?? const [],
          objectiveType: _objectiveTypeAt(draft, col, row),
          height: tile?.height ?? 0,
        );
    _syncingFromTile = false;
    // Do NOT repaint here — tapping only selects, does not modify the tile.
    // repaintSelected() is called only when the user changes the toolbar.
  }

  MapObjectiveType? _objectiveTypeAt(MapDraft draft, int col, int row) {
    for (final objective in draft.objectives) {
      if (objective.hex.col == col && objective.hex.row == row) {
        return objective.type;
      }
    }
    return null;
  }

  void _withGame(void Function(EditorWorld game) action) {
    final game = _game;
    if (game == null) return;
    game.editorState = ref.read(editorStateProvider);
    action(game);
  }

  void _setViewMode(MapViewMode value) {
    if (value == MapViewMode.graphic && !_hasGraphicMode) return;
    setState(() {
      _viewMode = value;
    });
    _game?.viewMode = value;
  }

  void _resizeMap(void Function(EditorWorld game) action) {
    _withGame((game) {
      action(game);
      game.resizeImageLayer(game.draft.cols, game.draft.rows);
    });
    setState(() {});
  }

  Future<void> _handleExport() async {
    final draft = ref.read(editorMapProvider);
    if (draft == null) return;

    final initialFilename = draft.mapName?.isNotEmpty == true
        ? draft.mapName!
        : 'map';
    final result = await showExportMapDialog(
      context,
      initialFilename: initialFilename,
    );
    if (!mounted || result == null) return;

    try {
      switch (result.destination) {
        case ExportMapDestination.share:
          await MapExporter.share(draft, result.filename);
        case ExportMapDestination.saveToDisk:
          final savedPath = await MapExporter.saveToDisk(
            draft,
            result.filename,
          );
          if (!mounted) return;
          if (savedPath != null) {
            _showSnackBar('Saved to $savedPath');
          }
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Export failed: $error');
    }
  }

  Future<void> _handleReplaceImage() async {
    final pickedPath = await MapSaver.pickImage();
    if (!mounted || pickedPath == null) return;
    final shouldSaveAsSlices = _pendingImageSourcePath != null
        ? _pendingImageSliceMode
        : _isSlicedImagePath(_activeImagePath);
    final options = await showMapImageUploadOptionsDialog(
      context,
      imageSourcePath: pickedPath,
      initialSliceImage: shouldSaveAsSlices,
    );
    if (!mounted || options == null) return;
    final draft = ref.read(editorMapProvider);
    final mapName = draft?.mapName;
    var persistedImmediately = false;

    try {
      String imagePath;
      if (draft != null && mapName != null && mapName.trim().isNotEmpty) {
        imagePath = await _saveMapImage(
          sourcePath: pickedPath,
          mapName: mapName,
          draft: draft,
          sliceImage: options.sliceImage,
        );
        persistedImmediately = true;
      } else {
        imagePath = pickedPath;
      }
      await _game?.loadImageOverlay(imagePath);
      if (!mounted) return;
      setState(() {
        _activeImagePath = imagePath;
        _pendingImageSourcePath = persistedImmediately ? null : pickedPath;
        _pendingImageSliceMode = persistedImmediately
            ? false
            : options.sliceImage;
        _hasGraphicMode = true;
        _viewMode = MapViewMode.graphic;
      });
      _game?.viewMode = MapViewMode.graphic;
      _showSnackBar(
        persistedImmediately ? 'Map image saved' : 'Map image replaced',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Image import failed: $error');
      return;
    }
  }

  Future<void> _handleSave() async {
    final draft = ref.read(editorMapProvider);
    if (draft == null) return;

    final saveRequest = await showSaveMapDialog(
      context,
      initialName: draft.mapName ?? 'map',
    );
    if (!mounted || saveRequest == null) return;

    draft.mapName = saveRequest.name; // MapSaver.save() sanitizes internally

    try {
      await MapSaver.save(draft);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Save failed: $error');
      return;
    }

    final safeName = draft.mapName!; // read back sanitized name after save

    String? savedImagePath;
    final saveDialogImageSelected = saveRequest.imageSourcePath != null;
    final imageSourcePath =
        saveRequest.imageSourcePath ?? _pendingImageSourcePath;
    if (imageSourcePath != null) {
      try {
        final sliceImage = saveDialogImageSelected
            ? saveRequest.sliceImage
            : _pendingImageSliceMode;
        savedImagePath = await _saveMapImage(
          sourcePath: imageSourcePath,
          mapName: safeName,
          draft: draft,
          sliceImage: sliceImage,
        );
      } catch (error) {
        if (!mounted) return;
        _showSnackBar('Map "$safeName" saved, but image import failed: $error');
        return;
      }
    }

    if (!mounted) return;
    _showSnackBar('Map "$safeName" saved');

    final resolvedImagePath =
        savedImagePath ?? await MapSaver.resolveImagePath(safeName);
    if (!mounted) return;

    setState(() {
      _activeImagePath = resolvedImagePath;
      _pendingImageSourcePath = null;
      _pendingImageSliceMode = false;
      _hasGraphicMode = resolvedImagePath != null;
    });

    if (resolvedImagePath != null) {
      await _game?.loadImageOverlay(resolvedImagePath);
    }
  }

  Future<String> _saveMapImage({
    required String sourcePath,
    required String mapName,
    required MapDraft draft,
    required bool sliceImage,
  }) {
    if (sliceImage) {
      return MapSaver.saveImageSlices(
        sourcePath: sourcePath,
        mapName: mapName,
        cols: draft.cols,
        rows: draft.rows,
        config: MapConfig.defaultConfig,
      );
    }
    return MapSaver.saveImageCopy(sourcePath: sourcePath, mapName: mapName);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isSlicedImagePath(String? path) {
    if (path == null) return false;
    return RegExp(r'(^|[\\/])1x1\.png$').hasMatch(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = ref.watch(editorMapProvider);
    final editorState = ref.watch(editorStateProvider);
    ref.watch(hexDisplayDefaultsBootstrapProvider);
    final displaySettings = ref.watch(hexDisplayProvider);

    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: GameUiTheme.bg,
        body: Center(
          child: CircularProgressIndicator(color: GameUiTheme.textSecondary),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: GameUiTheme.bg,
        body: GameUiEmptyState(
          icon: Icons.error_outline,
          title: l10n.editorOpenMapErrorTitle,
          message: '$_loadError',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _initializeEditor,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(GameText.actionLabel(l10n.retryAction)),
                style: GameUiTheme.outlinedButtonStyle(
                  foreground: GameUiTheme.goldLight,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/editor'),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(GameText.actionLabel(l10n.backAction)),
                style: GameUiTheme.textButtonStyle(
                  foreground: GameUiTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // When the user changes the toolbar, repaint the selected tile.
    // Suppressed when syncing from tile tap to avoid overwriting with stale state.
    ref.listen(editorStateProvider, (prev, next) {
      if (prev != next && !_syncingFromTile) {
        _game?.editorState = next;
        _game?.repaintSelected();
      }
    });

    _ensureGame(draft, editorState, displaySettings);
    final game = _game;

    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: Stack(
        children: [
          if (game != null)
            Positioned.fill(
              child: ViewportGestureLayer(
                game: game,
                child: GameWidget(game: game),
              ),
            ),
          if (_showDiceRollTestOverlay)
            const Positioned.fill(child: DiceRollTestOverlay()),
          Column(
            children: [
              EditorTopBar(
                draft: draft,
                onAddColumn: () => _resizeMap((game) => game.addColumn()),
                onRemoveColumn: () => _resizeMap((game) => game.removeColumn()),
                onAddRow: () => _resizeMap((game) => game.addRow()),
                onRemoveRow: () => _resizeMap((game) => game.removeRow()),
                onReplaceImage: _handleReplaceImage,
                onSave: _handleSave,
                onExport: _handleExport,
                onClose: () => context.go('/editor'),
              ),
              const Spacer(),
              if (draft != null)
                EditorBottomToolbar(
                  editorState: editorState,
                  displaySettings: displaySettings,
                  defaultZoom: _defaultZoom,
                  onDefaultZoomChanged: (zoom) {
                    _game?.defaultZoom = zoom;
                  },
                ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: EditorOptionsOverlay(
                  viewMode: _viewMode,
                  allowGraphicMode: _hasGraphicMode,
                  onViewModeChanged: _setViewMode,
                  onSave: _handleSave,
                  showTerrain: displaySettings.showTerrain,
                  showResources: displaySettings.showResources,
                  showHeightBadge: displaySettings.showHeightBadge,
                  showCitySites: displaySettings.showCitySites,
                  showCityGrowth: displaySettings.showCityGrowth,
                  showDiceRollTest: _showDiceRollTestOverlay,
                  onToggleTerrain: () =>
                      ref.read(hexDisplayProvider.notifier).toggleTerrain(),
                  onToggleResources: () =>
                      ref.read(hexDisplayProvider.notifier).toggleResources(),
                  onToggleHeightBadge: () =>
                      ref.read(hexDisplayProvider.notifier).toggleHeightBadge(),
                  onToggleCitySites: () =>
                      ref.read(hexDisplayProvider.notifier).toggleCitySites(),
                  onToggleCityGrowth: () =>
                      ref.read(hexDisplayProvider.notifier).toggleCityGrowth(),
                  onToggleDiceRollTest: () {
                    setState(() {
                      _showDiceRollTestOverlay = !_showDiceRollTestOverlay;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
